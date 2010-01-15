#!/bin/sh
# the next line restarts using wish \
exec wish8.4 "$0" "$@"

# This tool was developed to verify and correct the Swedish part
# of the SPEECON database
# http://www.speecon.com/

# Lots of magic stuff going on here don't worry unless you have to
#
# wrapit.tcl will insert code here to set the elements of the wrap() array

catch {package require Tk}

if {[info exists wrap]} {
 # package dirs have to be listed explicitly for wrapping
 # a line setting wrapdir is added by the wrapping script
 set dir $wrap(dir)
 set auto_path "[file join $dir snack] [file join $dir wsurf] $auto_path"
} else {
 set auto_path [concat [list [file dirname [info script]]] \
     [file dirname [pwd]parent] $auto_path]
}

package require surfutil

# re-define load to work with free-wrap
if {[info exists wrap] && [info command _load]==""} {
 rename load _load
 proc load {filename args} {
  set f [open $filename]
  fconfigure $f -encoding binary -translation binary
  set data [read $f]
  close $f
  set fname2 [file join [util::tmpdir] [file rootname [file tail $filename]].[pid]]
  set f [open $fname2 w]
  fconfigure $f -encoding binary -translation binary
  puts -nonewline $f $data
  close $f
  eval _load $fname2 $args
 }
}

# End of magic

package require wsurf 1.8

if {[info exists wrap]} {
 rename load ""
 rename _load load
}

::wsurf::Initialize


# Create and pack one wsurf widget and add a waveform pane

set w [wsurf .ws -collapser 0 -icons {play pause stop} -playpositionproc playpos]
pack $w -expand 0 -fill both
set pane [$w addPane -maxheight 2048  -minheight 10 -height 120]
$w analysis::addWaveform $pane
lappend ::wsurf::Info(Prefs,rawFormats) .SE0 16000 LIN16 1 littleEndian 0 .SE1 16000 LIN16 1 littleEndian 0 .SE2 16000 LIN16 1 littleEndian 0 .SE3 16000 LIN16 1 littleEndian 0
set info ""
pack [frame .if]
pack [label .if.l -textvariable ::info] -side left
pack [button .if.b -command ShowInfo -text "Show all"] -side left
pack [frame .f] -expand 1 -fill both
pack [scrollbar .f.sb -orient vert -command [list .f.t yview]] \
  -side right -fill y
pack [text .f.t -width 60 -height 3 -font "helvetica 18" -wrap word -yscrollcommand [list .f.sb set] -exportselection 0] -side right -expand 1 -fill both

pack [frame .bf]
pack [button .bf.b11 -text {[sta]} -command [list Ins {[sta]}] -width 5] -side left
pack [button .bf.b12 -text {[int]} -command [list Ins {[int]}] -width 5] -side left
pack [button .bf.b13 -text {[fil]} -command [list Ins {[fil]}] -width 5] -side left
pack [button .bf.b14 -text {[spk]} -command [list Ins {[spk]}] -width 5] -side left
pack [button .bf.b1 -text < -command Prev -width 5] -side left
pack [button .bf.b2 -text Pause -command [list $w pause] -width 5] -side left
pack [button .bf.b3 -text Play -command [list $w play] -width 5] -side left
pack [button .bf.b4 -text Replay -command Replay -width 6] -side left
pack [button .bf.b5 -text > -command Next -width 5] -side left
pack [button .bf.b6 -text Decap -command Decap -width 5] -side left

bind . <Control-Down> [list $w play]
bind . <Control-Shift-Down> Replay
bind . <Control-Up> [list $w pause]
bind . <Control-Left> Prev
bind . <Control-Right> Next
bind . <Control-p> Decap
bind . <F1> [list Ins {[sta]}]
bind . <F2> [list Ins {[int]}]
bind . <F3> [list Ins {[fil]}]
bind . <F4> [list Ins {[spk]}]

pack [frame .f2]
listbox .f2.lb -yscrollcommand [list .f2.sb set] -width 20 -height 7
bind .f2.lb <<ListboxSelect>> Select
scrollbar .f2.sb -orient vertical -command [list .f2.lb yview]
pack .f2.sb -side right -expand 1 -fill y
pack .f2.lb -side right -expand 1 -fill both

proc Ins {sym} {
 .f.t insert insert " $sym "
}

