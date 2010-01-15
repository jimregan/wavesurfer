#!/bin/sh
# the next line restarts using wish \
exec wish8.4 "$0" "$@"

catch {package require Tk}


# Search for wsurf package one level above this script's directory
# This is for easy testing purposes when wsurf has not been installed

set auto_path [concat [file join [file dirname [info script]] ..] $auto_path]
package require -exact wsurf 1.8
::wsurf::Initialize


# Create and pack one wsurf widget using a Waveform configuration

set ind [lsearch [::wsurf::GetConfigurations] *Waveform*]
set conf [lindex [::wsurf::GetConfigurations] $ind]
set w [wsurf .ws -collapser 0 -icons {play pause stop} -configuration $conf]
pack $w -expand 0 -fill both


# Create a simple user interface (one listbox and one button)

pack [frame .f]
listbox .f.lb -yscrollcommand [list .f.sb set] -width 90
bind .f.lb <<ListboxSelect>> Select
scrollbar .f.sb -orient vertical -command [list .f.lb yview]
pack .f.sb -side right -expand 1 -fill y
pack .f.lb -side right -expand 1 -fill both

pack [button .b -text Open -command Open]


# Create binding for spacebar to play selection

bind . <space> [list $w play]


# This procedure is called whenever a selection in the listbox is made

proc Select {} {

  # Get filename from selection and load the sound
  set index [.f.lb curselection]
  set filename [lindex [.f.lb get $index] 0]
  if {![file readable $filename]} {
    tk_messageBox -message "No such file: $filename"
    return
  }
  $::w openFile $filename

  # Get start and end values and set the wsurf widgets's selection
  set start [lindex [.f.lb get $index] 1]
  set end  [lindex [.f.lb get $index] 2]
  $::w configure -selection [list $start $end]
  $::w xzoom 0.0 1.0
}


# Open a new text file containing filenames and segment times

proc Open {} {
  .f.lb delete 0 end
  set filename [tk_getOpenFile]
  set f [open $filename]
  set text [read $f]
  foreach line [split $text \n] {
    regsub -all {\t} $line "  " tmp
    .f.lb insert end $tmp
  }
  close $f
}


# Insert a couple of example lines to start off with

.f.lb insert end "ex1.wav 0.1 0.2"
.f.lb insert end "ex1.wav 0.3 0.5"
.f.lb insert end "ex2.wav 0.2 0.4"
.f.lb insert end "ex2.wav 0.5 0.6"
