#########################################################################################
# VOWEL ANALYZER                                                                        #
#                                                                                       #
# DESCRIPTION:                                                                          #
# This script (modeled on Mietta Lennes' collect_formant_data_from_files.praat          #
# available at http://www.helsinki.fi/~lennes/praat-scripts/ and distributed under the  # 
# GNU General Public License, copyright 4/7/2003) is designed to be run on a set of     #
# soundfiles and TextGrids. It extracts duration (in ms), timestamps (in s), and        #
# F1/F2/F3 from all labeled intervals, and extracts labels for corresponding word,      #
# along with any notes present in the TextGrid. Last, the script outputs the analyst    #
# name, date, settings, OS, and Praat version to the results file. The script can also  #
# be constrained to a user-defined set of words using the "targets" option.             # 
#                                                                                       #
# NOTES:                                                                                #
# 1) Remember to add a / or \ (depending on the OS) to the end of all paths. 2)         #
# Soundfiles and TextGrids must have identical names in order for the script to match   #
# them up. 3) To use the "targets" option, make sure your TextGrid includes a word tier #
# and the "use word tier" option is selected, then create a tab-delimited text file     #
# containing a list of the words (case-sensitive) you'd like to extract, separated by   #
# newlines, with "word" as the column header. 4) If you use Unicode characters in your  #
# TextGrids, make sure Praat's text writing preferences are set to UTF-8 in Windows     #
# before running the script. If you intend to view the results file in Excel, in        #
# Windows you will have to open it from within Excel and import it specifying UTF-8     #
# encoding in order for the characters to display correctly. On OSX, you will first     #
# have to convert the file to UTF-16 Little Endian using a text editor, then import it  #
# into Excel.                                                                           #
#                                                                                       #
# CHANGELOG:                                                                            #
# 02/08/14: Rewrote code for results file generation, added pitch extraction option.    #
# 02/07/14: Added metadata output to the script (analyst, version, settings, etc.).     #
# 10/23/13: Changed the behavior of the script to target only non-empty intervals.      #
# 06/26/13: Fixed bug introduced by a recent version of Praat.                          #
# 03/10/13: Reordered formant options.                                                  #
# 02/22/13: Added option to append data to an existing results file.                    #
# 02/19/13: Added counter for number of vowels analyzed if using targets option.        #
# 02/14/13: Fixed a bug involving running the script over multiple files, simplified    # 
#           the extraction of sounds from longsounds.                                   #
# 01/19/13: Added ability to select the formant measurement points.                     #
# 01/01/13: Release version.                                                            #
#                                                                                       #
# This modified script distributed under the GNU General Public License v3 or higher,   #
# copyright 1/2013, John Riebold (riebold@uw.edu).                                      #
#########################################################################################

# PROMPT THE USER FOR LOCATION OF INPUT/OUTPUT FILES, FORMANT SETTINGS, ETC.
form Vowel Analyzer
	comment Paths:
	sentence Soundfile_directory 
	sentence Textgrid_directory 
	sentence Results_file results.txt
	optionmenu Use_targets_file 2
		option yes
		option no
	sentence Targets_file targets.txt
	comment Tiers:
	sentence Vowel_tier vowel
	optionmenu Use_word_tier: 2
		option yes
		option no
	sentence Word_tier word
	optionmenu Use_notes_tier: 2
		option yes
		option no
	sentence Notes_tier notes
	comment Formant settings:
	optionmenu Measurement_points: 4
		option Midpoint
		option 30%/50%/70%
		option 25%/50%/75%
		option 20%/50%/80%
	positive Maximum_formant_(Hz) 5500
	integer Number_of_formants 5
	comment Pitch Settings
	optionmenu Extract_pitch: 2
		option yes
		option no
	integer left_Pitch_range_(Hz) 75
	integer right_Pitch_range_(Hz) 500
	comment Analyst:
	sentence Initials
endform

if use_targets_file = 1 and use_word_tier = 2
	exit Error: the targets file option requires a word tier.
endif

# SET ADDITIONAL FORMANT OPTIONS, CHANGE IF NECESSARY
preemphasis_from = 50
window_length = 0.025
time_step = 0.01

# DEFINE EMPTY VARIABLES IN CASE TIERS ARE EMPTY/NOT PRESENT IN THE TEXTGRID
word_label$ = ""
notes_label$ = ""
preceding_label$ = ""
following_label$ = ""

# DEFINE DUMMY COUNTER VARIABLES FOR END-OF-SCRIPT REPORT
sound_count = 0
vowel_count = 0
target_vowel_count = 0

# GET TIME AND OS
rundate$ = date$ ()
if windows = 1
    os$ = "Windows"
elsif macintosh = 1
    os$ = "OSX"
elsif unix = 1
	os$ = "Linux"
endif
version$ = "'praatVersion'"
version$ = replace_regex$ ("'version$'", "(\d)(\d)(\d{2,2})", "\1.\2.\3", 0)

