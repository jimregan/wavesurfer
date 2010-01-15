#!/bin/sh
# the next line restarts using wish \
exec wish8.3 "$0" "$@"


# Search for wsurf package in current dir and load it

set auto_path [concat [file dirname [info script]] $auto_path]

package require -exact wsurf 1.1
::wsurf::Initialize

set filename [lindex $argv 0]

# Create and pack one wsurf widget

set ind [lsearch [::wsurf::GetConfigurations] *Waveform*]
set conf [lindex [::wsurf::GetConfigurations] $ind]
set w [wsurf .ws -collapser 0 -icons {play pause stop} \
    -configuration $conf]
pack $w -expand 0 -fill both

pack [frame .f] -fill x -expand true
pack [button .f.nf -text NextF -command NextF] -side left -expand 1 -anchor w
pack [button .f.n -text Next -command Next] -side left -anchor e
pack [button .f.s -text Save -command Save] -side left -anchor e
pack [frame .f2]
text .f2.t -yscrollcommand [list .f2.sb set] -wrap word
scrollbar .f2.sb -orient vertical -command [list .f2.t yview]
pack .f2.sb -side right -expand 1 -fill y
pack .f2.t -side right -expand 1 -fill both

proc NextF {} {
  incr ::filenr
  set ::filename [lindex $::files $::filenr]
  $::w openFile $::filename
  set ::wend -1

  set ::candidates {}
  LoadRec
  set ::segnr 0
  set ::cutnr 0

  set filename /space/db/eurom1/pass/
  append filename [lindex [file split [file root $::filename]] end].mix
  .f2.t delete 0.0 end
  if {[file readable $filename]} {
    set mf [open $filename]
    set text [read $mf]
    close $mf
    .f2.t insert end $text
  }
  Next
}

proc Next {} {
  set start [lindex $::candidates $::segnr]
  incr ::segnr
  while {$start < $::wend*625} {
    set start [lindex $::candidates $::segnr]
    if {$start == ""} return
    incr ::segnr
  }
  set end [lindex $::candidates $::segnr]
  if {$end == ""} return
  $::w configure -selection [list [expr {$start/10000000.0}] \
      [expr {$end/10000000.0}]]
  $::w play
}

proc LoadRec {} {
  set rf [open [lindex [file split [file root $::filename]] end].rec]
  set ::candidates {}
  set startsil -1
  set segend 0
  foreach row [split [read $rf] \n] {
    if {[scan $row {%d %d %s} start end label] == 3} {
      if {$label == "SILENCE"} {
	if {$end - $start > 2000000} {
	  if {$startsil == -1} {
	    set startsil $start
	  }
	  set endsil $end
	}
      } else {
	if {$startsil >= 0} {
	  if {$label == "K" || $label == "P" || $label == "T" \
	      || $label == "k" || $label == "p" || $label == "t"} {
	    set segend 0
	  } else {
	    set segend 1
	  }
	} else {
	  set segend 0
	}
      }
      if {$segend > 0} {
	lappend ::candidates [expr {$startsil + ($endsil - $startsil) / 2.0}]
	set segend 0
	set startsil -1
      }
    }
  }

#  Might have missed initial silence
  if {[lindex $::candidates 0] > 5000000} {
    set ::candidates [linsert $::candidates 0 0]
  }
#  Might have missed final silence
  set s [$::w cget -sound]
  if {[lindex $::candidates end] < ([$s length -unit sec]-0.5)*10000000} {
    lappend ::candidates [expr int([$s length -unit sec]*10000000)]
  }
  close $rf
}

proc Save {} {
  set s [$::w cget -sound]
  foreach {left right} [$::w cget -selection] break
  set ::wstart [expr {int($left*[$s cget -rate])}]
  set ::wend   [expr {int($right*[$s cget -rate])}]
  $s write [file root $::filename]_$::cutnr.wav -start $::wstart -end $::wend
  incr ::cutnr
  Next
#  if {$::segnr >= [llength $::candidates]} NextF
}

set files [lsort [glob [file dirname $filename]/????????.wav]]
set filenr [lsearch $files *$filename]

set wend -1
incr filenr -1
NextF
$w xzoom 0.0 1.0
