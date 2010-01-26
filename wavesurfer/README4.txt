WaveSurfer supports multi-lingual user interfaces through the use
of the msgcat Tcl package. The msgs directory contains the localization
files containing text strings used in WaveSurfer.
The current locale decides which .msg-file should be used in the
application. The locale is set using the environment variable LANG.
It is also possible to hard code this in surfutil.tcl, line 15
WaveSurfer defaults to English for undefined messages.

It is also possible to put .msg-files in the directory ~/.wavesurfer/<MAJORVERSION>/msgs/

Another option is to create a plug-in out of the .msg file.

If the locale is xxx create a file "xxx.plug" containing this code

namespace eval ::util {
::msgcat::mclocale xxx

# code from xxx.msg here #

} 


Please send us .msg-files you've created for inclusion in the source distribution.

Note that the encoding features are not currently supported by the
pre-compiled binary releases in order to keep the executables small.
