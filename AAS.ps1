#### Welcome Message ####
Write-Host "`nAdvanced Audio Suite (AAS) - Speech Synthesis Script for RC Transmitters"
Write-Host ""
Start-Sleep -Seconds 1.0


#### Check Credentials ####
Write-Host "Checking Azure credentials..." -NoNewline

$credentialsFilePath = Join-Path $PSScriptRoot "usr\credentials.json"

# Check if the key_region.json file exists
if (!(Test-Path $credentialsFilePath)) {
    # Create the key_region.json file with default values
    Write-Host "`nCredentials file not found.  Creating 'usr/credentials.json'."
    $defaultCredentials = @{
        Key = "yourkey"
        Region = "yourregion"
    }
    $defaultCredentials | ConvertTo-Json | Set-Content -Path $credentialsFilePath

    # Prompt the user to enter their Azure key and region
    $key = Read-Host "Please enter your Azure key"
    $region = Read-Host "Please enter your Azure region"
    $credentialsData = @{
        Key = $key
        Region = $region
    }
    # Save the updated key and region to the JSON file
    $credentialsData | ConvertTo-Json | Set-Content -Path $credentialsFilePath
} else {
    # Read the key and region from the JSON file
    $credentialsData = Get-Content -Raw -Path $credentialsFilePath | ConvertFrom-Json
    $key = $credentialsData.Key
    $region = $credentialsData.Region
    Write-Host " OK"
}

if (!(Test-Path (Join-Path $PSScriptRoot "key")) -or !(Test-Path (Join-Path $PSScriptRoot "region"))) {
    Write-Host "`nspx key and/or region files not found.  Setting them based on info in 'usr/credentials.json'"
    $commandKey = "spx --% config @key --set $key"
    $commandRegion = "spx --% config @region --set $region"
    Invoke-Expression $commandKey > $null
    Invoke-Expression $commandRegion > $null
    Write-Host "Azure Key and Region set."
}

$voicesJsonPath = Join-Path $PSScriptRoot "in/voices.json"

# Check if voices.json exists
if (-not (Test-Path $voicesJsonPath)) {
    Write-Host "Getting voices from spx..." -NoNewline
    $output = spx synthesize --voices
    $path = "in/voices.json"

    # Combine the output into a single string
    $outputText = $output -join "`n"

    # Extract the JSON portion of the output, ignoring the preceding text (spx response)
    $jsonStartIndex = $outputText.IndexOf('[')
    if ($jsonStartIndex -ge 0) {
        $jsonOutput = $outputText.Substring($jsonStartIndex)
    }

    # Delete the existing file if it exists
    if (Test-Path -Path $path) {
        Remove-Item -Path $path
    }

    # Write the JSON output to voices.json
    $jsonOutput | Out-File -FilePath $path -Encoding utf8

    if (Test-Path -Path $path) {
        Write-Host " OK"
    } else {
        Write-Host "Failed to create voices JSON file at $path"
        return
    }
} else {
    Write-Host "Reading voices.json..." -NoNewline
    if (Test-Path -Path $voicesJsonPath) {
    Write-Host " OK"
    } else {
        Write-Host "Failed to read voices JSON file at $voicesJsonPath"
        return
    }
}

$voicesJson = Get-Content -Raw -Path $voicesJsonPath | ConvertFrom-Json
Start-Sleep -Seconds 0.25

# Get the list of available ShortNames
$shortNames = $voicesJson | Select-Object -ExpandProperty ShortName

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

$configFilePath = "usr/config.json"

# Check if config.json exists
Write-Host "Reading config..."
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
    Write-Host "`nConfiguration retrieved from config.json:"
    Write-Host "`nShortName:         $selectedShortName"
    Write-Host "Style:               $(if ($selectedStyle) { $selectedStyle } else { 'none' })"
    Write-Host "Speed Multiplier:    $($selectedSpeed)x"
    Write-Host "Leading-Silence:     $($selectedPreSilenceLength)ms"
    Write-Host "Trailing-Silence:    $($selectedPostSilenceLength)ms"
}

if (Test-Path $configFilePath) {
    $deleteConfig = Read-Host "`nTo continue with this configuration, press Enter. To delete the existing config and create a new one, type 'config' and press Enter."
    if ($deleteConfig -eq 'config') {
        Remove-Item -Path $configFilePath -Force
        Write-Host "`nConfig file deleted. Recreating config..."
    }
    else {
        Write-Host "`nContinuing with existing configuration..."
        Write-Host "`n******************************************************************"
    }
}

