#
#  @COPYRIGHT@
#
# This file is part of the WaveSurfer package.
# The latest version can be found at http://sourceforge.net/projects/wavesurfer
#

package provide wsurf 1.8
package require snack 2.2
package require surfutil 1.8

namespace eval wavebar {
    variable Info
    
    if {![info exists Info(Initialized)]} {
	set Info(OptionTable) \
	    [list \
		 -height             25 \
		 -width              300 \
		 -troughcolor        [ttk::style lookup TLabel -background] \
		 -sound              "" \
		 -shapefile          "" \
		 -progress           "" \
		 -command            "" \
		 -messageproc        "" \
		 -zoomcommand        "" \
		 -zoomlimit          0.0 \
		 -repeatdelay        300 \
		 -repeatinterval     50 \
		 -background         gray \
		 -foreground         [ttk::style lookup TLabel -foreground] \
		 -shadowwidth        4 \
		 -jump               0 \
		 -zoomjump           1 \
		 -selection          [list 0.0 0.0] \
		 -state              interactive \
		 -cursorcolor        red \
		 -cursorpos          -1 \
		 -isrecording        0 \
		 -mintime            0.0 \
		 -maxtime            0.0 \
		 -formattimecommand  "" \
		 -scrollevent        1 \
		 -pixelspersecond    0.0 \
		 -zoomevent          {{Shift 1} 2} \
		]
	set Info(emptysound) [snack::sound]
	set Info(Initialized) 1
	set Info(debug) $::wsurf::Info(debug)
    }
}

