#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.4.1
 Author:         Sven Neuhaus <sven-theta AT sven DOT de>

 Script Function:
	Ricoh Theta 360° image batch processing
	Copy to directory with images taken by a Ricoh Theta and run it.
	It will generate auto-rotated images with XMP metadata.

    Will not work properly if there are more than 9999 files that have
	already	been processed in the current directory.

 Configuration:
 	Before running this script, please configure the three sections in 
	the 'Config Section' below.

#ce ----------------------------------------------------------------------------

; Config Section ---------------------------------------------------------------

; Configure App Path:
;   Alter the value of $theta_exe to match the path on your system.
;   If you don't know the path then right click on the icon, and
;   look at the Target value under the Shortcut tab.
;
;Local $theta_exe = "C:\Users\you\AppData\Local\Programs\RicohTheta\RICOH THETA.exe"
Local $theta_exe = "C:\Program Files (x86)\RICOH THETA\RICOH THETA.exe"


; Configure Language:
;   Change the title values if you use a Locale other than German
;
Local $theta_title = "RICOH THETA"
Local $theta_save_title = "JPEG-Daten mit XMP"
; For English US locale, use the following instead:
;Local $theta_title = "RICOH THETA"
;Local $theta_save_title = "JPEG data with XMP"

; Configure Navigation Method:
;   Select and configure the navigation method to match your version of
;   the Ricoh Theta App.
; 
;   Unfortunately only older versions of the app provide menu shortcuts 
;   for the conversion operations, hence '$navigationMethod' defaulting 
;   to 2 (cursor based).
;   Leave this as is unless you are using an old version with shortcut access.
;
Local $navigationMethod = 2

; method 1: (old) shortcut navigation method configuration
;   if using this navigation method, please configure the menu shortcuts to
;   match your locale (german default).
;   if not using this method then you can leave as is.
; German shortcuts;
Local $shortcut_file_menu = "!D"
Local $shortcut_write_with_up_down = "m"
Local $shortcut_write_xmp = "j"
; For English US locale, use the following instead:
; Local $shortcut_file_menu = "!F"
; Local $shortcut_write_with_up_down = "w"
; Local $shortcut_write_xmp = "j"

; method 2: (new) cursor based navigation method configuration
;   if using this method then then you may need to tweak the following
;   options depending on your system. The basic idea is that the script
;   simulates a mouse click to get to the file menu, then used the
;   cursor keys to get to the desired menu. Not ideal, but...
;   
Local $fileMenuClickOffsetX=20
Local $fileMenuClickOffsetY=40
Local $downPressesToWriteMenu=4
Local $rightPressesToJpgXmpMenu=2

; ------------------------------------------------------------------------------


; No user serviceable parts below ----------------------------------------------

#include <File.au3>

Local $windowTimeout = 20
Local $doneFileExtensions[2] = ["_xmp.JPG", "_xmp_e.jpg"]
Local $donefiles[9999] ; it's over 9000!
$donefiles = preprocessed_images()

; Now we go through all images (*.JPG) in the directory
Local $search_handle = FileFindFirstFile("*.JPG")
If $search_handle = -1 Then
    MsgBox($MB_SYSTEMMODAL, "", "Error: No .JPG files in current directory.")
EndIf

AutoItSetOption ("PixelCoordMode", 0)  ;relative to Window

Local $done = 0
Do
	Do
		$image_file = FileFindNextFile($search_handle)
		
		If @error Then
			$done = 1
			ExitLoop
		EndIf

		Local $isDoneFile = False
		For $i = 0 to UBound($doneFileExtensions)-1
			If StringInStr($image_file, $doneFileExtensions[$i]) <> 0 Then
			    $isDoneFile = True
			Endif
		Next
	Until $isDoneFile = False


	If ($done = 1) Then
		ExitLoop
	EndIf

	; check for file in list of already completed images ($donefiles)
	Local $dfile
	For $dfile In $donefiles
		Local $skip = 0
		if (StringInStr($image_file, $dfile) = 1) Then
			ConsoleWrite("skipping '" & $image_file & "' (_xmp file already present)" & @CRLF)
			$skip = 1;
			ExitLoop
		EndIf
	Next

	if ($skip <> 1) Then
		xmp_image($image_file)
	EndIf

Until $done = 1

FileClose($search_handle)
MsgBox($MB_APPLMODAL, "", "The autoit script is finished.")


