ricoh-theta-autoit
==================

AutoIt 3.x Script for batch conversion using the Ricoh Theta for Windows GUI Application

Copy the script theta_xmp.au3 into the directory with the 360° panoramic images 
copied from the Ricoh Theta camera, then launch it (usually by double clicking).
It will scan the directory and for every JPG image that does not yet have an 
accompanying _xmp.jpg file generate it using the Ricoh Theta for Windows 
application.

The generated file is auto-levelled and contains the XMP metadata necessary to
turn the image into a photosphere.
