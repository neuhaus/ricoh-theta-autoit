ricoh-theta-autoit
==================

[AutoIt 3.x](https://www.autoitscript.com/site/autoit/) script for batch processing using the [Ricoh Theta for Windows](https://theta360.com/de/support/download/) GUI application. The app can auto-level the panoramic images and add the missing XMP metadata, but it only processes one image at a time by itself.

New maintainer
--------------

The script was originally written by Sven Neuhaus. Ian Felstead is the current maintainer.

After downloading, change the path and the language strings in the script `theta_xmp.au3`, then 
copy it into the directory with your 360° panoramic images 
copied from the Ricoh Theta camera. Launch it (usually by double clicking) and
it will scan the directory and - for every JPG image that does not yet have an 
accompanying _xmp.jpg file - generate it using the *Ricoh Theta for Windows* 
application.

The generated files will be **auto-levelled** and contain the **XMP metadata** necessary to
turn the images into photospheres and/or use them with [Mapillary](http://blog.mapillary.com/update/2014/09/10/support-for-pano.html).

Refer to the [Wiki](https://github.com/neuhaus/ricoh-theta-autoit/wiki) for
download links.

Take great pictures and have fun!<br>

