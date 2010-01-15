#!/bin/sh
# the next line restarts using wish \
exec wish8.4 "$0" "$@"

catch {package require Tk}

# This examples allows two versions of a sound file to be loaded.
# The play button at the bottom of the GUI will start playback on
# both files simultaneously, but the second one will be muted.
# The 'Select' buttons can now be used to switch
# between the sound files while playback is proceeding.

# Search for wsurf package one level above this script's directory
# This is for easy testing purposes when wsurf has not been installed

set auto_path [concat [file join [file dirname [info script]] ..] $auto_path]

package require -exact wsurf 1.8
::wsurf::Initialize


# Create and pack two wsurf widgets using Waveform configurations

set ind [lsearch [::wsurf::GetConfigurations] *Waveform*]
set conf [lindex [::wsurf::GetConfigurations] $ind]

set w1 [wsurf .w1 -collapser 0 -configuration $conf -icons [list play pause stop]]
pack $w1 -expand 0 -fill both

set w2 [wsurf .w2 -collapser 0 -configuration $conf -icons [list play pause stop]]
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
pack [button .e -bitmap snackPlay -command SyncPlay] -side left
pack [label .f -text "Fade to:"] -side left
pack [button .g -text "top" -command [list SwapPlay 1]] -side left
pack [button .h -text "bottom" -command [list SwapPlay 2]] -side left

proc SyncPlay {} {
 $::w1 play
 set ::wsurf::Info(ActiveSound) ""
 $::w2 play
}

proc SwapPlay {selectWidget} {
 if {$selectWidget == 1} {
  $::w1 configure -playmapfilter 1
  $::w2 configure -playmapfilter 0
 } else {
  $::w1 configure -playmapfilter 0
  $::w2 configure -playmapfilter 1
 }
}
SwapPlay 1