proc Decap {} {
 set str [string trim [.f.t get 0.0 end]]
 set str [string tolower $str 0 1]
 .f.t delete 0.0 end
 .f.t insert 0.0 $str
 .f.t mark set insert 0.0
}

proc Select {} {
 if {[string compare $::text [string trim [.f.t get 0.0 end]]]} Save
 if {[.f2.lb curselection] != ""} {
  set ::index [.f2.lb curselection]
  Load
 }
}

proc Prev {} {
 if {[string compare $::text [string trim [.f.t get 0.0 end]]]} Save
 incr ::index -1
 Load
}

proc Next {} {
 if {[string compare $::text [string trim [.f.t get 0.0 end]]]} Save
 incr ::index
 Load
}

proc playpos {m pos} {
 set ::playpos $pos
}

proc Replay {} {
 set ::playpos [expr $::playpos - 2.0]
 $::w play $::playpos -1
}

proc Load {} {
 set labelfile [lindex $::files $::index]
 if {$labelfile == ""} {
  if {$::index < 0} { set ::index 0 }
  if {$::index >= [llength $::files]} { set ::index [expr [llength $::files]-1] }
  return
 }
 set f [open $labelfile]
 fconfigure $f -encoding binary
 set ::data [string trim [read $f]]
 close $f
 set ::text _junk
 set ::lineno 0
 foreach line [split $::data \n] {
  regsub -all {\.|!|;} $line " " line
#  regexp {LBO:\s[\d\,]*\s([\*\~\[\]\w\s\-\.\:\@]*)} $line dummy ::text
  if {[regexp {SEX:\s(.*)} $line dummy tmp]} {
   set ::info $tmp
  }
  if {[regexp {AGE:\s(.*)} $line dummy tmp]} {
   append ::info ", $tmp"
  }
  if {[regexp {ACC:\s(.*)} $line dummy tmp]} {
   append ::info ", $tmp"
  }
  if {[regexp {SCC:\s(.*)} $line dummy tmp]} {
   append ::info ", $tmp"
  }
  regexp {LBO:\s[\d\,]*\s(.*)} $line dummy ::text
  if {[string compare $::text _junk] != 0} {
   if {[string match {*\?\?*} $line]} { set prompt 1 }
   regsub -all {\?|,} $::text "" ::text
   break
  }
  incr ::lineno
 }
 .f.t delete 0.0 end
 if {[string compare $::text _junk] == 0} { set ::text "" }
 regsub -all {_} $::text " " ::text2
 regsub -all {noise rec} $::text2 "noise_rec" ::text2
 regsub -all {silence word} $::text2 "silence_word" text
 .f.t insert 0.0 $text
 .f.t mark set insert 0.0
 if {[info exists prompt]} {
  focus .f.t
  .f.t tag add sel 0.0 end
 }
 set sndfile [glob -nocomplain [file root $labelfile].??$::mic]
 $::w openFile $sndfile
 $::w configure -selection [list 0.0 0.0]
 update
 $::w xzoom 0.0 1.0
 $::w play
 .f2.lb selection clear 0 end
 .f2.lb selection set $::index
 .f2.lb see $::index
}

proc UpdateSound {} {
 set labelfile [lindex $::files $::index]
 set sndfile [glob -nocomplain [file root $labelfile].??$::mic]
 $::w openFile $sndfile
}

proc ShowInfo {} {
 catch {destroy .info}
 toplevel .info
 pack [text .info.t -height 40]
 .info.t insert 0.0 $::data
}

proc Save {} {
 set labelfile [lindex $::files $::index]
 if {$labelfile == ""} return
 if {[file exists [file root $labelfile].BAK] == 0} {
  file rename $labelfile [file root $labelfile].BAK
 }
 set f [open $labelfile w]
 fconfigure $f -translation crlf -encoding binary
 set i 0
 foreach line [split $::data \n] {
  if {$i == $::lineno} {
   regsub {LBO:\s([\d\,]*)\s.*} $line {LBO: \1 } out
   set text [string trim [.f.t get 0.0 end]]
   regsub -all {\.|!|\?|;} $text " " text
   regsub -all {\s+} $text " " text
   puts $f $out$text
  } else {
   puts $f $line
  }
  incr i
 }
 close $f
}

