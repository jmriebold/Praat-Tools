# Praat-Tools
A collection of useful Praat scripts I've developed over the years for my research. All should be reasonably well-commented and easily adapted to more specific use cases.

## Vowel-Analyzer.praat
A script designed to extract vowel formants, duration, timestamps, and other information from TextGrids. This script is intended to be used on traditional TextGrids where the only intervals are the vowels to be analyzed.

## Arpabet-Hand-Corrector.praat
Force-aligned TextGrids (e.g. from P2FA/FAVE) must be hand-corrected before any automated measurement can be done if precise duration and formant interval values are needed. This script is designed to speed up the process and be customized to fit the needs of the analyst, but must be edited before using.

## Arpabet-Vowel-Analyzer.praat
A script designed to extract vowel formants, duration, timestamps, and other information from P2FA/FAVE-generated TextGrids. It supports the use of a targets file to analyze only a subset of words.

## Remeasure
An editor window script for remeasuring formants (e.g. when automatic measurement yields erroneous values).
