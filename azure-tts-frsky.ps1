#### Welcome Message ####
Write-Host "Azure TTS Script for FrSky Ethos RC Transmitters"
Start-Sleep -Seconds 1.0

Write-Host "`nChecking for Azure key and region files..."
Start-Sleep -Seconds 0.5
$keyFilePath = Join-Path $PSScriptRoot "key"
$regionFilePath = Join-Path $PSScriptRoot "region"
if (!(Test-Path $keyFilePath) -or !(Test-Path $regionFilePath)) {
    Write-Host "Key and region files not found. Sending spx config commands..."
    Write-Host "`n"
    # Write spx config commands
    spx --% config @key --set 0fe34f42542146f9b3612c1512d0941c
    spx --% config @region --set eastus
}
else {
    Write-Host "Key and region files found. Continuing..."
    Start-Sleep -Seconds 1.0
}

#### Initial read of .json and .csv files to retrieve region and shortnames ####

# Read the contents of "voices.json"
Write-Host "`nReading voices.json to determine available voices..."
$voicesJsonPath = Join-Path $PSScriptRoot "voices.json"
$voicesJson = Get-Content -Raw -Path $voicesJsonPath | ConvertFrom-Json
Start-Sleep -Seconds 1

# Get the list of available ShortNames
$shortNames = $voicesJson | Select-Object -ExpandProperty ShortName

Write-Host "Reading .csv file to determine region..."
# get full CSV path and name
$csvFilePath = Join-Path $PSScriptRoot "in\*.csv"
$csvFileName = Get-ChildItem -Path $csvFilePath -Filter "*.csv" | Select-Object -ExpandProperty Name

# Extract the language code from the CSV filename
$languageCode = $csvFileName -replace '\.csv$'

# Find the matching ShortNames that start with the language code
$matchingShortNames = $shortNames | Where-Object { $_ -like "$languageCode*" }
Start-Sleep -Seconds 0.15

# Check if any matching ShortNames were found
if ($matchingShortNames.Count -eq 0) {
    Write-Host "`nNo ShortNames found for language code: $languageCode"
    return
}


#### Config ####

