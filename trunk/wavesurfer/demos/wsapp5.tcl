#!/bin/sh
# the next line restarts using wish \
exec wish8.4 "$0" "$@"

catch {package require Tk}

# Minimal example of a custom application using the wsurf widget.
#
# This example shows how to create a wsurf widget and how to add a 
# waveform pane, a time axis pane, and an empty visualization pane,
# where custom graphics can be put.


# Search for wsurf package one level above this script's directory
# This is for easy testing purposes when wsurf has not been installed

set auto_path [concat [file join [file dirname [info script]] ..] $auto_path]
package require -exact wsurf 1.8


# Initialize wsurf package (this will set default preferences)

::wsurf::Initialize

# Make widget scroll during playback

set scroll Scroll
wsurf::SetPreference autoScroll $scroll



# Create and pack one wsurf widget

set widget [wsurf .ws -collapser 0 -icons [list beg play pause stop zoomin zoomout zoomall zoomsel]]

pack $widget -expand 0 -fill both



# Add a couple of panes and some content from the standard plug-ins
# These lines have been copied from the standard Waveform configuration,
# ../wsurf1.8/configurations/Waveform.conf

set pane [$widget addPane -maxheight 2048  -minheight 10]
$widget analysis::addWaveform $pane

set pane [$widget addPane -maxheight 20  -minheight 20]
$widget timeaxis::addTimeAxis $pane

# Create a pane for custom drawing, keep track of its name in $myPane

set myPane [$widget addPane -height 100]



# Procedure that draws something in our pane (only)

proc Redraw {w pane} {
  if {$pane == $::myPane} {
    set c [$pane canvas]
    set width [expr {[$pane cget -maxtime] * [$pane cget -pixelspersecond]}]
    set height [$pane cget -scrollheight]
    $c delete all
    $c create line 0 0 $width $height
  }
}



# Register the "Redraw" procedure with the wsurf library.
# Every time the user zooms in or out with the wavebar "Redraw"
# will be called in order to update the contents of our pane.

wsurf::RegisterPlugin wsapp5
wsurf::ExecuteRegisterPlugin wsapp5 -redrawproc Redraw



# Prompt the user for a sound file, open it and draw something simple

proc Load {} {
  $::widget openFile [snack::getOpenFile]
}



# Create some buttons at the bottom of the window

snack::createIcons

pack [button .a -image snackOpen -command Load] -side left


foreach type [list None Page Scroll] {
 pack [radiobutton .r$type -text $type -value $type -variable scroll \
	   -command [list wsurf::SetPreference autoScroll $type]] -side left
}
