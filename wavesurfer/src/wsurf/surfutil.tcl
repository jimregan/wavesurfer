#
#  @COPYRIGHT@
#
# This file is part of the WaveSurfer package.
# The latest version can be found at http://sourceforge.net/projects/wavesurfer
#

package provide surfutil 1.8

namespace eval util {}

# i18n
proc util::mcload {} {
 # load language files, stored in either ~/.wavesurfer/$version/msgs/ or
 # in msgs/ subdirectories
 if {[info exists ::version] && \
   [file exists [file join $::env(HOME) .wavesurfer $::version msgs]]} {
  ::msgcat::mcload [file join $::env(HOME) .wavesurfer $::version msgs]
 } else {
  ::msgcat::mcload [file join [file dirname [info script]] msgs]
 }
}

if {[lsearch [package names] msgcat] != -1} {
  namespace eval util {
    package require msgcat

   # Possible place to hard code the locale
   # ::msgcat::mclocale se

   util::mcload
  }
}

# -----------------------------------------------------------------------------
# Miscellaneous utility procedures
# -----------------------------------------------------------------------------

proc util::min {a b} {if {$a<$b} {set a} else {set b}}

# -----------------------------------------------------------------------------

proc util::max {a b} {if {$a>$b} {set a} else {set b}}

# -----------------------------------------------------------------------------
# setmin (setmax) - set variable var to val if val is less than (greater than) 
#                   the current value of var or if var doesn't exist

proc util::setmin {var val} {
 upvar $var a
 if {![info exists a] || $val<$a} {set a $val} else {set a}
}

# -----------------------------------------------------------------------------

proc util::setmax {var val} {
 upvar $var a
 if {![info exists a] || $a<$val} {set a $val} else {set a}
}

# -----------------------------------------------------------------------------

proc util::swap {a b} {
 upvar $a x
 upvar $b y

 set tmp $x
 set x $y
 set y $tmp
}

# -----------------------------------------------------------------------------

proc util::zpad {str n} {
 
 set res [string trim $str]
 while {[string length $res]<$n} {set res "0$res"}
 return $res
}

# -----------------------------------------------------------------------------
# note: tcl8.3 allows "clock clicks -milliseconds"

switch $tcl_platform(platform) {
 windows {
  proc util::milliseconds { } {clock clicks}
 }
 unix {
  proc util::milliseconds { } {expr {[clock clicks]/1000}}
 }
}

# -----------------------------------------------------------------------------
# canvasbind
# - this proc creates canvas item bindings that, when invoked,
#   temporarily disables any widget bindings for the given event sequence

proc util::canvasbind {w tag seq script} {
 $w bind $tag $seq [namespace code "_rebind $w $seq\n_rebind Canvas $seq\n$script"]
}

proc util::_rebind {tag seq} {
#    puts [info level 0]
    bind $tag $seq [namespace code [list bind $tag $seq [_getbind $tag $seq]]]
}

proc util::_getbind {tag seq} {
 regsub -all {%} [bind $tag $seq] {%%} b
 return $b
} 



proc util::doOnce {cmd} {
 
 after cancel $cmd
 after idle $cmd
}


# canvasbind
# - this proc creates canvas item bindings that, when invoked,
#   temporarily disables any widget bindings for the given event sequence
#proc util::canvasbind {w tag seq script} {
#
# set cmd1 "bind $w $seq \"bind $w $seq \{\[bind $w $seq\]\}\""
# set cmd2 "bind Canvas $seq \"bind Canvas $seq \{\[bind Canvas $seq\]\}\""
# $w bind $tag $seq "$cmd1\n$cmd2\n$script"
#}
# -----------------------------------------------------------------------------

proc util::tmpdir {} {

 switch -glob [string tolower $::tcl_platform(platform)] {
  unix {set dir "/tmp"}
  win* {
   if {[info exists ::env(TEMP)] && $::env(TEMP) != ""} {
    set dir $::env(TEMP)
   } elseif {[info exists ::env(TMP)] && $::env(TMP) != ""} {
    set dir $::env(TMP)
   } else {
    set dir ""
   }
  }
  macintosh {
   set dir .
  }
  default {
   error "unknown platform $::tcl_platform(platform)"
  }
 }
 return $dir
}

# -----------------------------------------------------------------------------

proc util::wrapload {filename} {
 
 set f [open $filename]
 fconfigure $f -encoding binary -translation binary
 set data [read $f]
 close $f
 set fname2 [file join [tmpdir] load-[pid][file extension $filename]]
 set f [open $fname2 w]
 fconfigure $f -encoding binary -translation binary
 puts -nonewline $f $data
 close $f
 ::_load $fname2
 file delete $fname2
}

