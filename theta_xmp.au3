#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.4.1
 Author:         Sven Neuhaus <sven-theta AT sven DOT de>

 Script Function:
	Ricoh Theta 360° image batch processing
	Copy to directory with images taken by a Ricoh Theta and run it.
	It will generate auto-rotated images with XMP metadata.

    Will not work properly if there are more than 9999 files that have
	already	been processed in the current directory.

#ce ----------------------------------------------------------------------------

; Config Section ---------------------------------------------------------------
;Local $theta_exe = @ProgramFilesDir & "\RICOH THETA\RICOH THETA.exe"
Local $theta_exe = "F:\Program Files (x86)\RICOH THETA\RICOH THETA.exe"
; Change these if you use a Locale other than German
Local $theta_title = "RICOH THETA"
Local $theta_save_title = "JPEG-Daten mit XMP"

Local $shortcut_file_menu = "!D"
Local $shortcut_write_with_up_down = "m"
Local $shortcut_write_xmp = "j"
; No user serviceable parts below ----------------------------------------------

#include <File.au3>
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
	Until Not(StringInStr($image_file, "_xmp.JPG"))

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


; get a list of all already processed images (*_xmp.JPG)
Func preprocessed_images ()
	Local $image_file
	Local $donefiles[9999] ;"WHAT?! NINE THOUSAND?!"
	Local $di = 0
	Local $search_handle = FileFindFirstFile("*_xmp.JPG")
	If $search_handle <> -1 Then
		Do
			$image_file = FileFindNextFile($search_handle)
			If @Error Then
				ExitLoop
			EndIf
			; remember the filename but without the "_xmp.JPG" suffix
			$donefiles[$di] = StringLeft($image_file, StringInStr( $image_file, "_xmp.JPG")-1)
			$di = $di + 1
		Until @error
		FileClose($search_handle)
	EndIf
	Return $donefiles
EndFunc


; open file with theta app then save it with xmp data
Func xmp_image($image_file)
	; open program with image as parameter
	Run($theta_exe & ' "' & @WorkingDir & '\' & $image_file & '"')
	WinWaitActive($theta_title)
	; after loading the image, the window title changes
	WinWaitActive($image_file & " - " & $theta_title)
	; image loading done.

	; Save the file with XMP data and rotation correction

;	WinMenuSelectItem($image_file & " - " & $theta_title, "", "&Datei", "&Mit oben/unten schreiben", "&JPEG-Daten mit XMP")
	; File Menu ("Datei")
	Send($shortcut_file_menu)
	; Submenu "Mit oben/unten schreiben"
	Send($shortcut_write_with_up_down)
	; Menuentry "JPEG-Daten mit XMP"
	Send($shortcut_write_xmp)
	; wait for "save file" dialog to open
	WinWaitActive($theta_save_title)
	Send("{ENTER}")

	; Wait until the file has been written
	wait_until_ready($image_file)

	WinClose($image_file & " - " & $theta_title)
EndFunc


; This function waits until the program has finished saving the image
Func wait_until_ready($image_file)
	$xmp_file = StringLeft($image_file, StringInStr( $image_file, ".JPG")-1) & "_xmp.JPG"

	While (Not FileExists($xmp_file))
		Sleep(50)
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
