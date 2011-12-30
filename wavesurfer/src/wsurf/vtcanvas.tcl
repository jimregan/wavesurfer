#
#  @COPYRIGHT@
#
# This file is part of the WaveSurfer package.
# The latest version can be found at http://sourceforge.net/projects/wavesurfer
#

package require surfutil
package provide wsurf 1.8

namespace eval vtcanvas {
 variable Info
# add -width?
 set Info(OptionTable) [list \
   -title           title              "" \
   -unit            unit               "" \
   -height          height             200 \
   -width           width              300 \
   -scrollheight    scrollHeight       200 \
   -yzoom           yzoom              1.0 \
   -scrolled        isScrolled         0 \
   -stipple         stipple            "" \
   -layer           layer              bottom \
   -fillcolor       fillColor          lightyellow \
   -framecolor      frameColor         orange \
   -cursorcolor     cursorColor        red \
   -cursorpos       cursorPos          "" \
   -closeenough     @canvas            3.0 \
   -relief          @canvas            flat \
   -bd              @canvas            1 \
   -background      @canvas:yaxis      "" \
   -xscrollcommand  @canvas            "" \
   -yscrollbar      yscrollbar         0 \
   -selectioncommand selectionCommand  {} \
   -selection       selection          {} \
   -cursorcommand   cursorCommand      {} \
   -redrawcommand   redrawCommand      {} \
   -yaxiswidth      yaxisWidth         40 \
   -showyaxis       showYaxis          false \
   -pixelspersecond pixelsPerSecond    400 \
   -minvalue        minVal             0.0 \
   -maxvalue        maxVal             0.0 \
   -maxtime         maxTime            0.0 \
   -mintime         minTime            0.0 \
   -bottommargin    bottomMargin       0 \
   -yaxiscolor      yaxisColor         black \
   -yaxisfont       yaxisFont          {Helvetica 8} \
   -displaylength   displaylength      1 \
   -formattimecommand formatTimeCommand {} \
   -state           state              normal \
 ]

 list {
  -yaxisrelief
 }

 set Info(Callbacks) [list selectionCommand cursorCommand redrawCommand \
     formatTimeCommand]
}

# -----------------------------------------------------------------------------