if (-not (Test-Path $configFilePath)) {
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
    Write-Host "`nConfiguration saved to config.json.  To change the configuration, run the script again and type 'config' when prompted, or delete the config.json file."
    Write-Host "`n******************************************************************"
}

# Get the language, region, and voice from the selected ShortName and set the base file path for synthesized files
$shortNameParts = $selectedShortName -split '-'
$language = $shortNameParts[0]
$region = $shortNameParts[1]

$baseFilePath = "out/$language/$region/"

# Read the CSV file
Get-Content -Path $csvFilePath | Out-Null
$csvData = Import-Csv -Path $csvFilePath 
# Ensure the 'old' directory exists
$oldDirPath = Join-Path $PSScriptRoot "old"
if (-not (Test-Path $oldDirPath)) {
    New-Item -ItemType Directory -Path $oldDirPath | Out-Null
}

# Export csvData to lastCsvData.csv only if lastCsvData doesn't already exist
if (-not (Test-Path "$oldDirPath/lastCsvData.csv")) {
    $csvData | Export-Csv -Path "$oldDirPath/lastCsvData.csv" -NoTypeInformation
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
        if (Test-Path "$baseFilePath/$rowPath") {
            Remove-Item -Path "$baseFilePath/$rowPath" -Force
        }
    }
}   

# Check if the 'text to play' row for a given 'path' row is changed
$newRows = @()
if ($lastCsvData) {
    $lastCsvData = $lastCsvData | Select-Object -ExpandProperty Path
} else {
    $lastCsvData = @()
}

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
    $filePath += $csvData[$i].PSObject.Properties.Value[0]

    # If audio file already exists for this iteration, skip it.
    if (Test-Path $filePath) {
        Write-Host "`nFile $filePath already exists. Skipping synthesis."
        continue
    }

    Write-Host "`nSynthesizing $filePath..." -NoNewline

    # Get the subfolder path from the file path
    $folderPath = Split-Path -Path $filePath -Parent
    # Check if the subfolder path exists, if not, create it
    if (-not (Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath | Out-Null
    }

    $textToGenerate = $csvData[$i].PSObject.Properties.Value[1]

    # Check if the generated file size is greater than 1KB and retry if it is not (up to 3 retries)
    $retryCount = 0
    while (-not ($synthesisFailed)) {
        if ($retryCount -eq 3) {
            Write-Host "Audio synthesis failed. Retry limit reached. Re-run script to try again."
            Remove-Item -Path $filePath -Force
            break
        }
        spx synthesize --ssml   "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xmlns:mstts='https://www.w3.org/2001/mstts' xml:lang='$language-$region'>
                                <voice name='$selectedShortName'>
                                    <mstts:express-as style='$selectedStyle' styledegree='2'>
                                        <lang xml:lang='$language-$region'>
                                            <prosody rate='$selectedSpeed'>
                                                <mstts:silence type='Leading-exact' value='$selectedPreSilenceLength'/>
                                                    $textToGenerate
                                                <mstts:silence type='Tailing-exact' value='$selectedPostSilenceLength'/>
                                            </prosody>
                                        </lang>
                                    </mstts:express-as>
                                </voice>
                            </speak>" --audio output $filePath > $null 

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
    Write-Host " Done"
}

#### Azure Logging Cleanup ####
Write-Host "`nCleaning up..."
$logFolderPath = "log/"
if (Test-Path $logFolderPath) {
    Remove-Item -Path "$logFolderPath\*.log" -Force
} else {
    New-Item -ItemType Directory -Path $logFolderPath | Out-Null
}
Move-Item -Path "*.log" -Destination $logFolderPath -Force


#### End Sequence ####

# Export the csvData.csv to lastCsvData.csv for examination on next run
$lastCsvDataPath = "old/lastCsvData.csv"
Copy-Item -Path $csvFilePath -Destination $lastCsvDataPath -Force


# Notify user that the job is done.
$lowerRegion = $region.ToLower()
Write-Host "`nSpeech synthesis complete.  Synthesized audio can be found in 'out/$language/$lowerRegion'."

# Prompt the user to press Enter to close the window
Read-Host "`nPress Enter to close"