# -----------------------------------------------------------------------------
proc wavebar::create {w args} {
 variable Info
 namespace eval [namespace current]::$w {variable data}
 upvar [namespace current]::${w}::data d

 set d(time1) 0
 set d(time2) 0
 set d(command) ""
 set d(c0width) 0
 set d(c0height) 0
 set d(isInteractive) 0
 set d(mintime) 0
 set d(maxtime) 0
 set d(pixelspersecond) 0
 set d(sound) ""

 frame $w
 canvas $w.c0 -highlightthickness 0 -closeenough 3
 grid $w.c0 -row 0 -column 1 -rowspan 2 -sticky news
 grid columnconfigure $w 1 -weight 1
 foreach i {0 1} {grid rowconfigure $w $i -weight 1}

 # bottom layer: visible items

 $w.c0 create polygon -1 -1 -1 -1 -1 -1 -width 2 -tags [list arrow1 a1 ss]
 $w.c0 create line -1 -1 -1 -1 -1 -1 -width 2 -tags [list arrow1shadow a1 ss]
 $w.c0 create polygon -1 -1 -1 -1 -1 -1 -width 2 -tags [list arrow2 a2 ss]
 $w.c0 create line -1 -1 -1 -1 -1 -1 -width 2 -tags [list arrow2shadow a2 ss]

 $w.c0 create polygon -1 -1 -1 -1 -1 -1 -width 1 -outline "" -tags sliderfill
 $w.c0 create line -1 -1 -1 -1 -width 2 -tags [list sliderbottomshadow ss]
 $w.c0 create line -1 -1 -1 -1 -width 2 -tags [list slidertopshadow ss]
 if {[string match macintosh $::tcl_platform(platform)] || \
	 [string match Darwin $::tcl_platform(os)]} {
  $w.c0 create polygon -1 -1 -1 -1 -1 -1 \
    -outline black -fill "" -tags selection
 } else {
  $w.c0 create polygon -1 -1 -1 -1 -1 -1 \
    -fill black -stipple gray25 -tags selection
 }
 $w.c0 create waveform -1 -1 -anchor w -width 0 -height 0 \
   -zerolevel false -tags waveform -sound $Info(emptysound) -debug $Info(debug)
 $w.c0 create line -1 -1 -1 -1 -width 1 -tags cursor

 # top layer: invisible items, to catch events

 $w.c0 create polygon -1 -1 -1 -1 -1 -1 -width 0 -outline "" -fill "" \
   -tags [list trough1]
 $w.c0 create polygon -1 -1 -1 -1 -1 -1 -width 0 -outline "" -fill "" \
   -tags  [list trough2]
 $w.c0 create polygon -1 -1 -1 -1 -1 -1 -width 2 -outline "" -fill "" \
   -tags [list slider]
 $w.c0 create line -1 -1 -1 -1 -width 0 -fill "" -tags [list bar1 bar1a]
 $w.c0 create line -1 -1 -1 -1 -width 0 -fill "" -tags [list bar1 bar1b]
 $w.c0 create line -1 -1 -1 -1 -width 0 -fill "" -tags [list bar2 bar2a]
 $w.c0 create line -1 -1 -1 -1 -width 0 -fill "" -tags [list bar2 bar2b]

 bind $w.c0 <Configure> [namespace code [list _update $w %w %h]]
 bind $w <Enter> [namespace code [list _msgHelp $w "B1: Scroll, B2/shift-B1: Zoom, ctrl-B2: Zoom full out"]\n[list _msgTime $w]]
 bind $w <Leave> [namespace code [list _msgHelp $w ""]]

    focus $w

 $w.c0 bind a1 <<ScrollBegin>> [namespace code [list _event $w downArrow 1 ""]]
 $w.c0 bind a2 <<ScrollBegin>> [namespace code [list _event $w downArrow 2 ""]]
 $w.c0 bind a1 <<ScrollEnd>> [namespace code [list _event $w upArrow 1 ""]]
 $w.c0 bind a2 <<ScrollEnd>> [namespace code [list _event $w upArrow 2 ""]]

 foreach tag {slider bar1 bar2} {
  $w.c0 bind $tag <Enter> [namespace code [list _event $w enter %x %y]]
  $w.c0 bind $tag <Leave> [namespace code [list _event $w leave %x %y]]
  $w.c0 bind $tag <<ScrollBegin>> [namespace code [list _event $w down %x %y]]
  $w.c0 bind $tag <<ScrollMove>> [namespace code [list _event $w move %x %y]]
  $w.c0 bind $tag <<ScrollEnd>> [namespace code [list _event $w up %x %y]]
  $w.c0 bind $tag <Control-ButtonRelease-2> [namespace code [list _event $w zoomAll dummy dummy]]
 }

 $w.c0 bind trough1 <<ScrollBegin>> \
   [namespace code [list _event $w downTrough 1 ""]]
 $w.c0 bind trough2 <<ScrollBegin>> \
   [namespace code [list _event $w downTrough 2 ""]]
 $w.c0 bind trough1 <<ScrollEnd>> \
   [namespace code [list _event $w upTrough 1 ""]]
 $w.c0 bind trough2 <<ScrollEnd>> \
   [namespace code [list _event $w upTrough 2 ""]]
 
 foreach n {1 2} {
  $w.c0 bind bar$n <Enter> [namespace code [list _event $w enterBar$n %x %y]]
  $w.c0 bind bar$n <Leave> [namespace code [list _event $w leaveBar$n %x %y]]
  $w.c0 bind bar$n <<ZoomBegin>> \
    [namespace code [list _event $w downBar$n %x %y]]
  $w.c0 bind bar$n <<ZoomMove>> \
    [namespace code [list _event $w moveBar$n %x %y]]
  $w.c0 bind bar$n <<ZoomEnd>> \
    [namespace code [list _event $w upBar$n %x %y]]
 }

 foreach area {trough1 slider trough2} {
  $w.c0 bind $area <<ZoomBegin>> \
    [namespace code [list _event $w down2 %x %y]]
  $w.c0 bind $area <<ZoomMove>> \
    [namespace code [list _event $w move2 %x %y]]
  $w.c0 bind $area <<ZoomEnd>> \
    [namespace code [list _event $w up2 %x %y]]
  $w.c0 bind $area <Control-ButtonRelease-2> [namespace code [list _event $w zoomAll dummy dummy]]
 }

 rename $w $w.top
 proc ::$w {cmd args} "return \[eval wavebar::\$cmd $w \$args\]"

 array set opts $Info(OptionTable)
 array set opts $args
 eval configure $w [array get opts]

 util::setClass $w Wavebar

 return $w
}

proc wavebar::_msgHelp {w msg} {
 upvar [namespace current]::${w}::data d

 if {[info exists d(messageproc)]} {
  $d(messageproc) $msg help
 }
}

proc wavebar::_msgTime {w} {
 upvar [namespace current]::${w}::data d

 if {[info exists d(messageproc)]} {
  set msg [format "WaveBar - \[%s %s\] %.2fmm/s" [eval $d(formattimecommand) $d(time1)] [eval $d(formattimecommand) $d(time2)] \
	       [expr $d(pixelspersecond) / [winfo fpixels $w 1m]]]
  $d(messageproc) $msg
 }
}