proc vtcanvas::create {w args} {
 variable Info
 namespace eval [namespace current]::$w {
  variable widgets
  variable data
 }
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 set d(selectionT0) 0.0
 set d(selectionT1) 0.0
 set d(xTimeDown) 0.0
 set d(canvasWidth) 0
 set wid(frame) [ttk::frame $w]


 set wid(top) $w.top
 rename $w ::$wid(top)
 proc ::$w {cmd args} "return \[eval vtcanvas::\$cmd $w \$args\]"
 
 set wid(canvas) [set c [::canvas $w.c -highlightthickness 0]]
    ttk::separator $w.ff -orient vertical

 set wid(yaxis) [::canvas $w.yaxis -highlightthickness 0 -width 0 -bd 1]
 set wid(yscrollbar) [scrollbar $w.ysb \
			   -relief raised -bd 1 -highlightthickness 0 \
			   -command [namespace code [list yscroll $w]]]

 set wid(ysb_filler) [frame $w.ysb.fill]
 bind $wid(ysb_filler) <Visibility> [list raise %W] 
 pack $wid(yaxis) -side left -fill y
 pack $w.ff -side left -fill y -ipadx 1
 pack $wid(canvas) -side right -expand 1 -fill both
  set wid(title) [label $w.title -relief solid -bd 1 -bg #ffff7f]

 foreach {opt key val} $Info(OptionTable) {
  if {[string match @* $key]} {
   foreach tkwid [split [string range $key 1 end] :] {
    if {[string match "-background" $opt] && $val == ""} continue
    $wid($tkwid) configure $opt $val
   }
  } else {
   set d($key) $val
  }
 }
 if {[string match unix $::tcl_platform(platform)]} {
  set d(yaxisFont) {Helvetica 10}
 }

 if {[string match macintosh $::tcl_platform(platform)] || \
	 [string match Darwin $::tcl_platform(os)]} {
  set d(yaxisFont) {Helvetica 10}
  set layer bottom
 } else {
  if {$d(layer) != "bottom"} {set layer top} else {set layer bottom}
 }
 $c create rectangle 0 0 0 0 -tags [list block $layer] \
   -stipple $d(stipple) \
   -fill $d(fillColor) -outline {}
 $c create line 0 0 0 0 -tags [list rightbar bar top] \
   -fill $d(frameColor)
 $c create line 0 0 0 0 -tags [list leftbar bar top] \
   -fill $d(frameColor)
 $c create line -1 -1 -1 -1 -fill $d(cursorColor) \
   -tags [list cursor timeCursor]

 eval configure $w $args

 $wid(canvas) configure \
  -yscrollcommand [namespace code [list yscrollcommand $w]]
  
 util::setClass $w Vtcanvas

 bind $wid(canvas) <Configure> [namespace code [list cfgEvent $w %w %h]]

 $c bind bar <Enter> [list $c configure -cursor sb_h_double_arrow]
 $c bind bar <Leave> [list $c configure -cursor {}]

 util::canvasbind $c leftbar <ButtonPress-1> \
   [namespace code [list selectionEvent $w <ButtonPress-1> leftbar %x %y %t]]
 util::canvasbind $c rightbar <ButtonPress-1> \
   [namespace code [list selectionEvent $w <ButtonPress-1> rightbar %x %y %t]]
 bind $c <ButtonPress-1> \
   [namespace code [list selectionEvent $w <ButtonPress-1> "" %x %y %t]]
 bind $c <Shift-ButtonPress-1> \
   [namespace code [list selectionEvent $w <Shift-ButtonPress-1> "" %x %y %t]]
 bind $c <B1-Motion> \
   [namespace code [list selectionEvent $w <B1-Motion> "" %x %y %t]]
 bind $c <ButtonRelease-1> \
   [namespace code [list selectionEvent $w <ButtonRelease-1> "" %x %y %t]]

 bind $c <Motion> [namespace code [list motionEvent $w %x %y]]
 bind $c <Leave>  [namespace code [list motionEvent $w -1 -1]]
 
 return $w
}

proc vtcanvas::invoke {w cmd args} {
 variable Info
 upvar [namespace current]::${w}::data d
 if {[lsearch $Info(Callbacks) $cmd]==-1} {
  error "no such command"
 }
 if {$d($cmd)==""} {
  return
 }
 eval $d($cmd) $args
}

proc vtcanvas::configure {w args} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 if {[llength $args]%2} {
  error "wrong # args, must be vtcanvas::configure ?option value?..."
 }
 foreach {opt key val} $Info(OptionTable) {
  set OptionMap($opt) $key
 }
 foreach {opt val} $args {
  if {![info exists OptionMap($opt)]} {
   error "unknown option \"$opt\""
  } else {
   switch -- $opt {
    -title {
     # think more about placement of title label...
     $wid(title) configure -text $val
     if {$val!=""} {
      bind $w <Enter> [list place $wid(title) -x 50 -y 0 -anchor nw]
      bind $w <Leave> [list place forget $wid(title)]
     } else {
      bind $w <Enter> ""
      bind $w <Leave> ""
     }
    }
    -height {
     set d(height) $val
     if {!$d(isScrolled)} {
      set d(scrollHeight) $val
     }
     $wid(frame).top configure $opt $val
    }
    -scrollheight {
     if {$d(isScrolled)} {
      set d(scrollHeight) $val
     }
     redraw $w
     invoke $w redrawCommand
    }
    -scrolled {
     set d(isScrolled) $val
     redraw $w
     invoke $w redrawCommand
    }
    -yzoom {
     set d(yzoom) $val
     if {$val > 1.0} {
      set d(isScrolled) 1
     }
     set d(scrollHeight) [expr {int($d(height)*$val)}]
     redraw $w
     invoke $w redrawCommand
    }
    -cursorcolor {
     $wid(canvas) itemconfigure cursor -fill $val
    }
    -cursorpos {
     set d(cursorPos) $val
     redraw $w
    }
    -selection {
     foreach {d(selectionT0) d(selectionT1)} $val break
     redraw $w
    }
    -layer {
     if {[string match macintosh $::tcl_platform(platform)] || \
	 [string match Darwin $::tcl_platform(os)]} {
      set val bottom
     }
     $wid(canvas) itemconfigure block -tags [list block $val]
     $wid(canvas) raise top
     $wid(canvas) lower bottom
     set d(layer) $val
    }
    -fillcolor {
     $wid(canvas) itemconfigure block -fill $val
    }
    -stipple {
     $wid(canvas) itemconfigure block -stipple $val
    }
    -framecolor {
     $wid(canvas) itemconfigure bar -fill $val
    }
    -maxheight {
     if {$d(scrollHeight) > -1} {
      set d(maxheight) [util::min \
	[expr {$d(scrollHeight)+2*[$w cget -bd]}] $val]
     }
    }
    -yaxiswidth {
     if {$val == 0} {
	 # $w.ff  configure -bd 0
      $w.yaxis configure -bd 0
     }
     $wid(yaxis) configure -width $val
    }
    -yscrollbar {
     if {$val} {
      pack $wid(yscrollbar) -fill y \
	-before [lindex [pack slaves $w] 0] -side right
      if {$d(scrollHeight) > $d(height)} {
       # if the scrollbar is desired, don't display the filler
       place forget $wid(ysb_filler)
      } else {
       # if not, hide scrollbar behind the filler
       place $wid(ysb_filler) -x 0 -y 0 -relwidth 1 -relheight 1
       raise $wid(ysb_filler)
      }
     } else {
      pack forget $wid(yscrollbar)
      place forget $wid(ysb_filler)
     }
     set d(yscrollbar) $val
    }
    -pixelspersecond {
     set d(pixelsPerSecond) $val
     redraw $w
    }
    -maxvalue {
     set d(maxVal) $val
     if {[string match $d(showYaxis) true]} {set drax 1}
    }
    -minvalue {
     set d(minVal) $val
     if {[string match $d(showYaxis) true]} {set drax 1}
    }
    -unit {
     set d($OptionMap($opt)) $val
     if {[string match $d(showYaxis) true]} {set drax 1}
    }
    -yaxiscolor {
     set d(yaxisColor) $val
     if {[string match $d(showYaxis) true]} {set drax 1}
    }
    -yaxisfont {
     set d(yaxisFont) $val
     if {[string match $d(showYaxis) true]} {set drax 1}
    }
    -state {
     set d(state) $val
    }
    default {
     if {[string match @* $OptionMap($opt)]} {
      foreach tkwid [split [string range $OptionMap($opt) 1 end] :] {
       $wid($tkwid) configure $opt $val
      }
     } else {
      set d($OptionMap($opt)) $val
     }
    }
   }
  }
 }
 if [info exists drax] {drawYAxis $w $wid(yaxis)}

}

