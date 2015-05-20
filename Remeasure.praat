clearinfo

# GET TIMEPOINTS
start = Get start of selection
end = Get end of selection
duration = (end-start)
midpoint = (start+end)/2
onset = start+(duration/5)
offset = end-(duration/5)

# TAKE FORMANT MEASUREMENTS
Move cursor to... onset
f0_on = Get pitch
f1_on = Get first formant
f2_on = Get second formant
f3_on = Get third formant
f4_on = Get fourth formant

Move cursor to... midpoint
f0_mid = Get pitch
f1_mid = Get first formant
f2_mid = Get second formant
f3_mid = Get third formant
f4_mid = Get fourth formant

Move cursor to... offset
f0_off = Get pitch
f1_off = Get first formant
f2_off = Get second formant
f3_off = Get third formant
f4_off = Get fourth formant

# GET METADATA
rundate$ = date$ ()
edinfo$ = Editor info
maxformant$ = extractWord$ ("'edinfo$'", "Formant maximum formant: ")
maxformant = number (maxformant$)
numformants$ = extractWord$ ("'edinfo$'", "Formant number of poles: ")
numformants = number (numformants$) / 2

# PRINT OUTPUT
print F0: 'f0_on'	'f0_mid'	'f0_off''newline$'F1: 'f1_on'	'f1_mid'	'f1_off''newline$'F2: 'f2_on'	'f2_mid'	'f2_off''newline$'F3: 'f3_on'	'f3_mid'	'f3_off''newline$'F4: 'f4_on'	'f4_mid'	'f4_off''newline$''newline$''f0_on'	'f0_mid'	'f0_off'	'f1_on'	'f1_mid'	'f1_off'	'f2_on'	'f2_mid'	'f2_off'	'f3_on'	'f3_mid'	'f3_off'		Analyst	'rundate$'	Max formant: 'maxformant' Hz, Number of formants: 'numformants'