# Check if config.json exists
Write-Host "Looking for config file..."
Start-Sleep -Seconds 1
$configFilePath = Join-Path $PSScriptRoot "config.json"
if (Test-Path $configFilePath) {
    # Read the config.json file
    $configData = Get-Content -Raw -Path $configFilePath | ConvertFrom-Json

    # Retrieve the values from the config file
    $selectedShortName = $configData.selectedShortName
    $selectedStyle = $configData.selectedStyle
    $selectedSpeed = $configData.selectedSpeed
    $selectedpreSilenceLength = $configData.preSilenceLength
    $selectedpostSilenceLength = $configData.postSilenceLength
    Write-Host "`nConfiguration retrieved from config.json:"
    Write-Host "`nShortName:         $selectedShortName"
    Write-Host "Style:             $(if ($selectedStyle) { $selectedStyle } else { 'none' })"
    Write-Host "Speed Multiplier:  $selectedSpeed"
    Write-Host "Pre-Silence:       $selectedPreSilenceLength ms"
    Write-Host "Post-Silence:      $selectedPostSilenceLength ms"
}
else {
    # 
    Write-Host "`nNo config file found.  Follow the next instructions."
    Start-Sleep -Seconds 1

    # Display the available matching ShortNames
    Write-Host "`nAvailable ShortNames for language code: $languageCode"
    $matchingShortNames
    # Prompt the user to enter the selectedShortName
    $selectedShortName = Read-Host "`nPlease enter the ShortName for the voice you want to use (Press Enter for default: en-US-GuyNeural)"

    # Check if the selected ShortName is empty, if so, use the default value
    if ([string]::IsNullOrEmpty($selectedShortName)) {
        $selectedShortName = "en-US-GuyNeural"
    }

    # Check if the selected ShortName is valid
    while ($selectedShortName -notin $matchingShortNames) {
        Write-Host "Invalid ShortName. Please try again."
        $selectedShortName = Read-Host "Please enter a ShortName"
    }

    # Prompt the user to enter the selectedStyle
    if (($voicesJson | Where-Object { $_.ShortName -eq $selectedShortName }).PSObject.Properties.Name -contains "StyleList") {
        # Get the available styles for the selected ShortName
        $availableStyles = ($voicesJson | Where-Object { $_.ShortName -eq $selectedShortName }).StyleList
        # Display the available styles
        Write-Host "`nAvailable Styles for the selected ShortName: $selectedShortName"
        $availableStyles

        # Prompt the user to enter a style
        $selectedStyle = Read-Host "`nPlease enter the Style for the voice you want to use (Press Enter to skip)"

        # Check if the selected style is empty, if so, set $selectedStyle as null
        if ([string]::IsNullOrEmpty($selectedStyle)) {
            $selectedStyle = $null
            Write-Host "Selected Style: None"
        }
        else {
            # Check if the selected style is valid
            while ($selectedStyle -notin $availableStyles) {
                Write-Host "Invalid Style. Please try again."
                $selectedStyle = Read-Host "Please enter a style"
            }
            Write-Host "Selected Style: $selectedStyle"
        }
    }

    # Prompt the user to enter the selectedSpeed
    $selectedSpeed = Read-Host "`nPlease enter the Speed multiplier for the audio tracks (between 0.5 and 2.0)"

    # Check if the selected speed is within the valid range
    while ([double]$selectedSpeed -lt 0.5 -or [double]$selectedSpeed -gt 2.0) {
        Write-Host "Invalid Speed. Please try again."
        $selectedSpeed = Read-Host "Please enter a speed between 0.5 and 2.0"
    }

    # Prompt the user to enter the selectedPreSilenceLength
    $selectedPreSilenceLength = Read-Host "`nPlease enter the Pre-Silence Length (in milliseconds, press Enter for default: 100)"

    # Check if the selectedPreSilenceLength is empty, if so, use the default value
    if ([string]::IsNullOrEmpty($selectedPreSilenceLength)) {
        $selectedPreSilenceLength = 100
    }

    # Prompt the user to enter the selectedPostSilenceLength
    $selectedPostSilenceLength = Read-Host "`nPlease enter the Post-Silence Length (in milliseconds, press Enter for default: 100)"

    # Check if the selectedPostSilenceLength is empty, if so, use the default value
    if ([string]::IsNullOrEmpty($selectedPostSilenceLength)) {
        $selectedPostSilenceLength = 100
    }

    # Create a hashtable with the selected values
    $configData = @{
        selectedShortName = $selectedShortName
        selectedStyle = $selectedStyle
        selectedSpeed = $selectedSpeed
        preSilenceLength = $selectedPreSilenceLength
        postSilenceLength = $selectedPostSilenceLength
    }

    # Convert the hashtable to JSON and save it to the config.json file
    $configData | ConvertTo-Json | Set-Content -Path $configFilePath
    Write-Host "`nConfiguration saved to config.json.  To change the configuration, delete the config.json file and run the script again, or edit the .json file directly."
}

# Prompt the user to press Enter to start synthesis
Read-Host "`nPress Enter to start synthesis. You can stop it at any time by pressing Ctrl+C."
Start-Sleep -Seconds 1

#### Generate Audio Files ####
Write-Host "Begin synthesis..."
Start-Sleep -Seconds 1

# Get the locale and region for the selected shortname
$selectedLocale = ($voicesJson | Where-Object { $_.ShortName -eq $selectedShortName }).Locale
$selectedLocaleRegion = ($selectedLocale -split '-')[1]

# Read the CSV file
$csvData = Import-Csv -Path $csvFilePath

# Function to check if the file size is greater than 1KB
function CheckFileSize($filePath) {
    $fileInfo = Get-Item $filePath
    if ($fileInfo.Length -gt 1024) {
        return $true
    }
    return $false
}