proc vtcanvas::cget {w option} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 foreach {opt key val} $Info(OptionTable) {
  set OptionMap($opt) $key
 }

 switch -- $option {
  -framecolor {
   return [$wid(canvas) itemcget bar -fill]
  }
  -cursorcolor {
   return [$wid(canvas) itemcget cursor -fill]
  }
  -cursorpos {
   return $d(cursorPos)
  }
  -selection {
   return [list $d(selectionT0) $d(selectionT1)]
  }
  -fillcolor {
   return [$wid(canvas) itemcget block -fill]
  }
  -stipple {
   return [$wid(canvas) itemcget block -stipple]
  }
  -width {
   return $d(canvasWidth)
  }
  default {
   if {[string match @* $OptionMap($option)]} {
    set tkwid [lindex [split [string range $OptionMap($option) 1 end] :] 0]
    $wid($tkwid) cget $option
   } else {
    set d($OptionMap($option))
   }
  }
 }
}

# -----------------------------------------------------------------------------
# getConfiguration - get configuration of the vtcanvas as Tcl code
# Only creates output for options which differ from the defaults

proc vtcanvas::getConfiguration {w} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 foreach {opt key val} $Info(OptionTable) {
  set OptionDefault($opt) $val
 }
 foreach option {-title -unit -height -scrollheight -scrolled -stipple \
	 -layer -fillcolor -framecolor -cursorcolor -closeenough -relief \
	 -bd -background -yscrollbar -yaxiswidth -showyaxis \
	 -yaxiscolor -yaxisfont -bottommargin -displaylength} {
  set val [vtcanvas::cget $w $option]
  if {[string compare $OptionDefault($option) $val] == 0} continue
       append result "\$pane configure $option \{$val\}\n"
 }
 return $result
}

# -----------------------------------------------------------------------------

proc vtcanvas::yscroll {w args} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d
 
 eval $wid(canvas) yview $args
 eval $wid(yaxis)  yview $args
}

# -----------------------------------------------------------------------------
# yscrollcommand - bound to -yscrollcommand of the vtcanvas's main canvas

proc vtcanvas::yscrollcommand {w frac0 frac1} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 if {$d(scrollHeight)>$d(height)} {
  $wid(yscrollbar) set $frac0 $frac1
 }
}

# -----------------------------------------------------------------------------

