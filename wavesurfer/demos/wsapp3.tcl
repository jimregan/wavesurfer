#!/bin/sh
# the next line restarts using wish \
exec wish8.4 "$0" "$@"

catch {package require Tk}

# Minimal example of a custom application using the wsurf widget.
#
# This example shows how to create a wsurf widget and how to add one
# waveform pane and a time axis pane.


# Search for wsurf package one level above this script's directory
# This is for easy testing purposes when wsurf has not been installed

set auto_path [concat [file join [file dirname [info script]] ..] $auto_path]

package require -exact wsurf 1.8



# Initialize wsurf package (this will set default preferences)

::wsurf::Initialize

# Make widget scroll during playback

wsurf::SetPreference autoScroll Page



# Create and pack one wsurf widget

set widget [wsurf .ws -collapser 0 -icons [list beg play playloop pause stop record zoomin zoomout]]

pack $widget -expand 0 -fill both



# Add a couple of panes and some content from the standard plug-ins
# These lines have been copied from the standard Waveform configuration,
# ../wsurf1.8/configurations/Waveform.conf

set pane [$widget addPane -maxheight 2048  -minheight 10]
$widget analysis::addWaveform $pane

set pane [$widget addPane -maxheight 20  -minheight 20]
$widget timeaxis::addTimeAxis $pane



# Prompt the user for a sound file and open it

$widget openFile [snack::getOpenFile]

