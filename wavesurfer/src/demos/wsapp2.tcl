#!/bin/sh
# the next line restarts using wish \
exec wish8.4 "$0" "$@"

catch {package require Tk}

# Minimal example of a custom application using the wsurf widget.
#
# This example shows how to make the wsurf widget link to a file
# on disk instead of loading all sound data into memory.
# The first time a sound file is accessed a .shape file is created
# which contains coarse waveform information. This make accessing this
# file much faster in the future.


# Search for wsurf package one level above this script's directory
# This is for easy testing purposes when wsurf has not been installed

set auto_path [concat [file join [file dirname [info script]] ..] $auto_path]

package require -exact wsurf 1.8



# Initialize wsurf package (this will set default preferences)

::wsurf::Initialize

# Link to disk file

wsurf::SetPreference linkFile 1


# Create and pack one wsurf widget

set w [wsurf .ws -collapser 0 -progressproc snack::progressCallback]

pack $w -expand 0 -fill both



# Prompt the user for a sound file and open it

$w openFile [snack::getOpenFile]