proc SelectVerif {} {
 if {[string compare $::text [string trim [.f.t get 0.0 end]]]} Save
 .f.t delete 0.0 end
 for {set i 0} {$i < [.tl.f2.lb size]} {incr i} {
  .tl.f2.lb itemconf $i -background ""
 }
 set i [.tl.f2.lb curselection]
 .tl.f2.lb itemconf $i -background white
 if {$i != ""} {
  update
  NewSession [.tl.f2.lb get $i]
  set ::listboxIndex $i
 }
}

proc NextVerif {} {
 if {[string compare $::text [string trim [.f.t get 0.0 end]]]} Save
 .f.t delete 0.0 end
 for {set i 0} {$i < [.tl.f2.lb size]} {incr i} {
  .tl.f2.lb itemconf $i -background ""
 }
 incr ::listboxIndex
 .tl.f2.lb itemconf $::listboxIndex -background white
 if {$::listboxIndex != ""} {
  update
  NewSession [.tl.f2.lb get $::listboxIndex]
 .tl.f2.lb see $::listboxIndex
 }
}

proc OpenVerif {} {
 set ::listboxIndex 0
 set file [tk_getOpenFile -title "Open error file"]
# set file ~/junk.txt
 set fd [open $file]
 set lines [read -nonewline $fd]
 close $fd
 foreach row [split $lines \n] {
  scan $row "%s %s" filename junk
  .tl.f2.lb insert end $filename
 }
}

proc Verification {} {
 catch {destroy .tl}
 toplevel .tl

 list {
.bf.b1 configure -state disabled
.bf.b5 configure -state disabled
 bind . <Control-Left> ""
 bind . <Control-Right> ""
 }
 pack [frame .tl.f2] -expand 1 -fill both
 listbox .tl.f2.lb -yscrollcommand [list .tl.f2.sb set] -width 80 -height 17
 bind .tl.f2.lb <<ListboxSelect>> SelectVerif
 scrollbar .tl.f2.sb -orient vertical -command [list .tl.f2.lb yview]
 pack .tl.f2.sb -side right -expand 1 -fill y
 pack .tl.f2.lb -side right -expand 1 -fill both
 pack [frame .tl.f3]
 pack [button .tl.f3.b1 -text Open... -command OpenVerif] -side left
 pack [button .tl.f3.b2 -text Next -command NextVerif] -side left
#OpenVerif
}

proc NewSession {path} {
 if {[string match *.SEO $path]} {
  list {
   # slow
   set fileroot [file root [file tail $path]]
   set path [file dirname $path]
   set i [lsearch [lsort [glob -nocomplain $path/*.??0]] *$fileroot.SE0]
   set ::index [expr $i-1]
  }
  set i 0
  set ::index -1
  wm title . "Speaker: [file tail $path]"
  .f2.lb delete 0 end
  .f2.lb insert end $path
  .f2.lb selection set $i
  set ::files $path
  set ::text ""
  Next
  return
 } else {
  set i 0
  set ::index -1
 }
 wm title . "Speaker: [file tail $path]"

 .f2.lb delete 0 end
 set ::files [lsort [glob -nocomplain $path/*.??O]]
 foreach filename $::files {
  .f2.lb insert end [file root [file tail $filename]]
 }
 .f2.lb selection set $i
 set ::text ""
 Next
}

pack [frame .cf]
pack [button .cf.b -text "Choose speaker..." -command Choose] \
  -side left
pack [label .cf.l -text Mic] -side left
set mic 0
tk_optionMenu .cf.om mic 0 1 2 3
for {set n 0} {$n < 4} {incr n} {
 .cf.om.menu entryconfigure $n -command UpdateSound
}
pack .cf.om -side left
pack [button .cf.b2 -text Verification -command Verification] -side left

proc Choose {} {
 if {[string compare $::text [string trim [.f.t get 0.0 end]]]} Save
 if {[llength [file split $::path]] > 1} {
  set pathlist [file split $::path]
  set pathlist [lrange $pathlist 0 [expr [llength $pathlist]-2]]
  set initpath [eval file join $pathlist]
 } else {
  set initpath ""
 }
 set ::path [tk_chooseDirectory -title "Choose Speaker Directory" -initialdir $initpath]
 NewSession $::path
}

set files ""
set index -1
set text ""

set path ""
if {$argv != ""} {
 set path $argv
 NewSession $path
}

update
focus .f.t
.f.t mark set insert end
wm withdraw .
update
wm deiconify .