# -----------------------------------------------------------------------------

proc util::freewrapversion {} {
 if {[info exists ::freewrap::patchLevel]} {
  return [lindex [split $::freewrap::patchLevel abcdefghijklmnopqrstuvxyz] 0]
 } else {
  return 0
 }
}

# -----------------------------------------------------------------------------

proc util::setClass {w megaclass} {

 set class [lindex [bindtags $w] 1]
 bindtags $w [list $w $megaclass $class [winfo toplevel $w] all]
 foreach subw [winfo children $w] {
  setClass $subw $megaclass
 }
}

# -----------------------------------------------------------------------------

proc util::RGBscan {col} {
 switch [string length $col] {
  4 {scan $col "#%1x%1x%1x" r g b; set maxval 15}
  7 {scan $col "#%2x%2x%2x" r g b; set maxval 255}
  10 {scan $col "#%3x%3x%3x" r g b; set maxval 4095}
  13 {scan $col "#%4x%4x%4x" r g b; set maxval 65535}
 }
 if {![info exists b]} {error "color must be on #RGB format"}
 list [expr {1.0*$r/$maxval}] [expr {1.0*$g/$maxval}] [expr {1.0*$b/$maxval}]
}

proc util::RGBget {col} {
 foreach {r g b} [winfo rgb . $col] break
 list [expr {1.0*$r/65535}] [expr {1.0*$g/65535}] [expr {1.0*$b/65535}]
}

proc util::RGBformat {r g b} {
 set res #
 foreach c [list $r $g $b] {
  set cc [expr {int($c*65535)}]
  append res [zpad [string trim [format %4x $cc]] 4]
 }
 return $res
}

proc util::RGBbottomShadow {col} {

 foreach {r g b} [RGBget $col] break
 if {0.5*$r*$r + 1.0*$g*$g + 0.28*$b*$b < 0.05} {
  RGBformat [expr {(1+3*$r)/4}] [expr {(1+3*$g)/4}] [expr {(1+3*$b)/4}]
 } else {
  RGBformat [expr {0.6*$r}] [expr {0.6*$g}] [expr {0.6*$b}]
 }
}

proc util::RGBtopShadow {col} {

 foreach {r g b} [RGBget $col] break
 if {$g > 0.95} {
  RGBformat [expr {0.9*$r}] [expr {0.9*$g}] [expr {0.9*$b}]
 } else {
  set r2 [max [min 1.0 [expr {1.4*$r}]] [expr {(1.0+$r)/2}]]
  set g2 [max [min 1.0 [expr {1.4*$g}]] [expr {(1.0+$g)/2}]]
  set b2 [max [min 1.0 [expr {1.4*$b}]] [expr {(1.0+$b)/2}]]
  RGBformat $r2 $g2 $b2
 }
}

# -----------------------------------------------------------------------------

proc util::RGBintensity {col f} {
# puts [info level 0]
 if {$f>1 || $f<-1} {
  error "factor must lie between -1 (black) and 1 (white)"
 }
 foreach {r g b} [RGBget $col] break

 if {$f < 0.0} {
  RGBformat [expr {$r*(1+$f)}] [expr {$g*(1+$f)}] [expr {$b*(1+$f)}]
 } else {
  RGBformat [expr {$r+(1-$r)*$f}] [expr {$g+(1-$g)*$f}] [expr {$b+(1-$b)*$f}]
 }
}

# -----------------------------------------------------------------------------

proc util::guesslinuxsession {} {
    if [string match *gnome-session* [exec ps -e]] {
	return gnome
    }
    if [string match *ksm-server* [exec ps -e]] {
	return kde
    }
    return unknown
}

# -----------------------------------------------------------------------------

proc util::showURL url {

    # open url in preferred browser...
    
    switch -glob $::tcl_platform(platform)-$::tcl_platform(os) {
	unix-Linux {
	    switch [guesslinuxsession] {
		gnome {exec gnome-open $url}
		kde {exec kde-open $url}
		default {exec xdg-open $url}
	    }
	}
	unix-Darwin {
	    exec open $url
	} 
	windows-* {	
	    exec $::env(COMSPEC) /c start $url &
	}
	default {
	    webBrowser $url
	}
    }
}
    