proc wavebar::syncLimits {w} {
 upvar [namespace current]::${w}::data d
 
 if {$d(sound) != ""} {
  set d(minT) [util::min $d(mintime) 0.0]
  set d(maxT) [util::max $d(maxtime) [$d(sound) length -unit sec]]
 } else {
  set d(minT) $d(mintime)
  set d(maxT) $d(maxtime)
 }
 set d(time1) [util::max $d(minT) $d(time1)]
 set d(time2) [util::min $d(maxT) $d(time2)]
 #<< [info level 0]:$d(minT)-$d(maxT)---maxtime=$d(maxtime)
}

proc wavebar::configure {w args} {
 variable Info
 upvar [namespace current]::${w}::data d

 if {[llength $args]%2} {
  error "wrong # args, must be configure ?option value?..."
 }

 foreach {opt val} $Info(OptionTable) {set OptionMap($opt) 1}
 foreach {opt val} $args {

  if {![info exists OptionMap($opt)]} {
   error "unknown option \"$opt\""
  } else {
   switch -- $opt {
    -width {
     if {$val != ""} {$w.top configure $opt $val}
    }
    -height {
     $w.c0 configure -height $val
    }
    -troughcolor {
     if {$val != ""} {$w.c0 configure -bg $val}
    }
    -background {
     if {$val != ""} {
      $w.c0 itemconfigure sliderfill -fill $val
      set d(topShadow) [util::RGBtopShadow $val]
      $w.c0 itemconfigure slidertopshadow -fill $d(topShadow)
      set d(bottomShadow) [util::RGBbottomShadow $val]
      $w.c0 itemconfigure sliderbottomshadow -fill $d(bottomShadow) 
      $w.c0 itemconfigure arrow1 -fill $val -outline $d(topShadow)
      $w.c0 itemconfigure arrow1shadow -fill $d(bottomShadow)
      $w.c0 itemconfigure arrow2 -fill $val -outline $d(topShadow)
      $w.c0 itemconfigure arrow2shadow -fill $d(bottomShadow)
     }
    }
    -fg - -foreground {
     if {$val != ""} {
      $w.c0 itemconfigure waveform -fill $val
     } 
    }
    -cursorcolor {
     $w.c0 itemconfigure cursor -fill $val
    }
    -sound {
     set d(sound) $val
     $w.c0 itemconf waveform -sound $d(sound)
     syncLimits $w
     set needUpdate 1
    }
    -mintime {
     set d(mintime) $val
     syncLimits $w
     set needUpdate 1
    }
    -maxtime {
     set d(maxtime) $val
     syncLimits $w
     set needUpdate 1
    }
    -pixelspersecond {
     set d(pixelspersecond) $val
    }
    -shapefile -
    -progress {
     $w.c0 itemconf waveform $opt $val
    }
    -shadowwidth {
     $w.c0 itemconfigure ss -width $val
    }
    -selection {
     if {[llength $val] != 2} {error "bad value for selection"}
     foreach {d(fsel1) d(fsel2)} $val break
     set selectionChanged 1
    }
    -cursorpos {
     set d(cursorpos) $val
     set cursorChanged 1
    }
    -isrecording {
     set needUpdate 1
    }
    -state {
     switch $val {
      interactive { 
       set d(arrowWidth) 20
       set d(isInteractive) 1
      } 
      passive {
       set d(arrowWidth) 0
       set d(isInteractive) 0
      }
      default {error "bad state \"$val\", must be interactive or passive"}
     }
     set needUpdate 1
    }
    -zoomevent {
     event delete <<ZoomBegin>>
     event delete <<ZoomMove>>
     event delete <<ZoomEnd>>
     foreach seq $val {
      set mod [lindex $seq [expr [llength $seq] - 2]]
      set but [lindex $seq end]
      event add <<ZoomBegin>> <[join [concat $mod ButtonPress $but] -]>
      event add <<ZoomMove>> <[join [concat $mod B$but Motion] -]>
      event add <<ZoomEnd>> <[join [concat $mod ButtonRelease $but] -]>
     }
    }
    -scrollevent {
     event delete <<ScrollBegin>>
     event delete <<ScrollMove>>
     event delete <<ScrollEnd>>
     foreach seq $val {
      set mod [lindex $seq [expr [llength $seq] - 2]]
      set but [lindex $seq end]
      event add <<ScrollBegin>> <[join [concat $mod ButtonPress $but] -]>
      event add <<ScrollMove>> <[join [concat $mod B$but Motion] -]>
      event add <<ScrollEnd>> <[join [concat $mod ButtonRelease $but] -]>
     }
    }
    default {
    }
   }
   # store the value of the option (without preceeding dash) in the data array
   set d([string trimleft $opt -]) $val
  }
 }
 if {[info exists needUpdate]} {_update $w} else {
  if {[info exists selectionChanged]} {_redrawSelection $w}
  if {[info exists cursorChanged]} {_redrawCursor $w}
 }
}