proc vtcanvas::frac->t {w frac} {
 upvar [namespace current]::${w}::data d

 expr {$d(mintime)+$frac*($d(maxtime)-$d(mintime))}
}

proc vtcanvas::t->frac {w frac} {
 upvar [namespace current]::${w}::data d
 if {$d(mintime) == $d(maxtime)} {return 0.0}
 expr {1.0*($t-$d(mintime))/($d(maxtime)-$d(mintime))}
}

# -----------------------------------------------------------------------------
# cfgEvent - bound to Configure-event of each vtcanvas's main canvas 
# move this back to wsurf?
proc vtcanvas::cfgEvent {w cwidth cheight} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 set d(canvasWidth) $cwidth
 set d(height) $cheight
 set d(scrollHeight) [expr {int($d(height)*$d(yzoom))}]

 redraw $w
 invoke $w redrawCommand

 if {[string match $d(showYaxis) true]} {
  drawYAxis $w $wid(yaxis)
 }
}

# -----------------------------------------------------------------------------

proc vtcanvas::redraw {w} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 set c [$w canvas]

 # update the selection
 set t0 $d(selectionT0)
 set t1 $d(selectionT1)
 if {$t0=="" || $t1==""} {
  $c coords block -1 -1 -1 -1
  $c coords leftbar -1 -1 -1 -1
  $c coords rightbar -1 -1 -1 -1
 } else {
  set height [util::max $d(scrollHeight) $d(height)]
  set x0 [getCanvasX $w $t0]
  set x1 [getCanvasX $w $t1]
  $c coords block $x0 0 $x1 $height
  $c coords leftbar $x0 0 $x0 $height
  $c coords rightbar $x1 0 $x1 $height
  $c raise top
  $c lower top topmost
  $c raise selbg
  $c raise sellen
  $c lower bottom
 }

 # update the cursor
 set ct $d(cursorPos)
 if {$ct==""} {
  $c coords timeCursor -1 -1 -1 -1
 } else {
  set x [getCanvasX $w $ct]
  $c coords timeCursor $x 0 $x $d(scrollHeight)
#  $c raise timeCursor
 }
}

# -----------------------------------------------------------------------------

proc vtcanvas::storeSelection {w t0 t1} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 set d(selectionT0) [util::max $d(minTime) \
     [util::min $d(maxTime) [util::min $t0 $t1]]]
 set d(selectionT1) [util::min $d(maxTime) [util::max $t0 $t1]]
}

# -----------------------------------------------------------------------------

proc vtcanvas::selectionEvent {w event item x y t} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 set c  [$w canvas]
 set xc [$c canvasx $x]
 if {$d(pixelsPerSecond) == 0 || [string equal "normal" $d(state)] == 0} return
 set xtime [expr {$xc/double($d(pixelsPerSecond))}]
 if {[string match <*ButtonPress-1> ${event}] && $d(displaylength)} {
   $c create rectangle -1 -1 -1 -1 -fill $d(frameColor) -tags selbg
   $c create text 0 0 -tags sellen -text "" -anchor w -font $d(yaxisFont)
 }
 switch ${event}${item} {
  <ButtonPress-1>leftbar {
   focus $c
   set d(xTimeDown) $d(selectionT1)
   storeSelection $w $d(xTimeDown) $xtime
   set d(workAround83+bug) 1
  }
  <ButtonPress-1>rightbar {
   focus $c
   set d(xTimeDown) $d(selectionT0)
   storeSelection $w $xtime $d(xTimeDown)
   set d(workAround83+bug) 1
  }
  <ButtonPress-1> {
   focus $c
   set d(xTimeDown) $xtime
   storeSelection $w $d(xTimeDown) $xtime
   set d(workAround83+bug) 1
   set Info(downTime) $t
  }
  <B1-Motion> {
   if {![info exists d(workAround83+bug)]} return
   storeSelection $w $d(xTimeDown) $xtime

   set my [$c canvasy $y]
   if {$my < 10} { set my 10 }
   if {$my > $d(height)-10} { set my [expr {$d(height)-10}] }
   set dt [expr {abs($xtime - $d(xTimeDown))}]
   set text [invoke $w formatTimeCommand $dt]
   $c itemconf sellen -text $text
   set he [font metrics $d(yaxisFont) -linespace]
   if {$x < 100} {
    $c coord sellen [expr $xc+2] $my
     $c itemconf sellen -anchor sw
     set wi [font measure $d(yaxisFont) $text]
    $c coords selbg $xc $my [expr {$xc + $wi + 4}] [expr {$my - $he}]
   } else {
    $c coord sellen [expr $xc-2] $my
     $c itemconf sellen -anchor se
     set wi [expr -[font measure $d(yaxisFont) $text]]
    $c coords selbg $xc $my [expr {$xc + $wi - 4}] [expr {$my - $he}]
   }

  }
  <ButtonRelease-1> {
   if {[info exists d(workAround83+bug)]} {unset d(workAround83+bug)}
   if {[info exists Info(downTime)]} {
     if {[expr $t - $Info(downTime)] < 100} {
       storeSelection $w $d(xTimeDown) $d(xTimeDown)
     }
   }
   $c delete sellen selbg
  }
  <Shift-ButtonPress-1> {
   focus $c
   set d(workAround83+bug) 1
   if {abs($xtime-$d(selectionT0)) < abs($xtime-$d(selectionT1))} {
    set d(xTimeDown) $d(selectionT1)
    storeSelection $w $xtime $d(selectionT1)
   } else {
    set d(xTimeDown) $d(selectionT0)
    storeSelection $w $d(selectionT0) $xtime
   }
  }
  default {error "bad event \"$event\""}
 }
 redraw $w
 invoke $w selectionCommand $d(selectionT0) $d(selectionT1) \
	 [$c canvasx $x] $event
 motionEvent $w $x $y
}

