# Azure TTS FrSky
A Powershell V7 script for using Microsoft Azure Speech Synthesis to generate Voice Packs for RC Transmitters.  

Designed, tested, and optimized for use with FrSky radios on Ethos 1.5.  Works for older versions of Ethos, and probably for Open/EdgeTX, but the final output has the folder structure, files, etc in place for Ethos 1.5.

## Prerequesites
1. A subscription to Microsoft Azure (Free F0 tier will suffice)<br>
   https://azure.microsoft.com/en-us/products/ai-services/text-to-speech
2. PowerShell V7 (will not work on V6)
3. All prerequesites for Speech CLI Quickstart "Download and Install" Section<br>
   https://learn.microsoft.com/en-us/azure/ai-services/speech-service/spx-basics?tabs=windowsinstall%2Cterminal

## Notes
1. This script is written and designed to work with any language supported by Azure TTS.  Languages supported by Azure but not by Ethos may not work without some changes to the folder structure (untested).
2. This script was written largely by GitHub Companion, and stupid AI errors fixed by me (far from an experinced coder), so it's probably some of the ugliest code you've ever seen.  Suggestions for improvements are always welcome.
3. Only one .csv file may be in the 'in' folder.
4. Thanks to Bender for his help in getting this to work.

## CSV File
The script is designed for and needs three features in your CSV:<br>
### Title: 
Should be a two- or three-letter language code, such as en, fr, de, etc.<br>

### Contents:<br>
Column 1: path to file to be generated.  e.g. system/1.wav, system/throttle-hold.wav, system/fm-1.wav, etc<br>
Column 2: text to convert into speech.  e.g. Hello, Throttle Hold, Flight Mode 1, etc<br>

The script is compatible by default with the .csv file provided by FrSky when you download the audiopack from Ethos Suite.<br>

## Downloading
Download the entire repository as a ZIP file.  Extract the contents to anywhere of your choosing.

## Configuring
You need to set your key and region for Azure before the synthesis will work.  To do this, open the .ps1 file with an editor of your choosing (Notepad++ or VSCode are my choices).  

At the top of the file, find this section, and replace yourkey and yourregion with your own information.  Get this info from your Azure Portal TTS Resource Group.

>if (!(Test-Path key) -or !(Test-Path region)) {<br>
>&emsp;spx --% config @key --set yourkey<br>
>&emsp;spx --% config @region --set yourregion<br>
>}

## Usage
First, ensure your have your .csv file located in the 'in' folder.  The downloaded ZIP from this repository includes the latest (for now) Ethos en.csv, but you can change it or update it as needed.

Once you have all of the prerequesites, you should do the following to make it easier to run in the future:
1. The script is a .ps1 script.  By default however, if you just open it it will open in a text editor.  To make it easier, instead, right click the .ps1 file, click Open With, Browse for an App on this PC, navigate to C:\Program Files\PowerShell\7, and click on pwsh.exe.  Click Always so that it always uses this method to run.