# INITIALIZE RESULTS FILE
if fileReadable (results_file$)
	beginPause ("Warning")
		comment ("The file 'results_file$' already exists.")
	results_choice = endPause ("Append", "Overwrite", 1)
	if results_choice = 2
		filedelete 'results_file$'
		call InitializeResultsFile
	endif
else
	call InitializeResultsFile
endif

# OPEN TARGETS FILE
if use_targets_file = 1
	Read Table from tab-separated file... 'targets_file$'
	targets$ = selected$ ("Table", 1)
endif

# CREATE LIST OF SOUNDFILES IN DIRECTORY
Create Strings as file list... list 'soundfile_directory$'*.wav
numberoffiles = Get number of strings

# GO THROUGH EACH SOUNDFILE
for ifile to numberoffiles
	select Strings list
	filename$ = Get string... ifile

	# OPEN SOUNDFILE
	Open long sound file... 'soundfile_directory$''filename$'
	soundfile$ = selected$ ("LongSound", 1)

	# INCREMENT SOUND COUNT
	sound_count = sound_count + 1

	# OPEN A TEXTGRID OF THE SAME NAME
	gridfile$ = "'textgrid_directory$''soundfile$'.TextGrid"
	if fileReadable (gridfile$)
		Read from file... 'gridfile$'

		# FIND TIER NUMBER FOR VOWEL AND WORD TIERS
		call GetTier 'vowel_tier$' vowel_tier
		if use_word_tier = 1
			call GetTier 'word_tier$' word_tier
		endif
		intervals = Get number of intervals... vowel_tier

		# EXTRACT ANNOTATED PORTION OF SOUNDFILE
		gridstart = Get start time
		gridend = Get end time
		select LongSound 'soundfile$'
		Extract part... gridstart gridend yes

		# REMOVE LONGSOUND
		select LongSound 'soundfile$'
		Remove

		# EXTRACT FORMANT AND PITCH OBJECTS
		select Sound 'soundfile$'
		To Formant (burg)... time_step number_of_formants maximum_formant window_length preemphasis_from
		if extract_pitch = 1
			select Sound 'soundfile$'
			To Pitch... 0 left_Pitch_range right_Pitch_range
		endif

		# PASS THROUGH EACH INTERVAL IN SELECTED TIER AND GET LABEL
		for interval to intervals
			select TextGrid 'soundfile$'
			phone_label$ = Get label of interval... vowel_tier interval

			# MAKE SURE LABEL NOT EMPTY
			if phone_label$ <> ""

				# INCREMENT VOWEL COUNT
				vowel_count = vowel_count + 1

				# GET START AND END TIMES, CALCULATE DURATION, ETC.
				start = Get starting point... vowel_tier interval
				end = Get end point... vowel_tier interval
				duration = (end-start)
				duration_ms = duration*1000
				midpoint = (start+end)/2

				# DETERMINE WHICH POINTS TO MEASURE
				if measurement_points = 2
					onset = start+(duration*0.3)
					offset = end-(duration*0.3)
				elsif measurement_points = 3
					onset = start+(duration/4)
					offset = end-(duration/4)
				elsif measurement_points = 4
					onset = start+(duration/5)
					offset = end-(duration/5)
				endif

				# GET FORMANT VALUES AT INTERVAL(S)
				select Formant 'soundfile$'
				f1_2 = Get value at time... 1 midpoint Hertz Linear
				f2_2 = Get value at time... 2 midpoint Hertz Linear
				f3_2 = Get value at time... 3 midpoint Hertz Linear
				if measurement_points != 1
					f1_1 = Get value at time... 1 onset Hertz Linear
					f2_1 = Get value at time... 2 onset Hertz Linear
					f3_1 = Get value at time... 3 onset Hertz Linear
					f1_3 = Get value at time... 1 offset Hertz Linear
					f2_3 = Get value at time... 2 offset Hertz Linear
					f3_3 = Get value at time... 3 offset Hertz Linear
				endif

				# EXTRACT PITCH AT INTERVAL(S)
				if extract_pitch = 1
					select Pitch 'soundfile$'
					f0_2 = Get value at time... midpoint Hertz Linear
					if measurement_points != 1
						f0_1 = Get value at time... onset Hertz Linear
						f0_3 = Get value at time... offset Hertz Linear
					endif
				endif

				# GET WORD VOWEL IS FROM
				if use_word_tier = 1
					select TextGrid 'soundfile$'
					word = Get interval at time... word_tier midpoint
					word_label$ = Get label of interval... word_tier word
				endif

				# GET CONTENTS OF NOTES TIER
				if use_notes_tier = 1
					call GetTier 'notes_tier$' notes_tier
					note = Get interval at time... notes_tier midpoint
					notes_label$ = Get label of interval... notes_tier note
				endif

				# CREATE RESULTS LINE
				if use_word_tier = 1
					resultsline_begin$ = "'soundfile$'	'word_label$'	'phone_label$'	'start'	'end'	'duration_ms'	"
				else
					resultsline_begin$ = "'soundfile$'	'phone_label$'	'start'	'end'	'duration_ms'	"
				endif
				if use_notes_tier = 1
					resultsline_end$ = "'notes_label$'	'initials$'	'rundate$'	Max formant: 'maximum_formant' Hz, Number of formants: 'number_of_formants', Window length: 'window_length' s	'version$'	'os$''newline$'"
				else
					resultsline_end$ = "'initials$'	'rundate$'	Max formant: 'maximum_formant' Hz, Number of formants: 'number_of_formants', Window length: 'window_length' s	'version$'	'os$''newline$'"
				endif
				resultsline_middle$ = "'f1_1'	'f1_2'	'f1_3'	'f2_1'	'f2_2'	'f2_3'	'f3_1'	'f3_2'	'f3_3'	"
				if measurement_points = 1
					resultsline_middle$ = "'f1_2'	'f2_2'	'f3_2'	"
					if extract_pitch = 1
						resultsline_middle$ = "'f0_2'	" + resultsline_middle$
					endif
				elsif measurement_points != 1 and extract_pitch = 1
					resultsline_middle$ = "'f0_1'	'f0_2'	'f0_3'	" + resultsline_middle$
				endif
				resultsline$ = resultsline_begin$ + resultsline_middle$ + resultsline_end$

				# OUTPUT TO RESULTS FILE
				if use_targets_file = 1
					select Table 'targets$'
					match = Search column... word 'word_label$'
					if match
						target_vowel_count = target_vowel_count + 1
						fileappend "'results_file$'" 'resultsline$'
					endif
				else
					target_vowel_count = target_vowel_count + 1
					fileappend "'results_file$'" 'resultsline$'
				endif
			endif
		endfor

		# REMOVE TEXTGRID OBJECT FROM THE OBJECT LIST
		select TextGrid 'soundfile$'
		Remove
	endif

	# REMOVE TEMPORARY OBJECTS AND CONTINUE TO NEXT FILE
	select Sound 'soundfile$'
	plus Formant 'soundfile$'
	if extract_pitch = 1
		plus Pitch 'soundfile$'
	endif
	Remove
