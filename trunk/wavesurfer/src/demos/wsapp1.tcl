#!/bin/sh
# the next line restarts using wish \
exec wish8.4 "$0" "$@"

catch {package require Tk}

# Minimal example of a custom application using the wsurf widget.


# Search for wsurf package one level above this script's directory
# This is for easy testing purposes when wsurf has not been installed

set auto_path [concat [file join [file dirname [info script]] ..] $auto_path]

package require -exact wsurf 1.8



# Create and pack one wsurf widget

set w [wsurf .ws -collapser 0 -icons {play pause stop record}]

pack $w -expand 0 -fill both



# Try to load the first sound file given on the command line

$w openFile [lindex $argv 0]
