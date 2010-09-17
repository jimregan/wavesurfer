#
#  @COPYRIGHT@
#
# This file is part of the WaveSurfer package.
# The latest version can be found at http://sourceforge.net/projects/wavesurfer
#

package provide wsurf 1.8

namespace eval resizer {
# puts [info script]
 variable mode       ; # outline or full
 set mode outline

 image create bitmap emptybm -data {
  #define a_width 7
  #define a_height 8
  static char a_bits[] = {
   0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
  }
 }
}

# namespace export resizer::addResizer resizer::configure

proc resizer::mode {m} {
 variable mode
 if {[lsearch [list outline full] $m]==-1} {
  error "bad mode \"$m\", must be outline or full"
 }
 set mode $m
}

proc resizer::configure {w args} {
# puts [info level 0]
 upvar #0 $w a
 array set a $args
# parray a
 set h ${w}_handle

 foreach {opt val} [array get a] {
  switch -- $opt {
   -minheight -
   -maxheight {
    set a($opt) $val
    set newh [$w cget -height]
    if {[set minh $a(-minheight)] >= 0} {
     if {$newh<$minh} {set newh $minh}
    }
    if {[set maxh $a(-maxheight)] >= 0} {
     if {$newh>$maxh} {set newh $maxh}
    }
    if {$minh==$maxh} {
     $h configure -relief sunken -cursor ""
    } else {
     $h configure -relief raised -cursor sb_v_double_arrow 
    }
   }
   -height {
    $a(bar) configure $opt $val
    $h configure $opt $val
   }
   default {
    catch {$h configure $opt $val}
   }
  }
  if {[info exists newh]} {
   $w configure -height $newh
  }
 }
}

 
proc resizer::addResizer {w args} {
# puts [info level 0]
 upvar #0 $w a
 
 array set a {-type divider -height 2 -minheight -1 -maxheight -1}
 array set a $args

 set a(bar) [toplevel $w.bar -relief raised -bd 1 -height $a(-height)]
 wm withdraw $w.bar
 wm overrideredirect $w.bar 1

 switch $a(-type) {
  divider {
   eval _divider $w
  }
  box {
   bind $w <Configure> [namespace code [eval list _box $w]]
  }
 }
}

proc resizer::_box {w} {
 # puts [info level 0]
 upvar #0 $w a

 set h ${w}_handle
 if {![winfo exists $h]} {
  label $h -image emptybm -cursor sb_v_double_arrow -relief raised -bd 1
  eval configure $w
 }
 place $h -x 8 -y [expr {[winfo y $w]+[winfo height $w]-5}]
 foreach event {ButtonPress B1-Motion ButtonRelease} {
  bind $h <$event> [namespace code [list handleCB $event $h $w %X %Y]]
 }
 bind $w <Destroy> [list destroy $h]
 update idletasks
}

proc resizer::_divider {w} {
# puts [info level 0]

 upvar #0 $w a

# parray a

 set h ${w}_handle
 if {![winfo exists $h]} {
  if {![string match pack [winfo manager $w]]} {
   error "window \"$w\" is not managed by pack"
  }
  tk_frame $h -cursor sb_v_double_arrow -relief raised -bd 1
  eval configure $w
  pack $h -side top -fill x -after $w
  foreach event {ButtonPress B1-Motion ButtonRelease} {
   bind $h <$event> [namespace code [list handleCB $event $h $w %X %Y]]
  }
  bind $w <Destroy> [list destroy $h]
 }
}

proc resizer::handleCB {event h w X Y} {
 # puts [info level 0]
 upvar #0 $w a
 variable mode
 
 if {$a(-maxheight)==$a(-minheight)} return

 switch $event {
  Enter {
   $h configure -image updownarrow
  }
  Leave {
   $h configure -image emptybm
  }
  ButtonPress {
   set a(Y0) $Y
#   set a(h) [winfo height $w]
   set a(h) [$w cget -height]
   if {[string match outline $mode]} {
    set bw [winfo width $w]
    set bx [winfo rootx $w]
    set by [expr {[winfo rooty $w] + [winfo height $w]}]
    wm geometry $w.bar ${bw}x$a(-height)+$bx+$by
    update idletasks
    raise $w.bar
    wm deiconify $w.bar
   }
  }
  B1-Motion {
   if {![info exists a(h)]} return
   set newh [expr {$a(h)+$Y-$a(Y0)}]
   if {[set minh $a(-minheight)] >= 0} {
    if {$newh<$minh} {set newh $minh}
   }
   if {[set maxh $a(-maxheight)] >= 0} {
    if {$newh>$maxh} {set newh $maxh}
   }
   set a(Y0) [expr {$a(Y0)+$newh-$a(h)}]
   set a(h) $newh
   if {[string match outline $mode]} {
    wm geometry $w.bar +[winfo rootx $w]+[expr {[winfo rooty $w] + $newh}]
   } else {
    $w configure -height $newh
   }
  }
  ButtonRelease {
   if {![info exists a(h)]} return
   if {[string match outline $mode]} {
    wm withdraw $w.bar
    $w configure -height $a(h)
   }
  }
 }
}