proc wavebar::cget {w option} {
 upvar [namespace current]::${w}::data d
 variable Info 

 foreach {opt val} $Info(OptionTable) {set OptionMap($opt) 1}
 if {![info exists OptionMap($option)]} {
  error "unknown option \"$option\""
 } else {
  return $d([string trimleft $option -])
 }  
}

proc wavebar::_setState {w flag} {
 upvar [namespace current]::${w}::data d

 if {$flag==0} {
  grid forget $w.b0
  grid forget $w.b1
  set d(isInteractive) 0
 } else {
  grid $w.b0 -row 0 -column 0
  grid $w.b1 -row 0 -column 2
  set d(isInteractive) 1
 } 
}

proc wavebar::_buttonUp {w} {
 variable Info
 # cancel all pending repeats
 foreach key [array names Info afterId,*] {
  after cancel $Info($key)
  unset Info($key)
 } 
}

proc wavebar::_autoScroll {w element repeat} {
 upvar [namespace current]::${w}::data d
 variable Info

 switch $element {
  "arrow1"	{scroll $w -1 units}
  "trough1"	{scroll $w -1 pages}
  "trough2"	{scroll $w 1 pages}
  "arrow2"	{scroll $w 1 units}
 }

 # cancel all pending repeats
 foreach key [array names Info afterId,*] {
  after cancel $Info($key)
  unset Info($key)
 } 
 switch $repeat {
  initial {set delay $d(repeatdelay)}
  again {set delay $d(repeatinterval)}
  default {return}
 }
 set id [after $delay [namespace code [list _autoScroll $w $element again]]]
 set Info(afterId,$id) $id
}

# conversion: x-coord to time
proc wavebar::x->t {w x} {
 upvar [namespace current]::${w}::data d

 syncLimits $w
 expr {
  $d(minT) + ($d(maxT)-$d(minT))*($x-$d(arrowWidth))/($d(c0width)-2*$d(arrowWidth))
 }
}

# conversion: time to x-coord
proc wavebar::t->x {w t} {
 upvar [namespace current]::${w}::data d

 syncLimits $w
 if {$d(maxT) == $d(minT)} {
  return 0.0
 } else {
  expr {$d(arrowWidth)+($t-$d(minT))/($d(maxT)-$d(minT))*($d(c0width)-2*$d(arrowWidth))}
 }
}

# conversion: fraction to time
proc wavebar::frac->t {w frac} {
 upvar [namespace current]::${w}::data d

 syncLimits $w
 expr {$d(minT)+$frac*($d(maxT)-$d(minT))}
}

# conversion: time to fraction
proc wavebar::t->frac {w t} {
 upvar [namespace current]::${w}::data d

 syncLimits $w
 if {$d(minT) == $d(maxT)} {return 0.0}
 expr {1.0*($t-$d(minT))/($d(maxT)-$d(minT))}
}

