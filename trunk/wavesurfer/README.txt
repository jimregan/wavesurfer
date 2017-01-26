
WaveSurfer 1.8.8 - October 2010
-------------------------------

changes since last version:

+ drag-and-drop support! (osx and windows)
+ scroll wheel support re-added and improved (mysteriously missing in 1.8.7)
+ mac osx 10.5 crash (bug 3078589) fixed
+ mac osx yellow-spectrograms bug fixed (new snack binary)
+ re-added license info file (LICENSE.txt) (bug 3079342)
+ new startup option --show-console (useful for tracking startup problems in wrapped apps)
+ default configuration can now be set from within the choose-configuration dialogue
+ GUI tidying-up - more tile widgets, removed several hard-wired color specifications
+ modified snack::getOpenFile to allow for raw files on all platforms (fixing bug 3082068)



patchlevel 2 (2010-12-06):
+ applied Mac OSX menu-patch (3087446)
+ fixed Windows 7 bug (3111969)
+ fixed osx transcription bug (3115693)

patchlevel 3 (2011-01-30):
+ fixed bug 3136110 (close dialogue for empty sound)
+ fixed window resize-issue on OSX

patchlevel 4 (2011-12-30):
+ fixed bugs 3297829 (waveform scaling),3181986 (config dialog error)
+ applied patch 3466895 (selection edit error)

patchlevel 5 (2016-11-23, +update 2017-01-25):
+ fixed Mac OS X 10.12 (Sierra) compatibility issue + new Tcl 8.6.6 runtime)
+ fixed "namespace inscope"-bug for properties and preferences dialogs
+ new Linux Tcl 8.6.6 runtime (better compatibility with new Ubuntu releases)