# Iterate through each row in the CSV starting from the 1st row and send the command to Azure to generate audio for each.
for ($i = 0; $i -lt $csvData.Count; $i++) {
    # Get the filePath and textToGenerate from the current row in CSV
    $filePath = "out/" + $languageCode + "/" + $selectedLocaleRegion + "/" + $csvData[$i].PSObject.Properties.Value[0]
    $textToGenerate = $csvData[$i].PSObject.Properties.Value[1]
    
    # Determine output folder path from .csv  file path
    $folderPath = Split-Path -Path $filePath -Parent
    $folderPath = $folderPath.ToLower()

    # If output folder path doesn't exist, create it.
    if (-not (Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath | Out-Null
    }

    # If audio file already exists for this iteration, skip it.
    if (Test-Path $filePath) {
        Write-Host "File $filePath already exists. Skipping synthesis."
        continue
    }

    # Generate the audio file using spx ssml
    spx synthesize --ssml   "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xmlns:mstts='https://www.w3.org/2001/mstts' xml:lang='$selectedLocale'>
                                <voice name='$selectedShortName'>
                                    <mstts:express-as style='$selectedStyle' styledegree='2'>
                                        <lang xml:lang='$selectedLocale'>
                                            <prosody rate='$selectedSpeed'>
                                                <mstts:silence type='Leading-exact' value='$selectedPreSilenceLength'/>
                                                    $textToGenerate
                                                <mstts:silence type='Tailing-exact' value='$selectedPostSilenceLength'/>
                                            </prosody>
                                        </lang>
                                    </mstts:express-as>
                                </voice>
                            </speak>" --audio output $filePath
    Write-Host "File written to $filePath"

    # Check if the file size is greater than 1KB and retry later if it is not
    $retryCount = 0
    while (-not (CheckFileSize $filePath)) {
        if ($retryCount -ge 5) {
            Write-Host "Audio synthesis failed. Retry limit reached."
            break
        }
        Write-Host "File generated is invalid. There was an error during synthesis.  Retrying..."
        Start-Sleep -Seconds 0.25
        spx synthesize --ssml   "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xmlns:mstts='https://www.w3.org/2001/mstts' xml:lang='$selectedLocale'>
                                <voice name='$selectedShortName'>
                                    <mstts:express-as style='$selectedStyle' styledegree='2'>
                                        <lang xml:lang='$selectedLocale'>
                                            <prosody rate='$selectedSpeed'>
                                                <mstts:silence type='Leading-exact' value='$selectedPreSilenceLength'/>
                                                    $textToGenerate
                                                <mstts:silence type='Tailing-exact' value='$selectedPostSilenceLength'/>
                                            </prosody>
                                        </lang>
                                    </mstts:express-as>
                                </voice>
                            </speak>" --audio output $filePath
        Write-Host "File written to $filePath"
        $retryCount++
    }
}

#### Additional Files to Complete Audiopack ####
# Generate audio.version file
$versionFilePath = Join-Path -Path "out/$languageCode" -ChildPath "audio.version"

# To be updated anytime the audio .csv file is updated by FrSky to prevent audio version mismatch errors in Ethos
$versionContent = "1.5.0"
Set-Content -Path $versionFilePath -Value $versionContent
Write-Host "`nVersion file written to $versionFilePath"

# Copy the input csv file to the out folder
$csvDestinationPath = Join-Path -Path "out/$languageCode" -ChildPath $csvFileName
Copy-Item -Path $csvFilePath -Destination $csvDestinationPath

# Notify the user that the csv file has been copied
Write-Host "CSV file copied to $csvDestinationPath"


#### LOGGING ####

$logFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "log"

# Check if log folder exists
if (Test-Path $logFolderPath) {
    $logFiles = Get-ChildItem -Path $logFolderPath -File

    # If log folder exists, delete all contents
    foreach ($logFile in $logFiles) {
        Remove-Item -Path $logFile.FullName -Force
    }
} else {
    # If log folder does not exist, create it
    New-Item -ItemType Directory -Path $logFolderPath | Out-Null
}
# Copy all new log files to log folder
Move-Item -Path "*.log" -Destination $logFolderPath -Force


#### End Sequence ####

# Notify user that the job is done.
Write-Host "`nSpeech synthesis complete."
Write-Host "Copy the entire contents of the 'out' folder to the audio folder of your SD card."

# Prompt the user to press Enter to close the window
Read-Host "`nPress Enter to close"
