#########################################################################################
# ARPABET HAND-CORRECTOR                                                                #
#                                                                                       #
# DESCRIPTION:                                                                          #
# This script (modeled on Dan McCloy's SemiAutoPitchAnalysis.praat, available at        #
# http://students.washington.edu/drmccloy/resources/SemiAutoPitchAnalysis.praat and     #
# distributed under the GNU General Public License, copyright 2012) is designed to      #
# facilitate the hand-correction of P2FA-generated TextGrids by stepping through the    #
# intervals of interest and prompting the user to adjust the boundaries. It can         #
# automatically create a notes tier, and generates a progress file when the user hasn't # 
# finished correcting a file so that they can resume corrections later. All corrections #
# are saved to a new TextGrid file, and a report file is created containing a summary   #
# of the actions taken                                                                  #
#                                                                                       #
# NOTES:                                                                                #
# 1) IMPORTANT: this script is a skeleton, containing example target environments for   #
# hand-correction. To use it, replace the placeholders with the target                  #
# environments/segments of interest the appropriate places in the file (in the settings # 
# and later on, look for the comments). 2) Remember to add a / or \ (depending on the   #
# OS) to the end of all paths. 3) Soundfiles and TextGrids must have identical names in #
# order for the script to match them up. 4) To use the "targets" option, create a       #
# tab-delimited text file containing a list of the words (case-sensitive) you'd like to # 
# extract, separated by newlines, with "word" as the column header.                     #
#########################################################################################

# DISPLAY SETTINGS FORM
form Arpabet Hand-Corrector
	comment Paths:
	sentence Textgrid_directory
	sentence Soundfile_directory
	sentence Targets_file targets.txt
	comment Tiers:
	optionmenu Create_notes_tier: 2
		option Yes
		option No
	comment Settings:
	# *****CHANGE THESE NAMES*****
	optionmenu Targets: 1
		option CUSTOM OPTION 1
		option CUSTOM OPTION 2
		option CUSTOM OPTION 3
		option Use targets file
	real Zoom_duration 0.25
endform

# SET TIER NAMES, CHANGE IF NECESSARY
phone_tier$ = "phone"
word_tier$ = "word"

# INITIALIZE VARIABLES
file_count = 0
token_count = 0
skipped_count = 0
files_read$ = ""
corrected_tokens$ = ""
skipped_tokens$ = ""
continue = 0

# OPEN THE TARGETS FILE IF THE USER HAS CHOSEN TO USE ONE
if targets = 4
	Read Table from tab-separated file... 'targets_file$'
	targets$ = selected$ ("Table", 1)
endif

# MAKE A LIST OF ALL SOUNDFILES IN THE FOLDER
Create Strings as file list... list 'soundfile_directory$'*.wav
files = Get number of strings