proc vtcanvas::motionEvent {w x y} {
 upvar [namespace current]::${w}::data d

    set d(curX) $x
    set d(curY) $y

 set c [$w canvas]
 set cx [$c canvasx $x]
 set cy [$c canvasy $y]
 set t [getTime $w $cx]
 set v [getValue $w $cy]
 invoke $w cursorCommand $cx $cy $t $v
}

# -----------------------------------------------------------------------------
# conversion routines to go between real world and canvas coordinates
 
proc vtcanvas::getTime {w canvasX} {
 upvar [namespace current]::${w}::data d

 expr {double($canvasX)/$d(pixelsPerSecond)}
}


# -----------------------------------------------------------------------------

proc vtcanvas::getCanvasX {w time} {
 upvar [namespace current]::${w}::data d
 
 expr {double($time)*$d(pixelsPerSecond)}
}

# -----------------------------------------------------------------------------

proc vtcanvas::getValue {w canvasY} {
 upvar [namespace current]::${w}::data d

 set canvLower [$w cget -scrollheight]
 set canvUpper 0
 expr {
  $d(minVal) + ($canvasY-$canvLower) * ($d(maxVal)-$d(minVal)) / \
    double($canvUpper-$canvLower)
 }
}

# -----------------------------------------------------------------------------

proc vtcanvas::getCanvasY {w value} {
 upvar [namespace current]::${w}::data d

 set canvLower [$w cget -scrollheight]
 set canvUpper 0
 if {$d(maxVal)==$d(minVal)} {return .0}
 expr {
     $d(bottomMargin)+$canvLower + ($canvUpper-$canvLower)*\
	 (double($value)-$d(minVal))/double($d(maxVal)-$d(minVal))
 }
}

proc vtcanvas::getCurX {w} {
    upvar [namespace current]::${w}::data d
    return $d(curX)
}

proc vtcanvas::getCurY {w} {
    upvar [namespace current]::${w}::data d
    return $d(curY)
}

proc vtcanvas::yaxis {w} {
 upvar [namespace current]::${w}::widgets wid
 return $wid(yaxis)
}

proc vtcanvas::canvas {w} {
 upvar [namespace current]::${w}::widgets wid
 return $wid(canvas)
}

proc vtcanvas::ysbNeeded {w} {
 upvar [namespace current]::${w}::data d

 if {$d(scrollHeight)>$d(height)} {return 1} else {return 0}
}

proc vtcanvas::print {w canvas x y} {
 set topval [$w getValue 0]
 if {$topval > 0} {
  drawYAxis $w $canvas $x $y print
 }
}

# -----------------------------------------------------------------------------

proc vtcanvas::drawTitle {w title} {
 upvar [namespace current]::${w}::widgets wid
 set c $wid(yaxis)
 set width [winfo width $c]
 set height [$w cget -scrollheight]
 $c delete _title
 $c create text [expr {$width/2}] [expr {$height/2}] -text $title -tag _title
}

proc vtcanvas::_tick {n} {
 expr {[lindex {1 2 5} [expr {$n%3}]]*pow(10,($n-15)/3)}
}

