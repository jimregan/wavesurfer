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

proc util::showURL url {
 webBrowser $url
 return
 switch $::tcl_platform(platform) {
  unix {
    exec sh -c "netscape -remote 'openURL($url)' " &
  }
  windows {
   if {[string match $::tcl_platform(os) "Windows NT"]} {
    exec $::env(COMSPEC) /c start $url &
   } else {
    exec start $url &
   }
  }
  macintosh {
   tk_messageBox -message "See web-page at $url"
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

# ADAPTED FROM lib/tk8.0/bgerror.tcl BY DONAL K. FELLOWS --
#
# This file contains a default version of the bgerror procedure.  It
# posts a dialog box with the error message and gives the user a chance
# to see a more detailed stack trace.
#
# SCCS: @(#) bgerror.tcl 1.16 97/08/06 09:19:50
#
# Copyright (c) 1992-1994 The Regents of the University of California.
# Copyright (c) 1994-1997 Sun Microsystems, Inc.
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

# bgerror --
# This is the default version of bgerror. 
# It tries to execute tkerror, if that fails it posts a dialog box containing
# the error message and gives the user a chance to ask to see a stack
# trace.
# Arguments:
# err -			The error message.

option add *ErrorDialog.msg.wrapLength 3.5i widgetDefault
namespace eval ::tk {
    namespace eval errorDialog {
	variable button -1

	proc Return {} {
	    variable button

	    .bgerrorDialog.button0 configure -state active -relief sunken
	    update idletasks
	    after 100
	    set button 0
	}

	proc details {} {
	    set w .bgerrorDialog
	    $w.button2 configure -text "Save To Log" \
		    -command [namespace code {catch {saveToLog}}]
	    #grid columnconf $w.bot 2 -weight 0 -minsize 0;
	    grid $w.top.info - -sticky nsew -padx 3m -pady 3m
	}

	proc saveToLog {} {
	    set w .bgerrorDialog
	    set types {
		{{Log Files} .log}
		{{Text Files} .txt}
		{{All Files} *}
	    }
	    set filename [tk_getSaveFile -title "Log file to save to" \
		-filetypes $types -defaultextension .log -parent $w]
	    if {![string length $filename]} {
		return
	    }
	    set f [open $filename w]
	    puts -nonewline $f [$w.top.info.text get 1.0 end]
	    close $f
	}

	proc Destroy {W} {
	    if {".bgerrorDialog" == "$W"} {
		variable button
		set button -1
	    }
	}

	proc Config {W h} {
	    variable curh
	    if {".bgerrorDialog" == "$W" && $curh != $h && [winfo ismap $W]} {
		set width [.bgerrorDialog cget -width]
		set curh  $h
		set x [expr ([winfo screenwidth .bgerrorDialog] - $width)/2 - \
			[winfo vrootx [winfo parent .bgerrorDialog]]]
		set y [expr ([winfo screenheight .bgerrorDialog] - $curh)/2 - \
			[winfo vrooty [winfo parent .bgerrorDialog]]]
		wm geom .bgerrorDialog +$x+$y
	    }
	}
    }
}


if 1 {
proc bgerror err {
    global errorInfo tcl_platform
    set butvar ::tk::errorDialog::button
    upvar #0 $butvar _button

    set info $errorInfo

    # Ok the application's tkerror either failed or was not found
    # we use the default dialog then :
    if {$tcl_platform(platform) == "macintosh"} {
	set ok Ok
    } else {
	set ok OK
    }

    set w .bgerrorDialog
    set title "WaveSurfer Internal Error"
    set text "Error: $err"
    set bitmap error
    set default 0
    set args [list $ok "Skip Messages" "Details >>"]

    global tcl_platform

    # 1. Create the top-level window and divide it into top
    # and bottom parts.

    catch {destroy .bgerrorDialog}
    toplevel .bgerrorDialog -class ErrorDialog
    wm title .bgerrorDialog $title
    wm iconname .bgerrorDialog ErrorDialog
    wm protocol .bgerrorDialog WM_DELETE_WINDOW { }

    # The following, though surprising, works.
    if {$::tcl_version <= 8.3} {
     wm transient .bgerrorDialog .bgerrorDialog
    }
    if {$tcl_platform(platform) == "macintosh"} {
	unsupported1 style .bgerrorDialog dBoxProc
    }

    tk_frame .bgerrorDialog.bot
    tk_frame .bgerrorDialog.top
    if {$tcl_platform(platform) == "unix"} {
	.bgerrorDialog.bot configure -relief raised -bd 1
	.bgerrorDialog.top configure -relief raised -bd 1
    }
    pack .bgerrorDialog.bot -side bottom -fill both
    pack .bgerrorDialog.top -side top -fill both -expand 1

    set W [tk_frame $w.top.info]
    text $W.text -bd 2 -yscrollcommand "$W.scroll set" -setgrid true \
	    -width 20 -height 10 -state normal -wrap char
    if {$tcl_platform(platform) == "macintosh"} {
	$W.text configure -relief flat -highlightthickness 0
    } else {
	$W.text configure -relief sunken
    }
    scrollbar $W.scroll -relief sunken -command "$W.text yview"
    pack $W.scroll -side right -fill y
    pack $W.text -side left -expand yes -fill both
    $W.text insert 0.0 $info
    $W.text mark set insert 0.0
    $W.text configure -state disabled

    # 2. Fill the top part with bitmap and message (use the option
    # database for -wraplength so that it can be overridden by
    # the caller).

    label .bgerrorDialog.msg -justify left -text $text
    if {$tcl_platform(platform) == "macintosh"} {
	.bgerrorDialog.msg configure -font system
    } else {
	.bgerrorDialog.msg configure -font {Times -18}
    }
    grid .bgerrorDialog.msg -in .bgerrorDialog.top -row 0 -column 1 \
	    -sticky nsw -padx 3m -pady 3m
    grid rowconfig  .bgerrorDialog.top 1 -weight 1
    grid columnconf .bgerrorDialog.top 1 -weight 1
    if {$bitmap != ""} {
     if {($tcl_platform(platform) == "macintosh") && ($bitmap == "error")} {
      set bitmap "stop"
     }
      label .bgerrorDialog.bitmap -bitmap $bitmap

	grid .bgerrorDialog.bitmap -in .bgerrorDialog.top -row 0 -column 0 \
		-padx 3m -pady 3m
    }

    # 3. Create a row of buttons at the bottom of the dialog.

    set i 0
    foreach but $args {
	button .bgerrorDialog.button$i -text $but -command "set $butvar $i"
	if {$i == $default} {
	    .bgerrorDialog.button$i configure -default active
	} else {
	    .bgerrorDialog.button$i configure -default normal
	}
	grid .bgerrorDialog.button$i -in .bgerrorDialog.bot \
		-column $i -row 0 -sticky ew -padx 10
	grid columnconfigure .bgerrorDialog.bot $i -weight 1
	# We boost the size of some Mac buttons for l&f
	if {$tcl_platform(platform) == "macintosh"} {
	    set tmp [string tolower $but]
	    if {($tmp == "ok") || ($tmp == "cancel")} {
		grid columnconfigure .bgerrorDialog.bot $i \
			-minsize [expr 59 + 20]
	    }
	}
	incr i
    }

    set ::tk::errorDialog::curh 0
    bind .bgerrorDialog <Return>  	{::tk::errorDialog::Return    }
    bind .bgerrorDialog <Destroy> 	{::tk::errorDialog::Destroy %W}
    bind .bgerrorDialog <Configure>     {::tk::errorDialog::Config  %W %h}
    .bgerrorDialog.button2 configure -command {::tk::errorDialog::details   }

    # 6. Withdraw the window, then update all the geometry information
    # so we know how big it wants to be, then center the window in the
    # display and de-iconify it.

    wm withdraw .bgerrorDialog
    update idletasks
    set width  [winfo reqwidth  .bgerrorDialog]
    set height [winfo reqheight .bgerrorDialog]
    set x [expr ([winfo screenwidth .bgerrorDialog]  - $width )/2 - \
	    [winfo vrootx [winfo parent .bgerrorDialog]]]
    set y [expr ([winfo screenheight .bgerrorDialog] - $height)/2 - \
	    [winfo vrooty [winfo parent .bgerrorDialog]]]
    .bgerrorDialog configure -width $width
    wm geom .bgerrorDialog +$x+$y
    wm deiconify .bgerrorDialog

    # 7. Set a grab and claim the focus too.

    set oldFocus [focus]
    set oldGrab [grab current .bgerrorDialog]
    if {$oldGrab != ""} {
	set grabStatus [grab status $oldGrab]
    }
    grab .bgerrorDialog
    if {$default >= 0} {
	focus .bgerrorDialog.button$default
    } else {
	focus .bgerrorDialog
    }

    # 8. Wait for the user to respond, then restore the focus and
    # return the index of the selected button.  Restore the focus
    # before deleting the window, since otherwise the window manager
    # may take the focus away so we can't redirect it.  Finally,
    # restore any grab that was in effect.

    tkwait variable $butvar
    set button ${_button}; # Save a copy...
    catch {focus $oldFocus}
    catch {destroy .bgerrorDialog}
    if {$oldGrab != ""} {
	if {$grabStatus == "global"} {
	    grab -global $oldGrab
	} else {
	    grab $oldGrab
	}
    }

    if {$button == 1} {
	return -code break
    }
}
}