# LOOP THROUGH THE LIST OF FILES...
for file from 1 to files

	# READ IN THE SOUNDFILE AND FIND DURATION
	select Strings list
	filename$ = Get string... file
	Open long sound file... 'soundfile_directory$''filename$'
	soundfile$ = selected$ ("LongSound", 1)
	total_duration = Get total duration

	# INCREMENT FILE COUNT AND LOG
	file_count = file_count + 1
	files_read$ = "'files_read$'" + "'soundfile$', "

	# RESET FLAGS
	progress_file_present = 0
	corrected_file_present = 0
	new_file = 1

	# CHECK FOR PROGRESS FILE AND PREVIOUSLY CORRECTED TEXTGRID
	progress_file$ = "'soundfile_directory$''soundfile$'-progress"
	corrected_file$ = "'textgrid_directory$''soundfile$'-corrected.TextGrid"
	report_file$ = "'soundfile_directory$''soundfile$'-report.txt"
	if fileReadable (progress_file$)
		Read Matrix from raw text file... 'progress_file$'
		continue = 1
		progress_file_present = 1
	endif
	if fileReadable (corrected_file$)
		gridfile$ = "'corrected_file$'"
		gridname$ = "'soundfile$'-corrected"
		corrected_file_present = 1
		if progress_file_present = 0
			select Strings list
			plus LongSound 'soundfile$'
			if targets = 4
				plus Table 'targets$'
			endif
			if progress_file_present = 1
				plus Matrix 'soundfile$'-progress
			endif
			Remove
			exit Warning, a corrected TextGrid exists but there is no corresponding progress file. If the file has already been corrected, remove it from the directory, otherwise restore the progress file associated with it.
		endif
	else
		gridfile$ = "'textgrid_directory$''soundfile$'.TextGrid"
		gridname$ = "'soundfile$'"
	endif

	# OPEN THE CORRESPONDING TEXTGRID
	Read from file... 'gridfile$'

	# PERFORM INITIAL OPERATIONS ON TEXTGRID
	select TextGrid 'gridname$'
	call GetTier 'phone_tier$' phone_tier
	if phone_tier = -1
		exit The tier 'phone_tier$' is missing from 'soundfile$'.TextGrid!
	endif
	call GetTier 'word_tier$' word_tier
	if word_tier = -1
		exit The tier 'word_tier$' is missing from 'soundfile$'.TextGrid!
	endif
	if create_notes_tier = 1
		call GetTier notes notes_tier
		if notes_tier = -1
			Insert interval tier... (tiers+1) notes
		endif
	endif

	# LOOP THROUGH INTERVALS
	interval_count = Get number of intervals... phone_tier
	for interval to interval_count

		# GET NUMBER OF INTERVALS AGAIN IN CASE IT HAS CHANGED
		select TextGrid 'gridname$'
		interval_count = Get number of intervals... phone_tier
		
		# CHECK IF CONTINUING
		if continue = 1
			select Matrix 'soundfile$'-progress
			interval = Get value in cell... 1 1
			continue = 0
		endif

		# GET PHONE LABEL
		select TextGrid 'gridname$'
		phone_label$ = Get label of interval... phone_tier interval

		# GET WORD LABEL
		vowelstart = Get starting point... phone_tier interval
		vowelend = Get end point... phone_tier interval
		midpoint = (vowelstart+vowelend)/2
		word = Get interval at time... word_tier midpoint
		word_label$ = Get label of interval... word_tier word

		# GET PRECEDING PHONE LABELS
		if interval > 1
			preceding_time = Get starting point... phone_tier (interval-1)
			preceding_int = Get interval at time... word_tier preceding_time
			preceding_word$ = Get label of interval... word_tier preceding_int
			if preceding_word$ <> word_label$
				preceding_label$ = ""
			else
				preceding_label$ = Get label of interval... phone_tier (interval-1)
				if preceding_label$ = "sp" or preceding_label$ = "sil"
					preceding_label$ = ""
				endif
			endif
			if interval > 2
				prepreceding_time = Get starting point... phone_tier (interval-2)
				prepreceding_int = Get interval at time... word_tier prepreceding_time
				prepreceding_word$ = Get label of interval... word_tier prepreceding_int
				if prepreceding_word$ <> word_label$
					prepreceding_label$ = ""
				else
					prepreceding_label$ = Get label of interval... phone_tier (interval-2)
					if prepreceding_label$ = "sp" or prepreceding_label$ = "sil"
						prepreceding_label$ = ""
					endif
				endif
			else
				prepreceding_label$ = ""
			endif
		else
			preceding_label$ = ""
		endif

		# GET FOLLOWING PHONE LABEL
		if interval+1 <= interval_count
			following_time = Get starting point... phone_tier (interval+1)
			following_int = Get interval at time... word_tier following_time
			following_word$ = Get label of interval... word_tier following_int
			if following_word$ <> word_label$
				following_label$ = ""
			else
				following_label$ = Get label of interval... phone_tier (interval+1)
				if following_label$ = "sp" or following_label$ = "sil"
					following_label$ = ""
				endif
			endif
		else
			following_label$ = ""
		endif

		# CHECK FOR THE TARGET
		word_label$ = replace_regex$ (word_label$, "[A-Z]", "\L&", 0)

		# *****INSERT CHOICE OF PHONE/WORD HERE, FOLLOWING THE EXAMPLE HERE*****
		if targets = 1
			if phone_label$ = "AE1" or phone_label$ = "AE2" or phone_label$ = "EH1" or phone_label$ = "EH2" or phone_label$ = "EY1" or phone_label$ = "EY2"
				if following_label$ = "B" or following_label$ = "D" or following_label$ = "G" or following_label$ = "V" or following_label$ = "DH" or following_label$ = "Z" or following_label$ = "ZH" or following_label$ = "JH" or following_label$ = ""
					if skip_frame_sentence = 1
						if word_label$ = "write" or word_label$ = "today"
						else
							call Correct
						endif
					else
						call Correct
					endif
				endif
			endif

		# *****INSERT CHOICE OF PHONE/WORD HERE, FOLLOWING THE EXAMPLE HERE*****
		elsif targets = 2
			if phone_label$ = "AE1" or phone_label$ = "AE2" or phone_label$ = "EH1" or phone_label$ = "EH2"
				if following_label$ = "B" or following_label$ = "D" or following_label$ = "V" or following_label$ = "DH" or following_label$ = "Z" or following_label$ = "ZH" or following_label$ = "JH" or following_label$ = ""
					call Correct
				elsif following_label$ = "G"
					if preceding_label$ = "P" or preceding_label$ = "T" or preceding_label$ = "K"
						if prepreceding_label$ = ""
							call Correct
						endif
					endif
				endif
			elsif phone_label$ = "EY1" or phone_label$ = "EY2"
				if preceding_label$ = "P" or preceding_label$ = "T" or preceding_label$ = "K"
					if prepreceding_label$ = ""
						if following_label$ = "B" or following_label$ = "D" or following_label$ = "G" or following_label$ = "V" or following_label$ = "DH" or following_label$ = "Z" or following_label$ = "ZH" or following_label$ = "JH" or following_label$ = ""
							call Correct
						endif
					endif
				endif
			endif

		# *****INSERT CHOICE OF PHONE/WORD HERE, FOLLOWING THE EXAMPLE HERE*****
		elsif targets = 3
			if phone_label$ = "AE1" or phone_label$ = "AE2" or phone_label$ = "EH1" or phone_label$ = "EH2" or phone_label$ = "EY1" or phone_label$ = "EY2"
				if preceding_label$ = "P" or preceding_label$ = "T" or preceding_label$ = "K"
					if prepreceding_label$ = ""
						if following_label$ = "B" or following_label$ = "D" or following_label$ = "G" or following_label$ = "V" or following_label$ = "DH" or following_label$ = "Z" or following_label$ = "ZH" or following_label$ = "JH" or following_label$ = ""
							call Correct
						endif
					endif
				endif
			endif

		# TARGETS FILE IS INTENDED FOR USE WITH VOWELS, CHANGE THESE IF INTERESTED IN CONSONANTS
		elsif targets = 4
			if phone_label$ = "AO1" or phone_label$ = "AA1" or phone_label$ = "IY1" or phone_label$ = "UW1" or phone_label$ = "EH1" or phone_label$ = "IH1" or phone_label$ = "UH1" or phone_label$ = "AH1" or phone_label$ = "AX1" or phone_label$ = "AE1" or phone_label$ = "EY1" or phone_label$ = "AY1" or phone_label$ = "OW1" or phone_label$ = "AW1" or phone_label$ = "OY1" or phone_label$ = "ER1" or phone_label$ = "AXR1" or phone_label$ = "AO2" or phone_label$ = "AA2" or phone_label$ = "IY2" or phone_label$ = "UW2" or phone_label$ = "EH2" or phone_label$ = "IH2" or phone_label$ = "UH2" or phone_label$ = "AH2" or phone_label$ = "AX2" or phone_label$ = "AE2" or phone_label$ = "EY2" or phone_label$ = "AY2" or phone_label$ = "OW2" or phone_label$ = "AW2" or phone_label$ = "OY2" or phone_label$ = "ER2" or phone_label$ = "AXR2"
				select Table 'targets$'
				match = Search column... word 'word_label$'
				if match
					call Correct
				endif
			endif
		endif
	endfor

	# GENERATE FILE REPORT, REMOVE ALL OBJECTS FOR THAT FILE AND GO ON TO THE NEXT ONE
	call GenerateReport
	if fileReadable (progress_file$)
		filedelete 'progress_file$'
	endif
	select LongSound 'soundfile$'
	plus TextGrid 'gridname$'
	if progress_file_present = 1
		plus Matrix 'soundfile$'-progress
	endif
	Remove
	select Strings list
