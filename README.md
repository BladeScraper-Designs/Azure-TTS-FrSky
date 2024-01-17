# Azure TTS FrSky
A Powershell V7 script for using Microsoft Azure Speech Synthesis to generate Voice Packs for FrSky RC Transmitters

## Prerequesites
1. A subscription to Microsoft Azure (Free F0 tier will suffice for at least 10 complete voice pack generations per month)
   https://azure.microsoft.com/en-us/products/ai-services/text-to-speech
2. All prerequesites for Azure Text to Speech Quickstart CLI
   https://learn.microsoft.com/en-us/azure/ai-services/speech-service/get-started-text-to-speech?tabs=windows%2Cterminal&pivots=programming-language-cli
3. Powershell V7 (will not work on standard PS V6).

## Other Requirements
1. You must have the CSV file distributed by FrSky in their audio packs.

## Notes
1. This script has only been tested with English (US) and English (GB) voices.  It's written and designed to work with any language supported by Azure TTS, but I have not tested all of them.
2. 
