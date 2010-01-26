WaveSurfer

Copyright (C) 2000-2005
Jonas Beskow	beskow@speech.kth.se
Kare Sjolander	kare@speech.kth.se

There are several anti-spam methods between us and anybody trying to contact
us by e-mail. If you don't hear anything try to send a new message

This file only contains information on how to install and run WaveSurfer from
the source distrubution.
Please refer to the WaveSurfer web site, http://www.speech.kth.se/wavesurfer/,
for more information on the package itself.
Questions, feature requests and bug reports should be directed to the 
WaveSurfer user forum at the same web site.


Packages needed
-------------------------------------------------------------------
In order to use this release of WaveSurfer you will need to have the following
packages installed

Tcl and Tk version 8.4 or later, download at http://tcl.activestate.com/

Mac OS X users can download Tcl/Tk at http://tcltkaqua.sourceforge.net/


Snack version <SNACKMAJORV> or later, download at http://www.speech.kth.se/snack/

If the Tile package (http://tktable.sourceforge.net/tile/) is available
WaveSurfer will use it to provide an improved GUI, this package is contained
in the WaveSurfer binaries and is also part of the ActiveState distributions and
the Mac distribution.

The binary versions of WaveSurfer currently use Tcl/Tk8.4.4 on Windows/Linux 
and Tcl/Tk8.4.9 on the Mac.


Running WaveSurfer
-------------------------------------------------------------------
Once you have installed both of the above and made sure they work, change
directory to wavesurfer-<VERSION>/ and type

./wavesurfer.tcl


Problems
-------------------------------------------------------------------
If you get a complaint about Tcl not finding the Snack package, you probably 
did not install it in a place where Tcl can find it. See the Snack
installation instructions on how to set the TCLLIBPATH environment variable.

Unix only: WaveSurfer uses Tcl/Tk version 8.4 as default. If you have another
version, modify "exec wish8.4" at the top of the file wavesurfer.tcl.


System wide installation
-------------------------------------------------------------------
Simply copy the directory wsurf1.8 and its contents to the location where
Tcl looks for packages.

If you don't know where to put it, start tclsh and type

puts $auto_path

to get a list of possible installation directories (e.g. /usr/local/lib/).

If you have configurations or plug-ins that are to be used by many users,
you can put these in a common directory and use the environment variables
WSCONFIGDIR abd WSPLUGINDIR to point to these.


Localization support
-------------------------------------------------------------------
See the msgs/ directory for more information.


Example code
-------------------------------------------------------------------
Examples on WaveSurfer plug-ins can be found in plugins/
Example applications that use wsurf widgets can be found in demos/
Also included is a Python package which allows Python applications to
use wsurf widgets.


Debugging WaveSurfer
-------------------------------------------------------------------
Rename the file _proctrace.tcl to proctrace.tcl. This will add an
additional Debug-menu to WaveSurfer useful for procedure tracing.
See the file _proctrace.tcl for further instructions.


Acknowledgements
-------------------------------------------------------------------
The following people have contributed code, suggestions, and/or other help.

Francesco Cutugno
Massimo Petrillo 
Alastair Burt
Petur Helgason
Stefan Breuer
Marjorie Chan
Martyn Clark
Vitaly Repin
Alex Acero
Mark D. Anderson
Uwe Koloska
Toshio Hirai
Kazuaki Maeda
Giampiero Salvi
Johan Sundberg
Erhard Rank
Alain Bertrand
Kevin Ernste
Santiago Fernandez
Geoff Williams
Valery Petrushin
Khaldoun Shobaki
Peter Yue
Johan Wouters
Mattias Heldner
Erik Pihl
Daniel Elenius
Johan Dahl
Vincent Pagel
Geoffrey Wilfart
Tiago Tresoldi