endfor

# REMOVE REMAINING OBJECTS AND PRINT REPORT
select Strings list
if targets = 4
	plus Table 'targets$'
endif
Remove
clearinfo
files_read$ = replace_regex$ (files_read$, ", $", ".", 0)
printline Done. Read 'file_count' file(s): 'files_read$'

# PROCEDURE TO SHOW EVALUATION WINDOW AND TAKE INPUT
procedure Correct

	# PREVENT ZOOM DURATION FROM EXTENDING BEYOND THE ENDS OF THE FILE BUT MAINTAIN DESIRED WINDOW SIZE
	if not zoom_duration = 0
		left_edge = midpoint - zoom_duration/2
		right_edge = midpoint + zoom_duration/2
		right_excess = right_edge - total_duration

		if left_edge < 0
			zoom_start = 0
			if zoom_duration > total_duration
				zoom_end = total_duration
			else
				zoom_end = zoom_duration
			endif
		elsif right_edge > total_duration
			zoom_end = total_duration
			if left_edge > right_excess
				zoom_start = zoom_end - zoom_duration
			else
				zoom_start = 0
			endif
		else
			zoom_start = left_edge
			zoom_end = right_edge
		endif
	else
		zoom_start = 0
		zoom_end = total_duration
	endif

	# CHECK IF FIRST INTERVAL, IF SO SET ALL SETTINGS AND SHOW EDITOR WINDOW
	if new_file = 1
		select LongSound 'soundfile$'
		plus TextGrid 'gridname$'
		View & Edit
		editor TextGrid 'gridname$'
			Show analyses... yes yes yes yes no 10
			Spectrogram settings... 0.0 5000.0 0.005 70.0
			Zoom... zoom_start zoom_end
			Move cursor to... midpoint
		endeditor
	else
		editor TextGrid 'gridname$'
			Zoom... zoom_start zoom_end
			Move cursor to... midpoint
		endeditor
	endif
	new_file = 0

	# SHOW THE ANALYSIS WINDOW
	beginPause ("Correct Boundaries")
		comment ("File: 'soundfile$' (#'file_count' of 'files')")
		comment ("Correct the vowel boundaries and click 'next' when finished.")
	clicked = endPause ("Next", "Skip", "Stop", 1, 3)

	# IF THE USER CLICKS "NEXT", LOG IT AND SAVE THE TEXTGRID
	if clicked = 1
		token_count = token_count + 1
		corrected_tokens$ = "'corrected_tokens$'" + "'word_label$', "
		editor TextGrid 'gridname$'
			Save TextGrid as text file... 'textgrid_directory$''soundfile$'-corrected.TextGrid
		endeditor

	# IF THE USER CLICKS "SKIP", LOG IT AND GO TO THE NEXT INTERVAL
	elsif clicked = 2
		skipped_count = skipped_count + 1
		skipped_tokens$ = "'skipped_tokens$'" + "'word_label$', "

	# IF THE USER CLICKS "STOP", GENERATE REPORT AND PROGRESS FILE, CLEAR WINDOW AND REMOVE OBJECTS
	elsif clicked = 3
		if token_count > 0 or skipped_count > 0
			if fileReadable (progress_file$)
				filedelete 'progress_file$'
			endif
			fileappend "'progress_file$'" 'interval'
			call GenerateReport
		endif
		select Strings list
		plus LongSound 'soundfile$'
		plus TextGrid 'gridname$'
		if targets = 4
			plus Table 'targets$'
		endif
		if progress_file_present = 1
			plus Matrix 'soundfile$'-progress
		endif
		Remove
		clearinfo
		files_read$ = replace_regex$ (files_read$, ", $", ".", 0)
		printline Done. Read 'file_count' file(s): 'files_read$'
		exit
	endif
