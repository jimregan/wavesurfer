Included Tcl/Tk examples

wsapp1.tcl is a minimal example on how to build an application
using the wsurf widget.

wsapp2.tcl extends the previous example with code that makes the wsurf
widget link to a sound file instead of loading it into memory. Useful
for large sound files.

wsapp3.tcl shows how to create a wsurf widget with a couple of panes.
The code for adding these panes has been copied from a configuration file.

wsapp4.tcl is a slightly larger example that creates a wsurf widget and a 
listbox where the user can browse files and segments. These can be loaded
from a text file containing lines with the format
"filename start-in-seconds end-in-seconds".

wsapp5.tcl shows how to create a wsurf widget and add an empty pane to it.
This can be used to draw custom graphics.

wsapp6.tcl shows how to do ganging, i.e., how to create links between widgets.
All zoom/scroll/selection operations on one widget will be reflected by
the other widget.

wsapp7.tcl is tool that can load two versions of a sound file and allow
the user to switch between the sounds during playback.

wsapp8.tcl is an extension of wsapp5.tcl that shows how to track
cursor-movement, selection and scroll operations.

embed.tcl is a minimal example on how a custom application
can pop-up a WaveSurfer-window.

speecon.tcl is a tool used to verify and correct the Swedish part of
the SPEECON database.



Installing the wsurf package

It might be practical to install the wsurf package on your system in
order to develop and use custom applications like these.
Simply copy the wsurf@MAJORVERSION@ directory to the directory containing
the snack@SNACKMAJORV@ library directory (assuming you have installed Snack @SNACKMAJORV@
according to the installation instructions included with that package).
Something like:
     /usr/local/lib/snack@SNACKMAJORV@/
     /usr/local/lib/wsurf@MAJORVERSION@/
Properly installing wsurf in this manner will make the code line that
sets "auto_path", in the examples, superfluous.
