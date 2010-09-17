Included Python examples

wsapp1.py is a minimal example on how to build a Python application
using the wsurf widget.

wsplugapp.py is a minimal example of a Python application using the
wsurf widget and wsurf plugins written in Python.



Make sure that both the wsurf and Snack packages can be found by Python
and Tkinter.
On Unix this is done by setting the environment variable TCLLIBPATH.
setenv TCLLIBPATH "/tmp/wavesurfer-<VERSION> /tmp/snack<SNACKMAJORV>/unix"

Windows/Mac users should install the wsurf package in the same way the
Snack package is to be installed on their system.

Now do
cd demos/
python wsapp1.py



Installing the wsurf package

It might be practical to install the wsurf package on your system in
order to develop and use custom applications like these.
Simply copy the wsurf<MAJORVERSION> directory to the directory containing
the snack<SNACKMAJORV> library directory (assuming you have installed Snack <SNACKMAJORV>
according to the installation instructions included with that package).
Something like:
     /usr/local/lib/snack<SNACKMAJORV>/
     /usr/local/lib/wsurf<MAJORVERSION>/
Properly installing wsurf in this manner will make the code line that
sets "auto_path", in the examples, superfluous.