endfor

# REMOVE REST OF OBJECTS AND FINISH
select Strings list
if use_targets_file = 1
	plus Table 'targets$'
endif
Remove

# PRINT A REPORT
echo Done. Analyzed 'target_vowel_count' of 'vowel_count' vowels in 'sound_count' file(s).

# PROCEDURE TO INITIALIZE RESULTS FILE
procedure InitializeResultsFile
	if use_word_tier = 1
		header_begin$ = "Filename	Word	Vowel	Begin Time (s)	End Time (s)	Duration (ms)	"
	else
		header_begin$ = "Filename	Vowel	Begin Time (s)	End Time (s)	Duration (ms)	"
	endif
	if use_notes_tier = 1
		header_end$ = "Notes	Analyst	Date	Settings	Praat Version	OS'newline$'"
	else
		header_end$ = "Analyst	Date	Settings	Praat Version	OS'newline$'"
	endif
	if measurement_points = 1
		header_middle$ = "F1 50%	F2 50%	F3 50%	"
		if extract_pitch = 1
			header_middle$ = "F0 50%	" + header_middle$
		endif
	elsif measurement_points = 2
		header_middle$ = "F1 30%	F1 50%	F1 70%	F2 30%	F2 50%	F2 70%	F3 30%	F3 50%	F3 70%	"
		if extract_pitch = 1
			header_middle$ = "F0 30%	F0 50%	F0 70%	" + header_middle$
		endif
	elsif measurement_points = 3
		header_middle$ = "F1 25%	F1 50%	F1 75%	F2 25%	F2 50%	F2 75%	F3 25%	F3 50%	F3 75%	"
		if extract_pitch = 1
			header_middle$ = "F0 25%	F0 50%	F0 75%	" + header_middle$
		endif
	elsif measurement_points = 4
		header_middle$ = "F1 20%	F1 50%	F1 80%	F2 20%	F2 50%	F2 80%	F3 20%	F3 50%	F3 80%	"
		if extract_pitch = 1
			header_middle$ = "F0 20%	F0 50%	F0 80%	" + header_middle$
		endif
	endif
	header$ = header_begin$ + header_middle$ + header_end$
	fileappend "'results_file$'" 'header$'
endproc

# PROCEDURE TO FIND NUMBER OF TIER WITH GIVEN LABEL
procedure GetTier name$ variable$
	numberOfTiers = Get number of tiers
	itier = 1
	repeat
		tier$ = Get tier name... itier
		itier = itier + 1
	until tier$ = name$ or itier > numberOfTiers
	if tier$ <> name$
		'variable$' = 0
	else
		'variable$' = itier - 1
	endif
	if 'variable$' = 0
		exit The tier 'name$' is missing from the file 'soundfile$'!
	endif
endproc
