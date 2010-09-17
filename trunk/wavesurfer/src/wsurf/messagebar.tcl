#
#  @COPYRIGHT@
#
# This file is part of the WaveSurfer package.
# The latest version can be found at http://sourceforge.net/projects/wavesurfer
#

package provide wsurf 1.8

namespace eval messagebar {
 variable Info

 set Info(OptionTable) [list \
   -height             20 \
   -width              "" \
   -bg                 "" \
   -fg                 black \
   -level              0.0 \
   -text               "" \
   -font               "" \
   -inverted           0 \
   -locked             0 \
   -outline            "" \
   -progress           0.0 \
   -command            "" \
   -state              normal
 ]
}


proc messagebar::create {w args} {
#  puts [info level 0]
 variable Info
 namespace eval [namespace current]::$w {
  variable data
 }
 upvar [namespace current]::${w}::data d

 set d(height) 0
 set d(width) 0
 set d(scalewidth) 0
 set d(progress) -1
 set d(command) ""
 set d(state) normal
 set d(locked) 0
 set d(inverted) 0
 set d(maxtime) [clock seconds]
 set d(maxlevel) 0.0

 canvas $w -highlightthickness 0
 $w create rectangle 0 0 0 0 -tags bar
 $w create line -1 -1 -1 -1 -tags peakbar -fill red
 $w create text 0 0 -anchor w -tags text
 
 bind $w <Configure> [namespace code [list redraw $w %w %h]]

 $w bind text <1>         "$w select from current @%x,%y"
 $w bind text <B1-Motion> "$w select to current @%x,%y"

 eval configure $w $Info(OptionTable)
 eval configure $w $args

 return $w
}

proc messagebar::configure {w args} {
 variable Info
 upvar [namespace current]::${w}::data d

 foreach {opt val} $Info(OptionTable) {set OptionMap($opt) 1}
# parray OptionMap
 foreach {opt val} $args {
  if {![info exists OptionMap($opt)]} {
   error "unknown option \"$opt\""
  } else {
   switch -- $opt {
    -height -
    -width {
     if {$val != ""} {$w configure $opt $val}
    }
    -bg {
     if {$val != ""} {$w configure $opt $val}
     $w itemconfig bar -fill [util::RGBintensity [$w cget -bg] -.2]
    }
    -level {
      if {[clock seconds] - $d(maxtime) > 1} {
	set d(maxtime) [clock seconds]
	set d(maxlevel) 0.0
      }
      if {$val > $d(maxlevel)} {
	set d(maxlevel) $val
      }
      set x [expr {$d(maxlevel)*$d(width)-1}]
      $w coords peakbar $x 0 $x $d(height)

      set d(progress) $val
      if {$val != 0.0} {
	$w itemconfig bar -fill red
	if {$d(width) > 0 && $d(scalewidth) != $d(width)} {
	  $w delete scale
	  $w itemconfig text -text ""
	  set d(scalewidth) $d(width)
	  for {set i 0} {$i < 90} {incr i 6} {
	    set x [expr $i*$d(scalewidth)/90.0]
	    $w create line $x 17 $x 20 -tags scale
	  }
	  if {$d(scalewidth) > 400} {
	    for {set i -84} {$i <= -6} {incr i 12} {
	      set x [expr $d(scalewidth)+$i*$d(scalewidth)/90.0]
	      $w create text $x 18 -text $i -tags scale -anchor s
	    }
	  }
	  for {set i -78} {$i <= -6} {incr i 12} {
	    set x [expr $d(scalewidth)+$i*$d(scalewidth)/90.0]
	    $w create text $x 18 -text $i -tags scale -anchor s
	  }
	  set d(locked) 1
	  $w itemconfig text -text dB
	}
      } else {
	$w itemconfig bar -fill [util::RGBintensity [$w cget -bg] -.2]
	$w delete scale
	$w coords peakbar -1 -1 -1 -1
	set d(scalewidth) 0
	set d(locked) 0
	$w itemconfig text -text ""
      }
    }
    -fg {
     $w itemconfig text -fill $val
    }
    -text {
      if {$d(locked) == 0} {
	$w itemconfig text $opt $val
      }
    }
    -font {
     if {$val != ""} {$w itemconfig text $opt $val}
    }
    -outline {
     if {$val==""} {
      $w itemconfig bar -outline [$w itemcget bar -fill]
     }
    }
    -inverted {
     if {$val} {set d(inverted) 1} else {set d(inverted) 0}
    }
    -locked {
      set d(locked) $val
      $w select clear
    }
    -command {
     set d(command) $val
     bind $w <1> [namespace code [list invoke $w]]
    }
    -state {
     if {[lsearch [list normal disabled] $val]==-1} {
      error "bad state \"$val\": must be disabled, or normal"
     }
     set d(state) $val
    }
    -progress {
     set d(progress) $val
    }
   }
  }
  redraw $w
 }
}

proc messagebar::invoke {w} {
 upvar [namespace current]::${w}::data d

 if {[string match normal $d(state)]} {
  eval $d(command)
 }
}

proc messagebar::redraw {w {width -1} {height -1}} {
 upvar [namespace current]::${w}::data d

 if {$width>0} {set d(width) $width}
 if {$height>0} {set d(height) $height}
 set xbar [expr {$d(progress)*$d(width)-1}]
 set ybar [expr {$d(height)}]
 if {$d(progress)<0} {
 $w coords bar -2 -2 -2 -2
 } else {
  if {$d(inverted)} {
   $w coords bar $xbar 0 $d(width) $ybar
  } else {
   $w coords bar 0 0 $xbar $ybar
  }
 }
 $w coords text 1 [expr {$ybar/2}]
}

proc messagebar::Test {} { 
 uplevel source surfutil.tcl
 pack [messagebar::create .w -text tjena -progress .25 -command "puts hellooo"] -expand 1 -fill both
}