; get a list of all already processed images (e.g. *_xmp.JPG)
Func preprocessed_images ()
	Local $image_file
	Local $donefiles[9999] ;"WHAT?! NINE THOUSAND?!"
	Local $di = 0

	For $i = 0 to UBound($doneFileExtensions)-1
		Local $currentExt = $doneFileExtensions[$i]
		Local $search_handle = FileFindFirstFile( "*" & $currentExt)
		If $search_handle <> -1 Then
			Do
				$image_file = FileFindNextFile($search_handle)
				If @Error Then
					ExitLoop
				EndIf
				; remember the filename but without the done suffix
				$donefiles[$di] = StringLeft($image_file, StringInStr( $image_file, $currentExt)-1)
				$di = $di + 1
			Until @error
			FileClose($search_handle)
		EndIf
	Next
	Return $donefiles
EndFunc


; open file with theta app then save it with xmp data
Func xmp_image($image_file)
	; open program with image as parameter
	Local $pid = Run($theta_exe & ' "' & @WorkingDir & '\' & $image_file & '"')
	if $pid = 0 then
		report_failure( "Error: Unable to find " & $theta_exe )
	endif
	Local $winHdl = WinWaitActive($theta_title, "",$windowTimeout)
	if $winHdl = 0 Then
		report_failure( "Timed out while trying to find Theta App window" )
	Endif
	; after loading the image, the window title changes
	$winHdl = WinWaitActive($image_file & " - " & $theta_title, "", $windowTimeout)
	if $winHdl = 0 Then
		report_failure( "Timed out while trying to find Theta App file loaded window" )
	Endif

	; image loading done.

	; Save the file with XMP data and rotation correction

	if $navigationMethod = 1 then

		; (old) shortcut method

		;	WinMenuSelectItem($image_file & " - " & $theta_title, "", "&Datei", "&Mit oben/unten schreiben", "&JPEG-Daten mit XMP")
		; File Menu ("Datei")
		Send($shortcut_file_menu)
		; Submenu "Mit oben/unten schreiben"
		Send($shortcut_write_with_up_down)
		; Menuentry "JPEG-Daten mit XMP"
		Send($shortcut_write_xmp)
	else
		; (new) cursor method

		; Open menu with mouse
		Opt("MouseCoordMode", 0) ; coords relative to active window
		MouseClick("left", $fileMenuClickOffsetX, $fileMenuClickOffsetY, 1, 1 )
		Sleep(250) 	; note: a low sleep here can trip up the menu navigation

		For $i = 1 To $downPressesToWriteMenu
			Send("{Down}")
			Sleep(10)
		Next

		For $i = 1 To $rightPressesToJpgXmpMenu
			Send("{Right}")
			Sleep(10)
		Next

		Send("{Enter}")
		Sleep(10)
	endif

	; wait for "save file" dialog to open
	$winHdl = WinWaitActive($theta_save_title, "", $windowTimeout)
	if $winHdl = 0 then
		report_failure( "TImeout while waiting for the file save window" )
	endif
	Send("{ENTER}")

	; Wait until the file has been written
	wait_until_ready($image_file)

	WinClose($image_file & " - " & $theta_title)
EndFunc

;
;
Func report_failure($msg)
    MsgBox($MB_SYSTEMMODAL, "", $msg)
	Exit(1)
EndFunc
 
; This function waits until the program has finished saving the image
; I've noticed the app may save as _xmp_e.jpg too..
Func wait_until_ready($image_file)
	Local $seenDoneFile = False

	While $seenDoneFile = False
	
		For $i = 0 to UBound($doneFileExtensions)-1
			Local $nameToCheck = StringLeft($image_file, StringInStr( $image_file, ".JPG")-1) & $doneFileExtensions[$i]
			If FileExists($nameToCheck) = 1 Then
				$seenDoneFile = True
			Endif
		Next

		If $seenDoneFile = False Then
			Sleep(100)
		Endif
	WEnd

#comments-start
	Local $handle = WinGetHandle($image_file & " - " & $theta_title)
	; check if menu is enabled (doesn't work)
	;ControlCommand($hWin, "", "[NAME:button2]", "IsEnabled", "")
    $pixelx = 473; // was 914
	$pixely = 735; // was 930
	; the "+" button will be grayed out, then it will turn white again
	$color = PixelGetColor($pixelx, $pixely, $handle )
	While $color = 0xFFFFFF
		Sleep(50)
		$color = PixelGetColor($pixelx, $pixely, $handle )
		; TODO: if computer is too fast it may have been grey before we saw it... XXX
	WEnd

	ConsoleWrite(" pixel is no longer white" & @CRLF)
	$color = PixelGetColor($pixelx, $pixely, $handle)
	While $color <> 0xFFFFFF
		Sleep(100)
		$color = PixelGetColor($pixelx, $pixely, $handle)
	WEnd

	ConsoleWrite(" pixel is white again, writing has finished." & @CRLF)
#comments-end

EndFunc

;eof. This file has not been truncate
