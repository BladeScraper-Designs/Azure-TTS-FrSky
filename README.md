# Azure TTS FrSky
A Powershell V7 script for using Microsoft Azure Speech Synthesis to generate Voice Packs for RC Transmitters.  

Designed, tested, and optimized for use with FrSky radios on Ethos 1.5.  Works for older versions of Ethos, and probably for Open/EdgeTX, but the final output has the folder structure, files, etc in place for Ethos 1.5.

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
### Title: 
Should be a two- or three-letter language code, such as en, fr, de, etc.<br>

### Contents:<br>
Column 1: path to file to be generated.  e.g. system/throttle-hold.wav, system/fm-1.wav, gearup.wav, etc<br>
Column 2: text to convert into speech.  e.g. Throttle Hold, Flight Mode 1, Gear Up, etc<br>

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

5. Once it's gathered the info, it'll look for a config.json file.  If this is the first time running the script, there won't be one, so then it'll ask you to enter your settings for the first batch synthesis, starting with the compatible voices that match the language code from your .csv, e.g. en).
![image](https://github.com/BladeScraper-Designs/Azure-TTS-FrSky/assets/40482965/988f63f9-4b4c-4ae3-b074-b234d197b615)

6. Enter the ShortName voice you want to use.  If you do not, press enter and it will default to en-US-GuyNeural.  If you are generating in a language other than English, the default is still the same, so you'll have to pick one.  The entry is case sensitive.
![image](https://github.com/BladeScraper-Designs/Azure-TTS-FrSky/assets/40482965/b70136b0-51df-491c-ac21-6d0fb3469d2a)

7. If the voice you chose has different styles available, it will list those and ask you to choose.  Press Enter to skip (and keep a the defualt neutral tone), or pick one from the list.
![image](https://github.com/BladeScraper-Designs/Azure-TTS-FrSky/assets/40482965/d610bcae-2488-465e-8f4b-04424e9cefae)

8. It will then ask you for the speed multiplier.  This is pretty self explanatory.  I typically choose 1.25 as it speeds up the voice just a tad, but feel free to experiment and see what works best for you.
![image](https://github.com/BladeScraper-Designs/Azure-TTS-FrSky/assets/40482965/c1dce821-baff-4952-a2a1-fd92bb4edab4)

9. It will then ask you to enter the Pre-Silence and Post-Silence length.  This is the "dead space" before and after the actual speech in the .wav file.  Typically, the default 100ms for both is a good balance, but feel free to experiment.
![image](https://github.com/BladeScraper-Designs/Azure-TTS-FrSky/assets/40482965/fda7d0bc-2136-4d7f-8e09-57dee95f9a74)

10. Once all configuration is finished, it will write your choices to a config.json file.  The next time the script is run, it will skip the configuration steps.
![image](https://github.com/BladeScraper-Designs/Azure-TTS-FrSky/assets/40482965/d0d786b7-7853-4c9e-9913-648e9ab10568)

11. Press enter, and it will begin synthesizing the audio files.

Common Errors:
Error 429: The Azure F0 (Free) pricing tier is limited to 20 requests per minute.  This script runs considerably faster than that, so every once in a while you will get Error 429.  Just let the script keep running and it will retry in a few seconds.<br>
Error 4429: You have exceeded the number of characters per month allowed on your subscription tier (Free is 500,000/mo).  You will not be able to generate any more audio unless you change your subscription type or wait until the next monthly cycle.  





