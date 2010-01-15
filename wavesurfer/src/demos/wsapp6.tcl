#!/bin/sh
# the next line restarts using wish \
exec wish8.4 "$0" "$@"

catch {package require Tk}

# Minimal example of how to link two wsurf widgets.


# Search for wsurf package one level above this script's directory
# This is for easy testing purposes when wsurf has not been installed

set auto_path [concat [file join [file dirname [info script]] ..] $auto_path]

package require -exact wsurf 1.8

::wsurf::Initialize


wsurf::SetPreference yaxisWidth 0

# Create and pack two wsurf widgets using Waveform configurations

set ind [lsearch [::wsurf::GetConfigurations] *Waveform*]
set conf [lindex [::wsurf::GetConfigurations] $ind]

set w1 [wsurf .w1 -collapser 0 -configuration $conf -icons [list play pause stop zoomin zoomout]]
grid forget $w1.workspace.wavebar.c0
pack $w1 -expand 0 -fill both

set w2 [wsurf .w2 -collapser 0 -configuration $conf -icons [list play pause stop zoomin zoomout]]
pack $w2 -expand 0 -fill both


# Make the widgets control each other

$w1 configure -slaves $w2
$w2 configure -slaves $w1


# Create some buttons at the bottom of the window

snack::createIcons

pack [label .a -text Top:] -side left
pack [button .b -image snackOpen \
    -command {$w1 openFile [snack::getOpenFile]}] -side left
pack [label .c -text Bottom:] -side left
pack [button .d -image snackOpen \
    -command {$w2 openFile [snack::getOpenFile]}] -side left