proc wavebar::_event {w evt x y} {
 upvar [namespace current]::${w}::data d

 if {!$d(isInteractive)} return

 switch -glob -- $evt {
  enter {
   #   $w.c0 configure -cursor hand 
  }
  down {
   set d(x0) $x
   $w.c0 itemconf slidertopshadow -fill $d(bottomShadow)
   $w.c0 itemconf sliderbottomshadow -fill $d(topShadow)
  }
  move {
   if {$x<$d(arrowWidth) || $x>$d(c0width)-$d(arrowWidth)} return
   set dxtime [expr {1.0*$d(maxT)*($x-$d(x0))/($d(c0width)-2*$d(arrowWidth))}]
   set d(x0) $x
   set d(time1) [expr {$d(time1)+$dxtime}]
   set d(time2) [expr {$d(time2)+$dxtime}]
   if {$d(time1)<$d(minT)} {
    set d(time2) [expr {$d(time2)-$d(time1)}]
    set d(time1) $d(minT)
   }
   if {$d(time2)>$d(maxT)} {
    set d(time1) [expr {$d(maxT)-$d(time2)+$d(time1)}]
    set d(time2) $d(maxT)
   }
   #<< dxtime=$dxtime
   #<< minT=$d(minT),maxT=$d(maxT)
   #<< time1=$d(time1),time2=$d(time2)
   if {$d(jump)} {
    _update $w
   } else {
    if {$d(command) != ""} {
     #<< "invoking command: $d(command) moveto [t->frac $w $d(time1)]"
     eval $d(command) moveto [t->frac $w $d(time1)]
    }
   }
  }
  up {
   $w.c0 itemconf slidertopshadow -fill $d(topShadow)
   $w.c0 itemconf sliderbottomshadow -fill $d(bottomShadow)
   if {$d(jump)} {
    if {$d(command) != ""} {
     eval $d(command) moveto [t->frac $w $d(time1)]
    }
   }
  }
  enterBar* {
   set n [string index $evt [expr {[string length $evt] - 1}]]
   $w.c0 itemconf bar${n}a -fill $d(bottomShadow)
   $w.c0 itemconf bar${n}b -fill $d(topShadow)
  }
  leaveBar* {
   set n [string index $evt [expr {[string length $evt] - 1}]]
   $w.c0 itemconf bar${n} -fill ""
  }
  downBar* {
   set n [string index $evt [expr {[string length $evt] - 1}]]
   $w.c0 configure -cursor sb_h_double_arrow
  }
  moveBar* {
   set zl [util::min $d(zoomlimit) [expr {$d(maxT)-$d(minT)}]]
   set n [string index $evt [expr {[string length $evt] - 1}]]
   set tt [x->t $w $x]
   if {$n==1} {
    set d(time1) [util::min $tt [expr {$d(time2)-$zl}]]
    set d(time1) [util::max $d(minT) $d(time1)]
    set d(time2) [util::max [expr {$d(time1)+$zl}] $d(time2)]
   } else {
    set d(time2) [util::max $tt [expr {$d(time1)+$zl}]]
    set d(time2) [util::min $d(maxT) $d(time2)]
    set d(time1) [util::min [expr {$d(time2)-$zl}] $d(time1)]
   }
   if {$d(zoomjump)} {
    _update $w
   } else {
    if {$d(zoomcommand) != ""} {
     eval $d(zoomcommand) [t->frac $w $d(time1)] [t->frac $w $d(time2)]
    }
   }
  }
  upBar* {
   $w.c0 configure -cursor ""
   if {$d(time1)>$d(time2)} {util::swap d(time1) d(time2)}
   if {$d(zoomjump)} {
    if {$d(zoomcommand) != ""} {
     eval $d(zoomcommand) [t->frac $w $d(time1)] [t->frac $w $d(time2)]
    }
   }
  }

  down2 {
   set d(fdown2) [x->t $w $x]
   set d(time1) $d(fdown2)
   set d(time2) $d(fdown2)
  }
  move2 {
   set f [x->t $w $x]
   if {$f>$d(fdown2)} {
    _event $w moveBar2 $x $y
   } else {
    _event $w moveBar1 $x $y
   }
   if 0 {
    if {$f>$d(fdown2)} {
     set d(time1) $d(fdown2)
     set d(time2) $f
    } else {
     set d(time1) $f
     set d(time2) $d(fdown2)
    }
    set d(time1) [util::min $d(maxT) [util::max $d(minT) $d(time1)]]
    set d(time2) [util::min $d(maxT) [util::max $d(minT) $d(time2)]]
    
    if {$d(zoomjump)} {
     _update $w
    } else {
     if {$d(zoomcommand) != ""} {
      eval $d(zoomcommand) $d(time1) $d(time2)
     }
    }
   }
  }
  up2 {
   if {$d(zoomjump)} {
    if {$d(zoomcommand) != ""} {
     eval $d(zoomcommand) [t->frac $w $d(time1)] [t->frac $w $d(time2)]
    }
   }
  }
  downArrow {
   _autoScroll $w arrow$x initial
   $w.c0 itemconfigure arrow$x -outline $d(bottomShadow) 
   $w.c0 itemconfigure arrow${x}shadow -fill $d(topShadow) 
  }
  upArrow {
   _buttonUp $w
   $w.c0 itemconfigure arrow$x -outline $d(topShadow) 
   $w.c0 itemconfigure arrow${x}shadow -fill $d(bottomShadow) 
  }
  downTrough {
   set d(x0) $x
   _autoScroll $w trough$x initial
  }
  upTrough {
   _buttonUp $w
  }
  zoomAll {
   set d(time1) 0.0
   set d(time2) $d(maxtime)
   if {$d(zoomcommand) != ""} {
    eval $d(zoomcommand) $d(time1) $d(time2)
   }
   $w.c0 configure -cursor ""
  }
 }
 _msgTime $w
}