proc vtcanvas::drawYAxis {w canvas {x 0} {y 0} {tags yaxis}} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d
 
 set font  [$w cget -yaxisfont]
 set maxval [$w cget -maxvalue]
 set minval [$w cget -minvalue]
 set fill  [$w cget -yaxiscolor]
 set unit  [$w cget -unit]
 set width  [$w cget -yaxiswidth]
 set height [$w cget -scrollheight]
 set valPerTick 0.00001

 if {$maxval == $minval} return
 #<< "maxval = $maxval, minval = $minval"
 set dy [expr {double($height * $valPerTick) / ($maxval - $minval)}]

 if {[string match $tags yaxis]} {
  $canvas delete $tags
#  $canvas create rectangle $x $y [expr {$x+$width}] [expr {$y+$height}] \
#	  -fill white -tags $tags
 }
 if {[string match $tags print]} {
  $canvas create rectangle $x $y [expr {$x+$width}] [expr {$y+$height}] \
	  -fill white -tags print -outline $fill
 }

 # Choose reasonable vertical tick spacing (at least text height)

 set linespace [font metrics $font -linespace]
 set i 0
 while {$dy < $linespace} {
  for {} {1} {incr i} {
   if {[_tick $i] <= $valPerTick} continue
   set valPerTick [_tick $i]
   break
  }
  set dy [expr {double($height * $valPerTick) / ($maxval - $minval)}]
 }

 # Prepend 'k' to unit name if scaling made this necessary

 if {$valPerTick < 1000 || $unit == ""} { 
  set hztext $unit
 } else {
  set hztext k$unit
 }

 if {$minval >= 0.0} {
  set jstart [expr {int($minval / $valPerTick) + 1}]
 } else {
   set jstart [expr {int($minval / $valPerTick)}]
 }

 set ascent [font metrics $font -ascent]
 set ystart [expr {$dy*(double($valPerTick)*$jstart - $minval) / $valPerTick}]

 for {set i $ystart;set j $jstart} {$i < $height} \
	 {set i [expr {$i + $dy}];set j [expr {$j+1.0}]} {
  set yc [expr {$height + $y - $i}]

  if {$valPerTick >= 1.0} {
   if {$valPerTick < 1000} { 
    set time [expr {int($j * $valPerTick)}]
   } else {
    set time [expr {int($j * $valPerTick / 1000)}]
   }
  } else {
   set time [expr {$j * $valPerTick}]
  }
  if {$yc > [expr {8 + $y}]} {
   if {[expr {$yc - $ascent}] > [expr {$y + $linespace}] ||
       [font measure $font $hztext]  < \
       [expr {$width - 8 - [font measure $font $time]}]} {
    $canvas create text [expr {$x + $width - 8}] [expr {$yc-2}] -text $time \
      -font $font -anchor e -tags $tags -fill $fill
   }  
   $canvas create line [expr {$x + $width - 5}] $yc [expr {$x + $width}] \
    $yc -tags $tags -fill $fill
  }
 }

 $canvas create text [expr {$x + 2}] [expr {$y +1}] -text $hztext -font $font \
   -anchor nw -tags $tags -fill $fill

 return $valPerTick
}

# test the widget

proc vtcanvas::Test {} {
 variable Info

 toplevel .x
 set w .x.p
 pack [vtcanvas::create $w] -expand 1 -fill both
 
 foreach {opt key val} $Info(OptionTable) {

 }
 vtcanvas::configure $w -maxtime 10
 vtcanvas::configure $w -showyaxis true
 vtcanvas::configure $w -minvalue 1
 vtcanvas::configure $w -maxvalue 10
 vtcanvas::configure $w -stipple gray25
 vtcanvas::configure $w -cursorcolor blue
 vtcanvas::configure $w -framecolor green
 vtcanvas::configure $w -background orange
 vtcanvas::configure $w -fillcolor white
 vtcanvas::configure $w -yaxiswidth 40
 vtcanvas::configure $w -pixelspersecond 400
 vtcanvas::configure $w -selectioncommand "puts stdout selectioncommand; concat"
 package require snack
 sound s -load ex1.wav
 set c [$w canvas]
 $c create waveform 0 0 -sound s -pixelspersecond 400
 pack [scale .s1 -label maxv -from -21 -to 40 -resolution .1 -command [list vtcanvas::configure $w -maxvalue]]
 pack [scale .s2 -label minv -from -20 -to 40 -resolution .1 -command [list vtcanvas::configure $w -minvalue]]
}

#vtcanvas::Test