endproc

# PROCEDURE TO FIND THE NUMBER OF A TIER WITH A GIVEN LABEL
procedure GetTier name$ variable$
	tiers = Get number of tiers
	itier = 1
	repeat
		tier$ = Get tier name... itier
		itier = itier + 1
	until tier$ = name$ or itier > tiers
	if tier$ <> name$
		'variable$' = 0
	else
		'variable$' = itier - 1
	endif
	if 'variable$' = 0
		'variable$' = -1
	endif
endproc

# PROCEDURE TO GENERATE REPORTS FOR EACH FILE CORRECTED
procedure GenerateReport
	# GET TIME/DATE AND FORMAT LISTS
	rundate$ = date$ ()
	corrected_tokens$ = replace_regex$ (corrected_tokens$, ", $", ".", 0)
	skipped_tokens$ = replace_regex$ (skipped_tokens$, ", $", ".", 0)

	# APPEND REPORTS TO FILE
	fileappend "'report_file$'" 'rundate$''newline$'Corrected 'token_count' token(s): 'corrected_tokens$''newline$'Skipped 'skipped_count' token(s): 'skipped_tokens$''newline$''newline$'

	# CLEAR COUNTS AND LISTS FOR NEXT FILE
	token_count = 0
	skipped_count = 0
	corrected_tokens$ = ""
	skipped_tokens$ = ""
endproc
