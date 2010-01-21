#!/bin/sh
# the next line restarts using wish \
exec wish8.3 "$0" "$@"

set outputDir .

# Search for wsurf package in current dir and load it

set auto_path [concat [file dirname [info script]] $auto_path]

package require -exact wsurf 1.4
::wsurf::Initialize

# Create and pack one wsurf widget

set ind [lsearch [::wsurf::GetConfigurations] *Waveform*]
set conf [lindex [::wsurf::GetConfigurations] $ind]
set w [wsurf .ws -collapser 0 -icons {play pause stop} \
    -configuration $conf]
pack $w -expand 0 -fill both
bind . <space> [list $w play]

pack [frame .f] -fill x -expand true
pack [button .f.ls -text "Load sound" -command LoadSound] -side left -expand 1 -anchor w
pack [button .f.lt -text "Load text" -command LoadText] -side left -expand 1 -anchor w
pack [button .f.s -text Save -command Save] -side left -anchor e
pack [entry .e -textvariable entryText] -expand 1 -fill both
pack [frame .f2]
listbox .f2.l -yscrollcommand [list .f2.sb set] -width 80
scrollbar .f2.sb -orient vertical -command [list .f2.l yview]
pack .f2.sb -side right -expand 1 -fill y
pack .f2.l -side right -expand 1 -fill both
bind .f2.l <<ListboxSelect>> Select 

proc Select {} {
 set index [.f2.l curselection]
 if {$index != ""} {
  set ::entryText [.f2.l get $index]
  .f2.l see $index
 }
}

proc LoadSound {} {
 LoadSoundFile [snack::getOpenFile]
}

proc LoadSoundFile {fileName} {
 set ::filename $fileName
 $::w openFile $fileName
 $::w configure -selection [list 0.0 0.0]
 set s [$::w cget -sound] 
 $::w xzoom 0.0 [expr 10.0/[$s length -unit sec]]
}

proc LoadText {} {
 LoadTextFile [tk_getOpenFile]
}

proc LoadTextFile {fileName} {
 set f [open $fileName]
 .f2.l delete 0 end
 foreach line [split [read -nonewline $f] \n] {
  .f2.l insert end $line
 }
 close $f
 .f2.l selection set 0
 Select
}

proc Save {} {
 set cutnr [.f2.l curselection]
 if {$cutnr != ""} {
  set s [$::w cget -sound]
  foreach {left right} [$::w cget -selection] break
  set start [expr {int($left*[$s cget -rate])}]
  set end   [expr {int($right*[$s cget -rate])}]
  $s write $::outputDir/[file tail [file root $::filename]].$cutnr.wav -start $start -end $end
  
  set lf [open $::outputDir/[file tail [file root $::filename]].$cutnr.txt w]
  puts $lf $::entryText
  close $lf
  
  incr cutnr
  .f2.l selection clear 0 end
  .f2.l selection set $cutnr
  Select
  $::w configure -selection [list $right $right]
 }
}

if {$argv != ""} {
 LoadSoundFile [lindex $argv 0]
 LoadTextFile [lindex $argv end]
}