proc wavebar::scroll {w number unit} {
#    puts [info level 0]
 upvar [namespace current]::${w}::data d

 if {$number > 0} {
  set number [expr {int(ceil($number))}]
 } else {
  set number [expr {int(floor($number))}]
 }

 set delta [expr {$d(time2)-$d(time1)}]
 switch $unit {
  units {set increment [expr {$number*$delta*.2}]}
  pages {set increment [expr {$number*$delta*.9}]}
 }
 set d(time1) [expr {$d(time1)+$increment}]
 set d(time2) [expr {$d(time2)+$increment}]
 if {$d(time1)<$d(minT)} {
  set d(time1) $d(minT)
  set d(time2) $delta
 }
 if {$d(time2)>$d(maxT)} {
  set d(time1) [expr {$d(maxT)-$delta}]
  set d(time2) $d(maxT)
 }
 if {$d(command) != ""} {
  eval $d(command) scroll $number $unit
 }
}
# this command is invoked by the scroll wheel zooming
# amount is how much the wheel has turned, relx is the
# position of the cursor relative to the width of the
# window. we want to center the zooming around that point.
proc wavebar::zoom {w amount relx} {
#    puts [info level 0]
    upvar [namespace current]::${w}::data d

    # delta - length of visible area
    set delta [expr {$d(time2)-$d(time1)}]
    # factor by which the visible area shrink or expand
    set factor [expr {pow(1.1667,$amount)}]
    # the cursor position translated into time
    set curpos [expr {$d(time1)+$delta*$relx}]

    set newt1 [expr {$curpos - $factor*($curpos-$d(time1))}]
    set newt2 [expr {$curpos + $factor*($d(time2)-$curpos)}]
    if {$newt1 < $d(minT)} {set newt1 $d(minT)}
    if {$newt2 > $d(maxT)} {set newt2 $d(maxT)}
    set d(time1) $newt1
    set d(time2) $newt2
    if {$d(zoomcommand) != ""} {
	eval $d(zoomcommand) [t->frac $w $d(time1)] [t->frac $w $d(time2)]
    }
}

proc wavebar::zoom-old {w number} {
 upvar [namespace current]::${w}::data d
 
 set delta [expr {$d(time2)-$d(time1)}]
 set increment [expr {(pow(1.1667,$number)-1)*$delta}]

 if {$delta + 2*$increment > $d(maxT)-$d(minT)} {
  # full zoom-out
  set d(time1) $d(minT)
  set d(time2) $d(maxT)
 } elseif {$d(time1) - $increment < $d(minT)} {
  # from beginning
  set d(time2) [expr $d(time2)+2*$increment+$d(minT)-$d(time1)]
  set d(time1) $d(minT)
 } elseif {$d(time2) + $increment > $d(maxT)} {
  # from end
  set d(time1) [expr $d(time1)-2*$increment+$d(maxT)-$d(time2)]
  set d(time2) $d(maxT)
 } else {
  # default case
  set d(time1) [expr {$d(time1)-$increment}]
  set d(time2) [expr {$d(time2)+$increment}]
 }
 if {$d(zoomcommand) != ""} {
  eval $d(zoomcommand) [t->frac $w $d(time1)] [t->frac $w $d(time2)]
 }
}

proc wavebar::setfracs {w f1 f2} {
 upvar [namespace current]::${w}::data d

 set d(time1) [frac->t $w $f1]
 set d(time2) [frac->t $w $f2]
 _update $w
}

proc wavebar::getfracs {w} {
 upvar [namespace current]::${w}::data d
 
 list [t->frac $w $d(time1)] [t->frac $w $d(time2)]
}

