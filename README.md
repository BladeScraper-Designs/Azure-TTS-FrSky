# Azure TTS FrSky
A Powershell V7 script for using Microsoft Azure Speech Synthesis to generate Voice Packs for RC Transmitters.  
Current Script Version: 0.5

Designed, tested, and optimized for use with FrSky radios on Ethos 1.5 and 1.4.  Probably works for Open/EdgeTX too, but not tested.

An example output has been provided: en-AU.zip<br>
It contains the output for both Ethos 1.4 and Ethos 1.5.  Generated with the following settings:<br>
   1. ShortName: en-AU-ElsieNeural
   2. Style: None
   3. Speed Multiplier: 1.25x
   4. Leading Silence: 0ms
   5. Trailing Silence: 25ms

## Prerequesites
1. A subscription to [Microsoft Azure](https://azure.microsoft.com/en-us/products/ai-services/text-to-speech) (Free F0 tier will suffice)<br>
2. PowerShell V7 (will not work on V6)
3. All prerequesites for Speech CLI Quickstart ["Download and Install"](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/spx-basics?tabs=windowsinstall%2Cterminal#download-and-install) Section<br>
4. Speech Service Resource Group.  See Speech CLI Quickstart ["Create a resource configuration"](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/spx-basics?tabs=windowsinstall%2Cterminal#create-a-resource-configuration) section.  You can skip the "To configure your resource key and region identifier, run the following commands:" section because this script does those for you (see Usage below)

## Notes
1. This script is written and designed to work with any language supported by Azure TTS.  Languages supported by Azure but not by Ethos may not work without some changes to the folder structure (untested).
2. Only one .csv file may be in the 'in' folder.
3. Thanks to Bender for his help in getting this to work.

## CSV File
The script is designed for and needs three features in your CSV:<br>
### Filename:<br> 
Should be a two- or three-letter language code, such as en, fr, de, etc.  e.g.: en.csv<br> 

### Contents:<br>
Column 1: path to file to be generated.  e.g. system/throttle-hold.wav, system/fm-1.wav, gearup.wav, etc<br>
Column 2: text to convert into speech.  e.g. Throttle Hold, Flight Mode 1, Gear Up, etc<br>

![image](https://github.com/BladeScraper-Designs/Azure-TTS-FrSky/assets/40482965/95307dfe-c260-4ee8-93ea-831cf03f19fb)

The script is compatible by default with the .csv file provided by FrSky when you download the 1.5 audiopack from Ethos Suite.  Usually this can be found on your radio's SD card or NAND flash.<br>

## Downloading
Download the entire repository as a ZIP file.  Extract the contents to anywhere of your choosing.

## Configuring
You need to set your key and region for Azure before the synthesis will work.  To do this, open the .ps1 file with an editor of your choosing (Notepad++ or VSCode are my choices).  

At the top of the file, find this section, and replace yourkey and yourregion with your own information.  Get this info from your Azure Portal TTS Resource Group.

>spx --% config @key --set yourkey<br>
>spx --% config @region --set yourregion<br>

## Usage
1. Ensure your have your .csv file located in the 'in' folder.  The downloaded ZIP from this repository includes the latest (for now) Ethos en.csv, but you can change it or update it as needed.

2. You should do the following to make it easier to run.  The script is a .ps1 script.  By default, if you just open it, it will open in a text editor (or ask you how to open it if you don't have a suitable editor).  To make it easier to run in the future, right click the .ps1 file, click Open With, Browse for an App on this PC, navigate to C:\Program Files\PowerShell\7, and choose pwsh.exe.  Click Always so that it always uses this method to run.

3. On the first run, it will create a key and region file using the info you put into the top of the script.  Do not delete them, they are necessary for TTS to work and will simply be re-added the next time you run the script.

4. Once the key and region files are written, it will begin reading your .csv and the voices.json file. The voices.json file is a list of voices supported by Azure TTS.  

5. Once it's gathered the info, it'll look for a config.json file.  If this is the first time running the script, there won't be one, so then it'll ask you to enter your settings for the first batch synthesis, starting with the compatible voices that match the language code from your .csv, e.g. en), followed by style (if applicable), speed multiplier, leading and trailing time, and Ethos version.

6. Follow the on-screen prompts.  It's fairly straight-forward.
   
### Common Errors:
Error 429: The Azure F0 (Free) pricing tier is limited to 20 requests per minute.  This script runs considerably faster than that, so every once in a while you will get Error 429.  Just let the script keep running and it will retry in a few seconds.

Error 4429: You have exceeded the number of characters per month allowed on your subscription tier (Free is 500,000/mo).  You will not be able to generate any more audio unless you change your subscription type or wait until the next monthly cycle.  

## Output
Once the script is completed, the synthesized audio can be found in the 'out' folder, according to the configured audio version (1.4, 1.5, or non-ethos).
![image](https://github.com/BladeScraper-Designs/Azure-TTS-FrSky/assets/40482965/af638e56-af15-464e-b26b-fd4d9ed6b61e)


## Other Notes
1. This is a fairly simple script, and there is little special treatment or optimizations for the output audio.  It simply reads from the .csv and sends that information straight to Azure for processing, with your configuration options added.
   
2. The script detects existing .wav files and skips synthesis if the file already exists in that location.  As such, if you want to change only a single audio file (e.g. you don't like the phrase/words used in the .csv originally, or you want to make a custom version of it), you can simply delete that .wav and run the script again after changing that entry in the .csv, and it will only generate that single new file.  This prevents waste of precious characters, the quantity of which are limited by your Azure subscription.
![image](https://github.com/BladeScraper-Designs/Azure-TTS-FrSky/assets/40482965/1201e443-1fd5-49aa-b103-d07ba317ab99)

3. The script also detects changes in your .csv file compared to last run.  If it detects either a changed text to play on an existing file, or detects a new row, it only runs sythesis on the changed/added rows.
![image](https://github.com/BladeScraper-Designs/Azure-TTS-FrSky/assets/40482965/4fc7b555-ba87-4c4a-9b9e-fd83b096a4dd)

4. If no changes in your csv are detected compared to last run, it will re-run all rows but only files that have been deleted or were never synthesized will be synthesized.
![image](https://github.com/BladeScraper-Designs/Azure-TTS-FrSky/assets/40482965/38bac67b-fbc2-43b5-a7c3-d50428feae61)


# Future Goals
1. I'd like to make it more of a menu system rather than just typing in stuff
2. I'd like to add support for the "Options" column (column 3) in the .csv.  Not sure what it'd be used for, I guess that remains to be seen.
3. I'd like to support MultiLingual voices (such as AndrewMultilingualNeural) to allow generation of different languages with the same 'voice'.  Currently, if you choose a language other than English, the en-US-*MultilingualNeural options will not show up, even though they can speak that language.

Any suggestions/feedback are always welcome.

# Changelog
0.1 - Initial Release.<br>
0.5 - Huge update
   1. Added detection of changed or added rows in csv compared to the last run
   2. Vastly improved configuration routine
   3. Improved and shortened main loop
   4. added selection between Ethos 1.4 or Ethos 1.5 format (or neither) and output folder is set according to this config setting
   5. Cleaned up code to the best of my (very limited) ability