proc util::webBrowser {url} {
 catch {destroy .htmlbrowser}
 toplevel .htmlbrowser
 # pack [button .htmlbrowser.back -command util::webBrowserBack -text Back]
 pack [scrollbar .htmlbrowser.sb -orient vert \
   -command [list .htmlbrowser.t yview]] -side right -fill y 
 pack [text .htmlbrowser.t -width 110 -height 40 -yscrollcommand \
   [list .htmlbrowser.sb set]] -side right -expand true -fill both
 
 variable currentUrl $url
 variable urlStack {}
 
 package require http
 
 proc ::HMset_image {.htmlbrowser.t handle src junk} {
  set tmp [lreplace [split $::util::currentUrl /] end end]
  set src [join $tmp /]/$src
  if [string match file:* $src] {
   set filename [string range $src 5 end]
  } else {
   set filename "_temp.gif"
   set fileid [open $filename "w"]
   http::wait [http::geturl $src -channel $fileid]
   close $fileid
  }
  set image [image create photo -file $filename]
  HMgot_image $handle $image
  file delete _temp.gif
  #  image delete $image
 }
 
 proc ::HMlink_callback {win href} {
  switch -glob $href {
   "#*" {
    HMgoto .htmlbrowser.t [string trim $href #]
    return
   }
   mailto* {
    return
   }
   http* {
    set util::currentUrl $href
    set url $href
   }
   /* -
   ../* {
    set pathlist [split $::util::currentUrl /]
    set tmp [lreplace $pathlist [expr [llength $pathlist]-2] end]
    set url [join $tmp /]/[string trimleft $href ./]
   }
   *.html {
    set tmp [lreplace [split $::util::currentUrl /] end end]
    set url [join $tmp /]/$href
   }
   *.php* {
    set tmp [lreplace [split $::util::currentUrl /] end end]
    set url [join $tmp /]/$href
   }
   */ {
    set url [join $url /]/index.html
   }
   default {
    return
   }
  }
  util::webBrowserGoURL $url
 }
 HMinit_win .htmlbrowser.t
 util::webBrowserGoURL $url
}

proc util::webBrowserGoURL {url} {
 lappend ::util::urlStack $url
 if [string match file:* $url] {
#  puts "local url:<$url>"
  set filename [string range $url 5 end]
  set fd [open $filename]
  set data [read $fd]
  close $fd
 } else {
#  puts "global url:<$url>"
  set token [::http::geturl $url]
 }
 .htmlbrowser.t conf -state normal
 HMreset_win .htmlbrowser.t
 HMinit_win .htmlbrowser.t
 if {![info exists data]} {
  set data [::http::data $token]
 }
 HMparse_html $data "::HMrender .htmlbrowser.t"
 if {[winfo exists .htmlbrowser.t]} {
  .htmlbrowser.t conf -state disabled
 }
}

proc util::webBrowserBack {} {
 if {[llength $::util::urlStack] > 1} {
  set ::util::urlStack [lreplace $::util::urlStack end end]
 }
 set url [lindex $::util::urlStack end]
 util::webBrowserGoURL $url
}

proc util::formatTime {t maxtime args} {
 if {$args == ""} {
   set fmt %.3f
 } else {
   set fmt $args
 }
 set dec [string trimleft [format $fmt [expr {$t-int($t)}]] 0]
 if {$dec == 1} {
   set t [expr {$t + 1.0}]
 }
 if {$maxtime < 60} {
  set tmp [clock format [expr {int($t)}] -format "%S" -gmt 1]
 } elseif {$maxtime < 3600} {
  set tmp [clock format [expr {int($t)}] -format "%M:%S" -gmt 1]
 } else {
  set tmp [clock format [expr {int($t)}] -format "%H:%M:%S" -gmt 1]
 }
 if {$dec == 1} {
   set tmp ${tmp}[string trimleft [format $fmt 0.0] 0]
 } else {
   set tmp ${tmp}$dec
 }

 return $tmp
}

proc util::mc {message} {
  if {[info procs ::msgcat::mc] != ""} {
    ::msgcat::mc $message
  } else {
    set message
  }
}

proc util::mcmax {args} {
 if {[info procs ::msgcat::mc] != ""} {
  eval ::msgcat::mcmax $args
 } else {
  set len 0
  foreach str $args {
   set len [max $len [string length $str]]
  }
  return $len
 }
}

proc util::chooseColor {colorVar {label ""}} {
 upvar $colorVar color
 set res [eval tk_chooseColor -initialcolor $color]
 if {$res != ""} {
  set color $res
  if {$label != ""} {
   $label configure -bg $res
  }
 }
}


proc util::foreachSubWindow {root script} {
    regsub -all $script 
    foreach win [win ...]
}


# bgerror.tcl --
#
#	Implementation of the bgerror procedure.  It posts a dialog box with
#	the error message and gives the user a chance to see a more detailed
#	stack trace, and possible do something more interesting with that
#	trace (like save it to a log).  This is adapted from work done by
#	Donal K. Fellows.
#
# Copyright (c) 1998-2000 by Ajuba Solutions.
# Copyright (c) 2007 by ActiveState Software Inc.
# Copyright (c) 2007 Daniel A. Steffen <das@users.sourceforge.net>
# 
# RCS: @(#) $Id$
# $Id$

package require Tk

namespace eval ::tk::dialog::error {
    namespace import -force ::tk::msgcat::*
    namespace export bgerror
    option add *ErrorDialog.function.text [mc "Save To Log"] \
	widgetDefault
    option add *ErrorDialog.function.command [namespace code SaveToLog]
    option add *ErrorDialog*Label.font TkCaptionFont widgetDefault
    if {[tk windowingsystem] eq "aqua"} {
	option add *ErrorDialog*background systemAlertBackgroundActive \
		widgetDefault
	option add *ErrorDialog*info.text.background white widgetDefault
	option add *ErrorDialog*Button.highlightBackground \
		systemAlertBackgroundActive widgetDefault
    }
}

proc ::tk::dialog::error::Return {} {
    variable button

    .bgerrorDialog.ok configure -state active -relief sunken
    update idletasks
    after 100
    set button 0
}

proc ::tk::dialog::error::Details {} {
    set w .bgerrorDialog
    set caption [option get $w.function text {}]
    set command [option get $w.function command {}]
    if { ($caption eq "") || ($command eq "") } {
	grid forget $w.function
    }
    lappend command [$w.top.info.text get 1.0 end-1c]
    $w.function configure -text $caption -command $command
    grid $w.top.info - -sticky nsew -padx 3m -pady 3m
}

proc ::tk::dialog::error::SaveToLog {text} {
    if { $::tcl_platform(platform) eq "windows" } {
	set allFiles *.*
    } else {
	set allFiles *
    }
    set types [list	\
	    [list [mc "Log Files"] .log]	\
	    [list [mc "Text Files"] .txt]	\
	    [list [mc "All Files"] $allFiles] \
	    ]
    set filename [tk_getSaveFile -title [mc "Select Log File"] \
	    -filetypes $types -defaultextension .log -parent .bgerrorDialog]
    if {![string length $filename]} {
	return
    }
    set f [open $filename w]
    puts -nonewline $f $text
    close $f
}

proc ::tk::dialog::error::Destroy {w} {
    if {$w eq ".bgerrorDialog"} {
	variable button
	set button -1
    }
}

# ::tk::dialog::error::bgerror --
# This is the default version of bgerror.
# It tries to execute tkerror, if that fails it posts a dialog box containing
# the error message and gives the user a chance to ask to see a stack
# trace.
# Arguments:
# err -			The error message.

proc ::tk::dialog::error::bgerror err {
    global errorInfo tcl_platform
    variable button

    set info $errorInfo

    set ret [catch {::tkerror $err} msg];
    if {$ret != 1} {return -code $ret $msg}

    # Ok the application's tkerror either failed or was not found
    # we use the default dialog then :
    set windowingsystem [tk windowingsystem]
    if {$windowingsystem eq "aqua"} {
	set ok [mc Ok]
    } else {
	set ok [mc OK]
    }

    # Truncate the message if it is too wide (>maxLine characters) or
    # too tall (>4 lines).  Truncation occurs at the first point at
    # which one of those conditions is met.
    set displayedErr ""
    set lines 0
    set maxLine 45
    foreach line [split $err \n] {
	if { [string length $line] > $maxLine } {
	    append displayedErr "[string range $line 0 [expr {$maxLine-3}]]..."
	    break
	}
	if { $lines > 4 } {
	    append displayedErr "..."
	    break
	} else {
	    append displayedErr "${line}\n"
	}
	incr lines
    }

    set title [mc "Application Error"]
    set text [mc "Error: %1\$s" $displayedErr]
    set buttons [list ok $ok dismiss [mc "Skip Messages"] \
		     function [mc "Details >>"]]

    # 1. Create the top-level window and divide it into top
    # and bottom parts.

    set dlg .bgerrorDialog
    destroy $dlg
    toplevel $dlg -class ErrorDialog
    wm withdraw $dlg
    wm title $dlg $title
    wm iconname $dlg ErrorDialog
    wm protocol $dlg WM_DELETE_WINDOW { }

    if {$windowingsystem eq "aqua"} {
	::tk::unsupported::MacWindowStyle style $dlg moveableAlert {}
    }

    frame $dlg.bot
    frame $dlg.top
    if {$windowingsystem eq "x11"} {
	$dlg.bot configure -relief raised -bd 1
	$dlg.top configure -relief raised -bd 1
    }
    pack $dlg.bot -side bottom -fill both
    pack $dlg.top -side top -fill both -expand 1

    set W [frame $dlg.top.info]
    text $W.text -setgrid true -height 10 -wrap char \
	-yscrollcommand [list $W.scroll set]
    if {$windowingsystem ne "aqua"} {
	$W.text configure -width 40
    }

    scrollbar $W.scroll -command [list $W.text yview]
    pack $W.scroll -side right -fill y
    pack $W.text -side left -expand yes -fill both
    $W.text insert 0.0 "$err\n$info"
    $W.text mark set insert 0.0
    bind $W.text <ButtonPress-1> { focus %W }
    $W.text configure -state disabled

    # 2. Fill the top part with bitmap and message

    # Max-width of message is the width of the screen...
    set wrapwidth [winfo screenwidth $dlg]
    # ...minus the width of the icon, padding and a fudge factor for
    # the window manager decorations and aesthetics.
    set wrapwidth [expr {$wrapwidth-60-[winfo pixels $dlg 9m]}]
    label $dlg.msg -justify left -text $text -wraplength $wrapwidth
    if {$windowingsystem eq "aqua"} {
	# On the Macintosh, use the stop bitmap
	label $dlg.bitmap -bitmap stop
    } else {
	# On other platforms, make the error icon
	canvas $dlg.bitmap -width 32 -height 32 -highlightthickness 0
	$dlg.bitmap create oval 0 0 31 31 -fill red -outline black
	$dlg.bitmap create line 9 9 23 23 -fill white -width 4
	$dlg.bitmap create line 9 23 23 9 -fill white -width 4
    }
    grid $dlg.bitmap $dlg.msg -in $dlg.top -row 0 -padx 3m -pady 3m
    grid configure	 $dlg.msg -sticky nsw -padx {0 3m}
    grid rowconfigure	 $dlg.top 1 -weight 1
    grid columnconfigure $dlg.top 1 -weight 1

    # 3. Create a row of buttons at the bottom of the dialog.

    set i 0
    foreach {name caption} $buttons {
	button $dlg.$name -text $caption -default normal \
	    -command [namespace code [list set button $i]]
	grid $dlg.$name -in $dlg.bot -column $i -row 0 -sticky ew -padx 10
	grid columnconfigure $dlg.bot $i -weight 1
	# We boost the size of some Mac buttons for l&f
	if {$windowingsystem eq "aqua"} {
	    if {($name eq "ok") || ($name eq "dismiss")} {
		grid columnconfigure $dlg.bot $i -minsize 90
	    }
	    grid configure $dlg.$name -pady 7
	}
	incr i
    }
    # The "OK" button is the default for this dialog.
    $dlg.ok configure -default active

    bind $dlg <Return>	[namespace code Return]
    bind $dlg <Destroy>	[namespace code [list Destroy %W]]
    $dlg.function configure -command [namespace code Details]

    # 6. Place the window (centered in the display) and deiconify it.

    ::tk::PlaceWindow $dlg

    # 7. Ensure that we are topmost.

    raise $dlg
    if {$tcl_platform(platform) eq "windows"} {
	# Place it topmost if we aren't at the top of the stacking
	# order to ensure that it's seen
	if {[lindex [wm stackorder .] end] ne "$dlg"} {
	    wm attributes $dlg -topmost 1
	}
    }

    # 8. Set a grab and claim the focus too.

    ::tk::SetFocusGrab $dlg $dlg.ok

    # 9. Wait for the user to respond, then restore the focus and
    # return the index of the selected button.  Restore the focus
    # before deleting the window, since otherwise the window manager
    # may take the focus away so we can't redirect it.  Finally,
    # restore any grab that was in effect.

    vwait [namespace which -variable button]
    set copy $button; # Save a copy...

    ::tk::RestoreFocusGrab $dlg $dlg.ok destroy

    if {$copy == 1} {
	return -code break
    }
}

namespace eval :: {
    # Fool the indexer
    proc bgerror err {}
    rename bgerror {}
    namespace import ::tk::dialog::error::bgerror
}