proc wavebar::_redrawSelection {w} {
 upvar [namespace current]::${w}::data d

 set xs1 -1; set xs2 -1
 if {$d(fsel1)>0 || $d(fsel2)>0} {
  set xs1 [t->x $w $d(fsel1)]
  set xs2 [t->x $w $d(fsel2)]
 }
 set y1 0
 set y2 [expr {$d(c0height)-1}] 
 $w.c0 coords selection $xs1 $y1 $xs2 $y1 $xs2 $y2 $xs1 $y2
}

proc wavebar::_redrawCursor {w} {
 upvar [namespace current]::${w}::data d

 set xc -1
 if {$d(cursorpos)>0} {
  set xc [t->x $w $d(cursorpos)]
 }
 set y1 0
 set y2 [expr {$d(c0height)-1}] 
 $w.c0 coords cursor $xc $y1 $xc $y2
}

proc wavebar::_redrawArrows w {
 upvar [namespace current]::${w}::data d

 set x0 0
 set x1 [expr {$d(arrowWidth)-1}]
 set x2 [expr {$d(c0width)-$d(arrowWidth)+1}]
 set x3 $d(c0width)
 set y0 0
 set y1 [expr {0.5*$d(c0height)}]
 set y2 $d(c0height)
 
 $w.c0 coords arrow1 $x0 $y1 $x1 $y0 $x1 $y2
 $w.c0 coords arrow1shadow $x0 $y1 $x1 $y2 $x1 $y0
 $w.c0 coords arrow2 $x2 $y0 $x3 $y1 $x2 $y2
 $w.c0 coords arrow2shadow $x2 $y2 $x3 $y1
}

proc wavebar::soundChanged {w} {
 upvar [namespace current]::${w}::data d
 
 $w syncLimits

 _update $w
}

proc wavebar::_update {w {width -1} {height -1}} {
 upvar [namespace current]::${w}::data d
 if {$width>0} {set d(c0width) $width}
 if {$height>0} {set d(c0height) $height}
 if {$d(c0width)<=0} return
 
 set x0 [t->x $w $d(minT)]
 set x1 [t->x $w $d(time1)]
 set x2 [t->x $w $d(time2)]
 set x3 [expr {$d(c0width)-$d(arrowWidth)}] ;# can't use maxT, might be 0.0
 set y1 1
 set y2 [expr {$d(c0height)-1}] 
 _redrawSelection $w
 _redrawCursor $w
 
 #<< x0=$x0
 #<< x1=$x1
 #<< x2=$x2
 #<< x3=$x3
 
 if {$d(isInteractive)} {
  $w.c0 coords slider $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2
  $w.c0 coords trough1 $x0 $y1 $x1 $y1 $x1 $y2 $x0 $y2
  $w.c0 coords trough2 $x2 $y1 $x3 $y1 $x3 $y2 $x2 $y2
  $w.c0 coords bar1a $x1 $d(c0height) $x1 0
  $w.c0 coords bar1b [expr {$x1-1}] $d(c0height) [expr {$x1-1}] 0
  $w.c0 coords bar2a $x2 $d(c0height) $x2 0
  $w.c0 coords bar2b [expr {$x2-1}] $d(c0height) [expr {$x2-1}] 0
  $w.c0 coords sliderfill $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2
  $w.c0 coords slidertopshadow $x1 $y2 $x1 $y1 $x2 $y1
  $w.c0 coords sliderbottomshadow $x2 $y1 $x2 $y2 $x1 $y2
  _redrawArrows $w
 } else {
  foreach item {bar1 bar2 sliderfill slidertopshadow sliderbottomshadow arrow1 arrow1shadow arrow2 arrow2shadow} {
   $w.c0 coords $item -1 -1 -1 -1 -1 -1
  }
 }
 if {1&&$d(sound) != ""} {
  if {$d(isrecording)} {
   if {$d(isInteractive) && $x0 == 0.0} {
    set x0 $d(arrowWidth)
   }
   $w.c0 coords waveform $x3 [expr {$d(c0height)*0.5}]
   $w.c0 itemconfigure waveform -anchor e -pixelspersecond 250 -width [expr {$x3-$x0}]
  } else {
   set xw0 [t->x $w 0.0]
   set xw1 [t->x $w [$d(sound) length -unit seconds]]
   $w.c0 coords waveform [t->x $w 0.0] [expr {$d(c0height)*0.5}]
   set wwidth [expr {$xw1-$xw0}]
   
   $w.c0 itemconfigure waveform -anchor w -width $wwidth \
     -height [expr {int($d(c0height)*0.8)}]
  }
 }
}
