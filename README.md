# Azure TTS FrSky
A Powershell V7 script for using Microsoft Azure Speech Synthesis to generate Voice Packs for RC Transmitters.  
Designed, tested, and optimized for use with FrSky radios on Ethos 1.5.  Works for older versions of Ethos, and probably for Open/EdgeTX, but the final output has the folder structure, files, etc in place for Ethos 1.5.

## Prerequesites
1. A subscription to Microsoft Azure (Free F0 tier will suffice for at least 10 complete voice pack generations per month)
   https://azure.microsoft.com/en-us/products/ai-services/text-to-speech
2. All prerequesites for Azure Text to Speech Quickstart CLI
   https://learn.microsoft.com/en-us/azure/ai-services/speech-service/get-started-text-to-speech?tabs=windows%2Cterminal&pivots=programming-language-cli
3. Powershell V7 (will not work on Powershell V6)

## Other Requirements
1. CSV File for Audio to Generate<br>
&emsp;The script is designed for and needs three features in your CSV:<br>
&emsp;Title: Should be a two- or three-letter language code, such as en, fr, de, etc.<br>
&emsp;Contents:<br>
&emsp;&emsp;Column 1: path to file to be generated.  e.g. system/1.wav, system/throttle-hold.wav, system/fm-1.wav, etc<br>
&emsp;&emsp;Column 2: text to convert into speech.  e.g. Hello, Throttle Hold, Flight Mode 1, etc<br>

&emsp;The script is compatible by default with the .csv file provided by FrSky when you download the audiopack from Ethos Suite.  An example (from FrSky) is provided in the download.<br>

## Notes
1. This script is written and designed to work with any language supported by Azure TTS.  Languages supported by Azure but not by Ethos may not work without some changes to the folder structure (untested).
2. This script was written mostly by GitHub Companion, and fixed by me (far from an experinced coder), so it's probably some of the ugliest code you've ever seen.
3. Thanks to Bender for his help in getting this to work.
