#### Welcome Message ####
Write-Host "Azure TTS Script for FrSky Ethos RC Transmitters"
Start-Sleep -Seconds 1.0

Write-Host "`nChecking for Azure key and region files..."
Start-Sleep -Seconds 0.25
$keyFilePath = Join-Path $PSScriptRoot "key"
$regionFilePath = Join-Path $PSScriptRoot "region"
if (!(Test-Path $keyFilePath) -or !(Test-Path $regionFilePath)) {
    Write-Host "Key and region files not found. Sending spx config commands..."
    Write-Host "`n"
    # Write spx config commands
    spx --% config @key --set yourkey
    spx --% config @region --set yourregion
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
Start-Sleep -Seconds 0.25

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
Start-Sleep -Seconds 0.25

# Check if any matching ShortNames were found
if ($matchingShortNames.Count -eq 0) {
    Write-Host "`nNo ShortNames found for language code: $languageCode"
    return
}


#### Config ####

$configFilePath = "config.json"

# Check if config.json exists
Write-Host "Reading config file..."
Start-Sleep -Seconds 0.5

if (Test-Path $configFilePath) {
    # Read the config.json file
    $configData = Get-Content -Raw -Path $configFilePath | ConvertFrom-Json

    # Retrieve the values from the config file
    $selectedShortName = $configData.selectedShortName
    $selectedStyle = $configData.selectedStyle
    $selectedSpeed = $configData.selectedSpeed
    $selectedpreSilenceLength = $configData.preSilenceLength
    $selectedpostSilenceLength = $configData.postSilenceLength
    $selectedAudioVersion = $configData.ethosAudioVersion
    Write-Host "`nConfiguration retrieved from config.json:"
    Write-Host "`nShortName:         $selectedShortName"
    Write-Host "Style:             $(if ($selectedStyle) { $selectedStyle } else { 'none' })"
    Write-Host "Speed Multiplier:  $($selectedSpeed)x"
    Write-Host "Pre-Silence:       $($selectedPreSilenceLength)ms"
    Write-Host "Post-Silence:      $($selectedPostSilenceLength)ms"
    Write-Host "Ethos Version:     $(if ($selectedAudioVersion) { $selectedAudioVersion } else { 'none' })"
}

# If config.json does not exist, begin config routine
else {
    # 
    Write-Host "`nNo config file found.  Follow the next instructions."
    Start-Sleep -Seconds 2

    # Display the available matching ShortNames
    Write-Host "`nAvailable ShortNames for language code: $languageCode"
    $matchingShortNames
    
    # Prompt the user to enter the ShortName
    while ($true) {
            $selectedShortName = Read-Host "`nEnter the ShortName for the voice you want to use, or press Enter for default: en-US-GuyNeural"
            if ([string]::IsNullOrEmpty($selectedShortName)) {
                $selectedShortName = 'en-US-GuyNeural'
                break
            }
            if ($selectedShortName -in $matchingShortNames) {
                break
            }
            Write-Host "`nInvalid ShortName. Please try again."
        }
    Write-Host "Selected ShortName: $selectedShortName"

    # Prompt the user to enter the selectedStyle
    if (($voicesJson | Where-Object { $_.ShortName -eq $selectedShortName }).PSObject.Properties.Name -contains "StyleList") {
        # Get the available styles for the selected ShortName
        $availableStyles = ($voicesJson | Where-Object { $_.ShortName -eq $selectedShortName }).StyleList
        # Display the available styles
        Write-Host "`nAvailable Styles for $($selectedShortName)"
        $availableStyles
        # Prompt the user to enter the selectedStyle
        while ($true) {
            $selectedStyle = Read-Host "`nEnter the Style you want to use, or press Enter to skip."
            if ([string]::IsNullOrEmpty($selectedStyle)) {
                $selectedStyle = $null
                break
            }
            if ($selectedStyle -in $availableStyles) {
                break
            }
            Write-Host "`nInvalid Style. Please try again."
        }
        Write-Host "Selected Style: $(if ($selectedStyle) { $selectedStyle } else { 'none' })"
    }
    else {
        Write-Host "`nNo alternate styles available for $selectedShortName. Skipping Style selection."
        $selectedStyle = $null
    }

   # Prompt the user to enter the Speed Multiplier
    while ($true) {
        $selectedSpeed = Read-Host  "`nEnter the Speed multiplier for the audio tracks between (0.5 and 2.0), or press Enter for default: 1.25"
        if ([string]::IsNullOrEmpty($selectedSpeed)) {
            $selectedSpeed = 1.25
            break
        }
        if ($selectedSpeed -ge 0.5 -and $selectedSpeed -le 2.0) {
            break
        }
        Write-Host "`nInvalid Silence Length.  Please try again."
    }
    Write-Host "Selected Speed Multiplier: $($selectedSpeed)x"

   # Prompt the user to enter the Pre-Silence Length
    while ($true) {
        $selectedPreSilenceLength = Read-Host  "`nEnter the Pre-Silence Length (in milliseconds, max 5000), or press Enter for default: 0)"
        if ([string]::IsNullOrEmpty($selectedPreSilenceLength)) {
            $selectedPreSilenceLength = 0
            break
        }
        if ($selectedPreSilenceLength -ge 0 -and $selectedPreSilenceLength -le 5000) {
            break
        }
        Write-Host "`nInvalid Silence Length.  Please try again."
    }
    Write-Host "Selected Pre-Silence Length: $($selectedPreSilenceLength)ms"

   # Prompt the user to enter the Post-Silence Length
    while ($true) {
        $selectedPostSilenceLength = Read-Host  "`nEnter the Post-Silence Length (in milliseconds, max 5000), or press Enter for default: 25)"
        if ([string]::IsNullOrEmpty($selectedPostSilenceLength)) {
            $selectedPostSilenceLength = 25
            break
        }
        if ($selectedPostSilenceLength -ge 0 -and $selectedPostSilenceLength -le 5000) {
            break
        }
        Write-Host "`nInvalid Silence Length.  Please try again."
    }
    Write-Host "Selected Post-Silence Length: $($selectedPostSilenceLength)ms"

    # Prompt the user to enter the Ethos version (1.4.x or 1.5.x or press Enter to skip)
    while ($true) {
        Write-Host "`nEnter the version of Ethos that you'd like to generate for."
        $selectedAudioVersion = Read-Host  "If generating for non-Ethos radios, press Enter to skip."
        if ([string]::IsNullOrEmpty($selectedAudioVersion)) {
            $selectedAudioVersion = $null
            break
        }
        if ($selectedAudioVersion -match '^1\.4\.[0-99]+$' -or $selectedAudioVersion -match '^1\.5\.[0-99]+$') {
            break
        }
        Write-Host "`nInvalid Ethos Version. Please try again."
    }
    Write-Host "Selected Ethos Version: $(if ($selectedAudioVersion) { $selectedAudioVersion } else { 'none' })"
    Start-Sleep -Seconds 1

    # Create a hashtable with the selected values
    $configData = @{
        selectedShortName = $selectedShortName
        selectedStyle = $selectedStyle
        selectedSpeed = $selectedSpeed
        preSilenceLength = $selectedPreSilenceLength
        postSilenceLength = $selectedPostSilenceLength
        ethosAudioVersion = $selectedAudioVersion
    }

    # Convert the hashtable to JSON and save it to the config.json file
    $configData | ConvertTo-Json | Set-Content -Path $configFilePath
    Write-Host "`nConfiguration saved to config.json.  To change the configuration, delete the config.json file and run the script again, or edit the .json file directly."
    Write-Host "`n******************************************************************"
}

Write-Host "`nConfiguring output based on config settings..."

# Get the locale (en-US) and region (US) for the selected ShortName
$selectedLocale = ($voicesJson | Where-Object { $_.ShortName -eq $selectedShortName }).Locale
$selectedLocaleRegion = ($selectedLocale -split '-')[1]

# Read the CSV file
Get-Content -Path $csvFilePath | Out-Null
$csvData = Import-Csv -Path $csvFilePath 
# export csvData to lastCsvData.csv only if lastCsvData doesn't already exist
if (-not (Test-Path "old/lastCsvData.csv")) {
    $csvData | Export-Csv -Path "old/lastCsvData.csv" -NoTypeInformation
}

# Get the short version of the Ethos version (1.4 or 1.5) if applicable
if ($selectedAudioVersion) {
    $shortVersion = $selectedAudioVersion.Substring(0, 3)
}

# Get base output path from $selectedAudioVersion
$baseFilePath = "out/"
switch -Wildcard ($shortVersion) {
    "1.4" { $baseFilePath += $shortVersion + "/" + $languageCode + "/"}
    "1.5" { $baseFilePath += $shortVersion + "/" + $languageCode + "/" + $selectedLocaleRegion.ToLower() + "/" }
    $null { $baseFilePath += "non-ethos/" }
}

#### Check csvData.csv and compare to $csvData to determine if any changes have been made ####
Write-Host "`nChecking for changes in .csv file from last run..."
Start-Sleep -Seconds 0.5

$lastCsvData = Import-Csv -Path "old/lastCsvData.csv"
# Check if the 'text to play' row for a given 'path' row has changed from the last run
$changedRows = @()
foreach ($row in $csvData) {
    $rowPath = $row.Path
    $textToPlay = $row.'text to play'
    $lastRowPath = $lastCsvData | Where-Object { $_.Path -eq $rowPath }
    if ($lastRowPath -and $lastRowPath.'text to play' -ne $textToPlay) {
        $changedRows += $row
        Write-Host "$rowPath text to play has changed.  Removing old audio file."
        # This would be a lot easier if I could just use the $baseFilePath variable like in the 'else' section, but Ethos 1.4's audio file layout is weird so I have to examine the path to determine where to delete the file from
        if ($selectedAudioVersion -eq "1.4" -and (-not($rowPath -like "*/*.wav"))) {
            if (Test-Path "out/1.4/$rowPath") {
                Remove-Item -Path "out/1.4/$rowPath" -Force
            }
        }
        else {
            if (Test-Path "$baseFilePath/$rowPath") {
                Remove-Item -Path "$baseFilePath/$rowPath" -Force
            }
        }
    }
}   

# Check if the 'text to play' row for a given 'path' row is changed
$newRows = @()
$lastCsvData = $lastCsvData | Select-Object -ExpandProperty Path

# Check if any new rows have been added to the .csv file since last run
foreach ($row in $csvData) {
    $rowPath = $row.Path
    $textToPlay = $row.'text to play'
    if (-not $lastCsvData.Contains($rowPath)) {
        $newRows += $row
        Write-Host "$rowPath is a new row."
    }
}

# Figure out what to do with $csvData (what files to generate)
if (($changedRows) -and ($newRows)) {
    $csvData = $changedRows + $newRows
    Write-Host "`nChanges detected in .csv file.  Synthesizing new and changed rows."
}
elseif ($changedRows.Count -gt 0) {
    $csvData = $changedRows
    Write-Host "`nChanges detected in .csv file.  Synthesizing changed rows."
}
elseif ($newRows.Count -gt 0) {
    $csvData = $newRows
    Write-Host "`nChanges detected in .csv file.  Synthesizing new rows."
}
else {
    Write-Host "`nNo changes detected in .csv file. Only deleted or never-created files will be synthesized."
    $csvData = Import-Csv -Path $csvFilePath 
}

#### Wait for User Confirmation to Start Synthesis ####

# Prompt the user to press Enter to start synthesis
Read-Host "`nPress Enter to start synthesis. You can stop it at any time by pressing Ctrl+C."

Write-Host "`nBegin synthesis..."
Start-Sleep -Seconds 0.5


#### Synthesize Audio Files ####

# Set synthesisFailed to false for first run
[boolean] $synthesisFailed = $false

# Main loop to iterate through each synthesis cycle
for ($i = 0; $i -lt $csvData.Count; $i++) {
    # Set filepath to base file path for each iteration
    $filePath = $baseFilePath

    # code to figure out what directory to put the .wav in because Ethos 1.4's audio file layout is weird
    if ($shortVersion -eq "1.4" -and (-not ($csvData[$i].PSObject.Properties.Value[0] -like "*/*.wav"))) {
        $filePath = Split-Path -Path $filePath -Parent
        $filePath += "/"
    }

    # Get full file path from .csv data and append it to base file path based on Ethos version
    $filePath += $csvData[$i].PSObject.Properties.Value[0]

    # If audio file already exists for this iteration, skip it.
    if (Test-Path $filePath) {
        Write-Host "File $filePath already exists. Skipping synthesis."
        continue
    }

    # Get the subfolder path from the file path
    $folderPath = Split-Path -Path $filePath -Parent
    # Check if the subfolder path exists, if not, create it
    if (-not (Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath | Out-Null
    }

    $textToGenerate = $csvData[$i].PSObject.Properties.Value[1]

    # Check if the file size is greater than 1KB and retry later if it is not
    $retryCount = 0
    while (-not ($synthesisFailed)) {
        if ($retryCount -eq 5) {
            Write-Host "Audio synthesis failed. Retry limit reached. Re-run script to try again."
            Remove-Item -Path $filePath -Force
            break
        }
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

        # Check if the file size is greater than 1KB (to detect if there was an error during synthesis)
        if ((Get-Item $filePath).Length -lt 1024) {
            $retryCount++
            Write-Host "File generated is invalid. There was an error during synthesis.  Retrying..."
            Write-Host "Retry Count: $retryCount" 
            Start-Sleep -Seconds 0.25
        }
        else {
            $synthesisFailed = $false
            $retryCount = 0
            break
        }
    }
    # Reset $synthesisFailed for the next iteration
    $synthesisFailed = $false 
 
}

Write-Host "`nCopying files..."


#### Azure Logging Cleanup ####

$logFolderPath = "log/"
if (Test-Path $logFolderPath) {
    Remove-Item -Path "$logFolderPath\*.log" -Force
} else {
    New-Item -ItemType Directory -Path $logFolderPath | Out-Null
}
Move-Item -Path "*.log" -Destination $logFolderPath -Force


#### End Sequence ####

# Export the csvData.csv to lastCsvData.csv for examination on next run
$csvDataPath = "in/csvData.csv"
$lastCsvDataPath = "old/lastCsvData.csv"
Copy-Item -Path $csvDataPath -Destination $lastCsvDataPath -Force

# Notify user that the job is done.
Write-Host "`nSpeech synthesis complete."

switch ($shortVersion) {
    "1.4" { 
        Set-Content -Path "out/$shortVersion/$languageCode/audio.version" -Value $selectedAudioVersion
        Write-Host "`nAudio pack has been organized for FrSky Ethos version $shortVersion"
        Write-Host "Copy the entire contents of the 'out/$shortVersion' folder to the audio folder of your SD card or NAND."
    }
    "1.5" { 
        Set-Content -Path "out/$shortVersion/$languageCode/audio.version" -Value $selectedAudioVersion
        Copy-Item -Path $csvFilePath -Destination "out/1.5/$languageCode/$csvFileName"
        Write-Host "`nAudio pack has been organized for FrSky Ethos version $shortVersion"
        Write-Host "Copy the entire contents of the 'out/$shortVersion' folder to the audio folder of your SD card or NAND."
    }
    default {
        Write-Host "`nSynthesized audio can be found in the 'out/non-ethos' folder."
    }
}

# Prompt the user to press Enter to close the window
Read-Host "`nPress Enter to close"
