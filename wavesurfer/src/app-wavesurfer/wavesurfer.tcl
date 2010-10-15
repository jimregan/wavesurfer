#!/bin/sh
# the next line restarts using wish \
exec wish8.5 "$0" "$@"

set RELEASE @RELEASE@
set BUILD @BUILD@
#
#  @COPYRIGHT@
#
# This file is part of the WaveSurfer package.
# The latest version can be found at http://sourceforge.net/projects/wavesurfer
#

package provide app-wavesurfer 1.8

catch {package require Tk}

set dir [file normalize [file dirname [info script]]]
set auto_path [concat [list [file dirname $dir]] $auto_path]

package require surfutil

proc ShowConsole {} {
    if {[catch {console show}]} {
	if {[info command tkcon] == ""} {
	    package require tkcon
	    
	    set ::tkcon::OPT(exec) {}
	    set ::tkcon::PRIV(root) .tkcon
	    set ::tkcon::PRIV(protocol) {}
	    ::tkcon::Init
	} else {
	    tkcon show
	}
    }
}

# check for --show-console option a.s.a.p. so we may use it to diagnose startup problems
# in wrapped apps
if {"--show-console" in $argv} {
    set argv [lreplace $argv [lsearch $argv "--show-console"] [lsearch $argv "--show-console"]]
    ShowConsole
}

set version_major 1
set version_minor 8
set version ${version_major}.${version_minor}

namespace eval ::splash {

 variable progress
 variable filecount
 set filecount 0
 set splash [toplevel .splash -relief raised -bd 1]
 wm withdraw $splash
 wm withdraw .
 wm overrideredirect $splash 1
 if [file exists $dir/../../icons/ws10h.gif] {
     set img [image create photo -file $dir/../../icons/ws10h.gif]
 } else {
     set img [image create photo]
 }  

 set pad 20
 set width [expr [image width $img]+2*$pad]
 set height [expr [image height $img]+2*$pad]
 set bg lightgray
 set fg black
 set fg2 black
 pack [label $splash.lx -text [::util::mc "WaveSurfer @RELEASE@"] -font "helvetica 12" -bg $bg -fg $fg] -side top -expand 1 -fill x
 pack [canvas $splash.c -width $width -height $height -bg $bg -highlightthickness 0] -side top 
 $splash.c create image $pad $pad -image $img -anchor nw
 pack [label $splash.l0 -text [::util::mc "Initializing..."] -font "helvetica 12" -bg $bg -fg $fg] -side top -expand 1 -fill x
 pack [frame $splash.f -bg $bg] -side top -expand 1 -fill x
 pack [label $splash.f.l1 -text [::util::mc "Components read:"] -font "helvetica 12" -bg $bg -fg $fg] -side left -expand 1 -fill x
 pack [label $splash.f.l2 -textvariable ::splash::progress -font "helvetica 12" -bg $bg -fg $fg2 -anchor w] -side left -expand 1 -fill x
 
 set ww $width
 set wh [expr {$height+150}]
 wm geometry $splash +[expr {([winfo screenwidth .]-$ww)/2}]+[expr {([winfo screenheight .]-$wh)/2}]
 wm deiconify $splash

 update idletasks
}

set proctracefile [file join [file dirname [info script]] proctrace.tcl]

if {[file exists $proctracefile]} {
# source $proctracefile
}

if {$::tcl_platform(os) == "Darwin"} {
 set ::ocdir right
} else {
 set ::ocdir left
}

set surf(wavesurferdir) [file dirname [info script]]

proc SetIcon {w} {
 if {[info exists ::wrap] && [info commands winico] != ""} {
  set icofile [file join $::wrap(dir) icons b32-256.ico]
  if {[file exists $icofile]} {
   if {![info exists ::surf(board)]} {
    set tmpfile [file join [util::tmpdir] board.ico]
    set fin [open $icofile r]
    fconfigure $fin -translation binary
    set fout [open $tmpfile w]
    fconfigure $fout -translation binary
    puts -nonewline $fout [read $fin]
    close $fin
    close $fout
    set ::surf(board) [winico create $tmpfile]
    file delete $tmpfile
   }
  # set the toplevel icon...
   winico setwindow $w $::surf(board)
  # set the taskbar icon...
#   winico text $::surf(board) {WaveSurfer, LMB: play/pause, MMB: record/stop}
#   winico taskbar add $::surf(board) -callback [list taskbarCallback %m %x %y]
  }
 }
}

proc taskbarCallback {m x y} {
  if {[string match WM_LBUTTONUP $m ]} {
    PlayPause
  }
  if {[string match WM_MBUTTONUP $m ]} {
    set w [::wsurf::GetCurrent]
    if {$w == ""} return
    if {[$w getInfo isRecording] == 1} {
      $w stop
    } else {
      $w record
    }
  }
}

# try to remove all libsnack* files in the tmp directory
# note: a currently loaded library cannot be deleted, 
# it will have to stay until next time. 
# CleanUp will called both at startup and exit.

proc CleanUp {} {
 foreach f [glob -nocomplain [file join [util::tmpdir] libsnack*]] {
  catch {file delete -force $f}
 }
}

set surf(fileFormat) WAV
set surf(extTypes) {}
set surf(loadTypes) {}
set surf(loadKeys) {}
set surf(saveTypes) {}
set surf(saveKeys) {}

proc GetTopLevel {w} {
 if {$w == ""} {
  return [lindex $::Info(toplevels) 0]
 }
 return .[lindex [split $w .] 1]
}

proc GetCurrentPath {} {
 set w [::wsurf::GetCurrent]
 set path ""
 if {$w != ""} {
   if {[$w getInfo fileName] != ""} {
     set path [file dirname [$w getInfo fileName]]
   }
 }
 if {$w == "" && $path == ""} {
  if {[info exists ::recentFiles] && [llength $::recentFiles] > 0} {
   set path [file dirname [lindex $::recentFiles 0]]
   if {[file exists $path] == 0} { set path "" }
  }
 }
 return $path
}


proc Open {} {
 
 set w [::wsurf::GetCurrent]

 set path [GetCurrentPath]

 # workaround for evil windows tk_get*File bug
 set mb [GetTopLevel $w].bf.lab
 messagebar::configure $mb -state disabled

 # For unknown RAW files, add the current extension to the list in the file selection dialog
 if {$::surf(fileFormat) == "RAW"} {
  if {[info exists ::recentFiles] && [llength $::recentFiles] > 0} {
   set ext [file extension [lindex $::recentFiles 0]]
   if {[regexp " $ext\}" $::surf(loadTypes)] == 0} {
    set ::surf(loadTypes) [concat $::surf(loadTypes) [list "{Raw Files} $ext"]]
    snack::addLoadTypes $::surf(loadTypes) $::surf(loadKeys)
   }
  }
 }

 set fileName [snack::getOpenFile -initialdir $path -format $::surf(fileFormat)]
 update
 messagebar::configure $mb -state normal
 
 if {$fileName == ""} return
 OpenFile $fileName
}

set filelist {}
set fileName {}
proc ReadFileList {fileName} {
 if {[file isdir $fileName]} {
  set ::listfiles [glob $fileName/*.wav]
  set ::filelist {}
 } else {
  set fd [open $fileName]
  set ::listfiles {}
  set ::filelist {}
  foreach e [split [read -nonewline $fd] \n] {
   if {[string match windows $::tcl_platform(platform)]} {
    regsub -all {\\} $e "/" e
   }
   lappend ::listfiles $e
  }
  close $fd
 }
 foreach n [list 0 1 2 3] {
  if {[file dirname [lindex $::listfiles 0]] == "."} break
  set path [eval file join [lrange [file split \
		     [file dirname [lindex $::listfiles 0]]] 0 end-$n]]
  set chopMore 0
  foreach f $::listfiles {
   if {[string match "$path*" $f] == 0} { set chopMore 1 ; break}
  }
  if {$chopMore == 0} break
 }
 foreach e $::listfiles {
  set name [eval file join [lrange [file split $e] end-$n end]]
  if {[regexp {.*:[\d]+} $e]} {
   regexp {(.*):[\d]+} $name dummy shortname
   regexp {(.*):[\d]+} $e dummy longname
   set ::filemap($shortname) $longname
  } else {
   set ::filemap($name) $e
  }
  lappend ::filelist $name
 }
 set ::fileName $fileName
}

proc UpdateFileList {files} {
 if {[string match windows $::tcl_platform(platform)]} {
  regsub -all {\\} $files "/" files
 }
 set ::listfiles $files
 set ::filelist {}
 
 foreach n [list 0 1 2 3] {
  if {[file dirname [lindex $::listfiles 0]] == "."} break
  set path [eval file join [lrange [file split \
		     [file dirname [lindex $::listfiles 0]]] 0 end-$n]]
  set chopMore 0
  foreach f $::listfiles {
   if {[string match "$path*" $f] == 0} { set chopMore 1 ; break}
  }
  if {$chopMore == 0} break
 }
 foreach e $::listfiles {
  set name [eval file join [lrange [file split $e] end-$n end]]
  if {[regexp {.*:[\d]+} $e]} {
   regexp {(.*):[\d]+} $name dummy shortname
   regexp {(.*):[\d]+} $e dummy longname
   set ::filemap($shortname) $longname
  } else {
   set ::filemap($name) $e
  }
  lappend ::filelist $name
 }
}

proc Chooser {} {
 catch {destroy .chooser}
 set e [toplevel .chooser]
 # wm geometry .blowup +$v(blowupwinx)+$v(blowupwiny)
 wm title $e [::util::mc "Chooser"]
 
 pack [ttk::frame $e.frame] -side top -expand yes -fill both
 scrollbar $e.frame.scroll -command "$e.frame.list yview"
 listbox $e.frame.list -yscroll "$e.frame.scroll set" -setgrid 1 -selectmode single -exportselection false -height 16 -width 40
 pack $e.frame.scroll -side right -fill y
 pack $e.frame.list -side left -expand 1 -fill both
 bind $e.frame.list <ButtonPress-1> {Choose %y}

 foreach file $::filelist {
  $e.frame.list insert end $file
 }

 pack [ttk::frame $e.f2] -fill x
 pack [ttk::button $e.f2.b2 -width 12 -text [::util::mc "Add files..."] -command AddFilesToList] -side left -padx 5 -pady 5
 pack [ttk::button $e.f2.b1 -width 12 -text [::util::mc "Load file list..."] -command LoadFileList] -side left -padx 5 -pady 5
 pack [ttk::button $e.f2.b3 -width 12 -text [::util::mc "Clear list"] -command ClearFileList] -side left -padx 5 -pady 5
 pack [ttk::button $e.f2.b4 -width 12 -text [::util::mc "Sort"] -command SortFileList] -side left -padx 5 -pady 5

# pack [ttk::frame $e.f3] -fill x
# pack [label $e.f3.l1 -text [::util::mc "File path:"]] -side left
# pack [ttk::entry $e.f3.e1 -textvariable Info(chooser,dir)] -side left
# pack [ttk::button $e.f3.b1 -text [::util::mc "Browse..."] -command browseForDir] -side left
 pack [ttk::frame $e.f4] -fill x -ipadx 10 -ipady 10

 pack [ttk::checkbutton $e.f4.cb -text [::util::mc "Load new file into current sound"] -variable ::Info(chooser,replacecurrent)] -side left -padx 5 -pady 5
 pack [ttk::checkbutton $e.f4.cb2 -text [::util::mc "Auto play"] -variable ::Info(chooser,autoplay)] -side left -padx 5 -pady 5
 pack [ttk::checkbutton $e.f4.cb3 -text [::util::mc "Auto zoom out"] -variable ::Info(chooser,autozoom)] -side left -padx 5 -pady 5
}

proc LoadFileList {} {
 set fn [tk_getOpenFile -initialdir [GetCurrentPath]]
 if {$fn == ""} return

 set fd [open $fn]
 UpdateFileList [split [read -nonewline $fd] \n]
 close $fd

 set e .chooser
 $e.frame.list delete 0 end
 foreach file $::filelist {
  $e.frame.list insert end $file
 }
}

proc AddFilesToList {} {
 set newfiles [tk_getOpenFile -title [::util::mc "Select files to add"] -multiple 1 -initialdir [GetCurrentPath]]
 UpdateFileList [concat $::filelist $newfiles]
 set e .chooser
 $e.frame.list delete 0 end
 foreach file $::filelist {
  $e.frame.list insert end $file
 }
}

proc ClearFileList {} {
 set e .chooser
 $e.frame.list delete 0 end
 UpdateFileList [list]
}

proc SortFileList {} {
 set e .chooser
 $e.frame.list delete 0 end
 foreach file [lsort -dictionary $::filelist] {
  $e.frame.list insert end $file
 }
}

proc Choose y {
 set index [.chooser.frame.list nearest $y]
 ChooseEntry $index
}

proc ChooseNext {} {
 set index [.chooser.frame.list curselection]
 .chooser.frame.list selection clear $index
 incr index
 .chooser.frame.list selection set $index
 ChooseEntry $index
 set w [::wsurf::GetCurrent]
 $w xscroll moveto 0.0
 $w configure -selection [list 0.0 0.0]
}

proc ChooseEntry {index} {
 set entry [.chooser.frame.list get $index]
 foreach {name pos} [split $entry ;] {}
 set w [::wsurf::GetCurrent]
 if {$w == ""} {
  set w [newWidget "" expanded]
 }
 if {[info exists ::filemap($name)]} {
  if {$::Info(chooser,replacecurrent) && $w != ""} {
   # load file into current widget
   $w openFile $::filemap($name)
   if {[$w cget -configuration] == ""} {
    if {[lindex $::surf(conf) 0] != "unspecified"} {
     $w configure -configuration [lindex $::surf(conf) 0]
    }
   }
  } elseif {$::surf(conf) != "unspecified"} {
   OpenFile $::filemap($name) [lindex $::surf(conf) 0]
  } else {
   OpenFile $::filemap($name)
  }
  # 070910, for playing back float-files
  if 1 {
   set ::convert(encoding) Lin16 
   set ::convert(rate)     44100
   set ::convert(channels) 1
   DoConvert $w
   set length [[$w cget -sound] length -unit seconds]
   $w configure -selection [list 0.0 $length]
   DoNormalize $w
  }
  if {$::Info(chooser,autoplay)} {
   [wsurf::GetCurrent] play
  }
 }
 if {$::Info(chooser,autozoom)} {
  [::wsurf::GetCurrent] zoomall
 }

 if {$pos != ""} {
  set w [::wsurf::GetCurrent]
  $w configure -selection [list $pos $pos]
  $w zoomin
  $w zoomout
 } else {
  $w configure -selection [list 0.0 0.0]
 }
 set title [::util::mc "Chooser"]
 append title " ([expr $index+1] of [llength $::filelist])"
 append title " $::fileName"
 wm title .chooser $title
}

proc Revert {} {
 if {[::wsurf::NeedSave]} {
  if {[tk_messageBox -message "[::util::mc "You have unsaved changes."] \n [::util::mc "Do you really want to revert to the file on disk?"]" -type yesno -icon question] == "no"} {
    return
  }
 }
 set w [::wsurf::GetCurrent]
 if {$w != ""} {
   if {[$w getInfo fileName] != ""} {
    $w openFile [$w getInfo fileName]
   }
 }
}

proc OpenFile {args} {

    puts [info level 0]
    puts defaultConfig=$::wsurf::Info(Prefs,defaultConfig)
    global surf
    variable Info  
    
    set fileName [lindex $args 0]
    if {![file readable $fileName]} {
	tk_messageBox -message "[::util::mc {Can't open the file}] \"$fileName\"" \
	    -icon error
	return
    }
    
    set w [::wsurf::GetCurrent]
    
    if {$w != "" && [$w getInfo isUntouched]} {
	$w closeWidget
    }
    
    if {[::wsurf::GetCurrent] != ""} {
	set w [CreateToplevel]
    } else {
	set w [wsurf [GetTopLevel $w].s[incr surf(count)] \
		   -messageproc setMsg -progressproc progressCallback \
		   -playpositionproc progressCallback -dropfileproc dropFileCallback]
	
	lappend ::Info(widgets,$::Info(toplevels)) $w
    }
    $w openFile $fileName
    pack $w -expand 0 -fill both -side top
    set conf ""
    if {[llength $args] == 1} {
	if {$::wsurf::Info(Prefs,defaultConfig) == ""} {
	    set makedefault 0
	    set conf [::wsurf::ChooseConfigurationDialog makedefault]
	    if {$conf == ""} {
		destroy $w
		return
	    }
	    puts makedefault=$makedefault
	    if $makedefault {
		wsurf::SetPreference defaultConfig [file root [file tail $conf]]
		::SavePreferences
	    }
	} else {
	    set l [::wsurf::GetConfigurations]
	    set ind [lsearch -regexp $l ".*$::wsurf::Info(Prefs,defaultConfig)\[\\w\\s\]*.conf"]
	    if {$ind != -1} {
		set conf [lindex $l $ind]
	    } else {
		set conf ""
	    }
	}
	if {$conf == "standard"} {
	    set conf ""
	}
    } else {
	set conf [lindex $args 1]
    }
    $w configure -configuration $conf
    
    SetMasterWidget
    # Remember this file format type for next time
    set surf(fileFormat) [lindex [[$w cget -sound] info] 6]
    RecentFile $fileName
    if {$surf(play)} {
	$w play
    }
    # set mb [GetTopLevel $w].bf.lab
    # messagebar::configure $mb -text [[$w cget -sound] info]
}

proc CreateToplevel {} {
 global surf
 incr surf(count)
 if {[string match separate $::wsurf::Info(Prefs,createWidgets)]} {
  toplevel .x$surf(count)
  lappend ::Info(toplevels) .x$surf(count)
  wm title .x$surf(count) "WaveSurfer #$surf(count)"
  CreateMenus .x$surf(count)
  CreateToolbar .x$surf(count)
  CreateMessagebar .x$surf(count)
  BindKeys .x$surf(count)
  proc pgcb.x$surf(count) {args} {
   set name [string trimleft [lindex [info level 0] 0] pgcb].bf.lab
   eval progressCallback2 $name $args
  }
  proc smcb.x$surf(count) {args} {
   set name [string trimleft [lindex [info level 0] 0] smcb].bf.lab
   eval setMsg2 $name $args
  }
  set index [lsearch -exact $::wsurf::Info(Prefs,icons) close]
  set icons [lreplace $::wsurf::Info(Prefs,icons) $index $index]
  set w [wsurf .x$surf(count).s$surf(count) -icons $icons \
    -messageproc smcb.x$surf(count) -progressproc pgcb.x$surf(count)\
    -playpositionproc pgcb.x$surf(count) -dropfileproc dropFileCallback]
  wm protocol .x$surf(count) WM_DELETE_WINDOW [list KillWindow .x$surf(count)]
  wm minsize .x$surf(count) 200 1
  wm resizable .x$surf(count) 1 0
  lappend ::Info(widgets,.x$surf(count)) $w
 } else {
  set w [wsurf [lindex $::Info(toplevels) 0].s[incr surf(count)] \
    -messageproc setMsg -progressproc progressCallback \
    -playpositionproc progressCallback -dropfileproc dropFileCallback]
  lappend ::Info(widgets,[lindex $::Info(toplevels) 0]) $w
 }
 return $w
}

proc RecentFile fn {
 global recentFiles

 if {$fn == ""} return
 if {[info exists recentFiles]} {
 } else {
  set recentFiles {}
 }
 set index [lsearch -exact $recentFiles $fn]
 set recentFiles [lreplace $recentFiles $index $index]
 set recentFiles [linsert $recentFiles 0 $fn]
 if {[llength $recentFiles] > 6} {
  set recentFiles [lreplace $recentFiles 6 end]
 }
 
 foreach tl $::Info(toplevels) {
  set m $tl.menu
  $m.file delete $::fileMenuIndex end
  foreach e $recentFiles {
   set l $e
   if {[string length $e] > 30} {
    set l ...[string range $e [expr {[string length $e]-30}] end]
   }
   $m.file add command -label $l -command [list OpenFile $e]
  }
  $m.file add separator
  $m.file add command -label [::util::mc Close] -command [list Close $tl] \
    -accelerator $::AccKeyM+W
  if {$::tcl_platform(os) != "Darwin"} {
   $m.file add command -label [::util::mc Exit] -command Exit
  }
 }
 
 set fn [file join $::env(HOME) .wavesurfer $::Info(Version) recent-files]
 if {[catch {open $fn w} out]} {
 } else {
  puts $out "set ::recentFiles \[list $recentFiles\]"
  close $out
 }
}

proc PlayFile {filename} {
  set ::surf(play) 1
  OpenFile $filename ""
}

proc BreakIfInvalid {w} {
 if {[string match *.bf [focus]]} {
  regexp {(\.x[0-9]*\.).*} $w junk w
 }
 if {[string match *.tb.* [focus]]} {
  regexp {(\.x[0-9]*\.).*} $w junk w
 }
 if {$w == "" || ([string match $w* [focus]] == 0 && \
		      [string match .tkcon.text [focus]] == 0)} {

  return -code return
 }
}

proc Save {{w ""}} {
    puts [info level 0]
    if {$w==""} {
	set w [::wsurf::GetCurrent]
	BreakIfInvalid $w
    }
    set fn [$w getInfo fileName]
    puts fn=$fn
    if {$fn == ""} {
	return [SaveAs $w]
    } else {
	$w saveFile $fn
	return $fn
    }
}

proc SaveAs {{w ""}} {
    if {$w==""} {
	set w [::wsurf::GetCurrent]
	BreakIfInvalid $w
    }
    return [$w saveAs]
}

proc SaveAs:OLD {} {
    puts [info level 0]
    set w [::wsurf::GetCurrent]
#    BreakIfInvalid $w
    set path [file dirname [$w getInfo fileName]]
    set fileName [snack::getSaveFile -initialdir $path \
		      -format $::surf(fileFormat)]
    if {$fileName == ""} return ""
    $w saveFile $fileName
    return $filename
}

proc SaveSelection {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w

 foreach {left right} [$w cget -selection] break
 if {$left == $right} return
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]

 set path [file dirname [$w getInfo fileName]]
 set fileName [snack::getSaveFile -initialdir $path \
     -format $::surf(fileFormat)]
 if {$fileName == ""} return

 $s write $fileName -start $start -end $end -progress progressCallback
}

proc Print {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 $w printDialog
}

proc Close {p} {
 if {[llength $::Info(widgets,$p)] == 1} {

  # Choose the single widget of this toplevel

  set w $::Info(widgets,$p)

 } else {

  # Get current widget

  set w [::wsurf::GetCurrent]

  # If it isn't a child of the current toplevel, get the first child instead

  set n [lsearch $::Info(widgets,$p) $w]
  if {$n == -1} { set n 0 }
  set w [lindex $::Info(widgets,$p) $n]
 }
 if {[winfo exists $w]} {
  $w closeWidget
 }

 # If there are several toplevels check if this one should be closed

 if {[llength $::Info(toplevels)] > 1} {

  # Remove the widget from the widget list for this toplevel

  set n [lsearch $::Info(widgets,$p) $w]
  set ::Info(widgets,$p) [lreplace $::Info(widgets,$p) $n $n]

  # Close the toplevel if there are no children left

  if {[llength $::Info(widgets,$p)] == 0} {
   set n [lsearch $::Info(toplevels) $p]
   set ::Info(toplevels) [lreplace $::Info(toplevels) $n $n]
   destroy $p
  }
 }
}

proc KillWindow {w} {
 if {[llength $::Info(toplevels)] > 1 || [winfo exists .chooser]} {

  # Close all widgets in this toplevel

  foreach widget $::Info(widgets,$w) {
   Close $w
  }
 } else {

  # Exit if this was the last toplevel closed
  
  Exit
 }
}
set Info(showExitDialog) 1

proc Exit:OLD {} {
 if {[::wsurf::NeedSave]} {
  if {$::Info(showExitDialog)} {
   set ::Info(showExitDialog) 0
   if {[tk_messageBox -message "[::util::mc "You have unsaved changes."] \n [::util::mc "Do you really want to exit?"]" -type yesno -icon question] == "no"} {
    set ::Info(showExitDialog) 1
    return
   }
  } else {
   return
  }
 }

# Remember geometry

 if {[winfo exists .x]} {
  if {[catch {open $::Info(geometryFile) w} out]} {
  } else {
   regexp {([\d]+)[x][\d]+[+]([\d]+)[+]([\d]+)} [wm geometry .x] dummy w x y
   if {[info exists w]} {
    puts $out "set Info(Prefs,wsWidth) $w"
    puts $out "set Info(Prefs,wsLeft)  $x"
    puts $out "set Info(Prefs,wsTop)   $y"
   }
   close $out
  }
 }

 foreach f $::surf(tmpfiles) {
  file delete -force $::surf(tmpfiles)
 }
 CleanUp
 if {[info exists ::wrap] && [info commands winico] != ""} {
#   winico taskbar delete $::surf(board)
 }

 exit
}

# rename the exit command so we can catch it

rename exit _exit

proc exit {} {Exit}

proc Exit {} {

    foreach w [wsurf::GetUnsavedWidgets] {
	
	# try to close widget. this will pop up an ask-for-save dialog
	# if happily closed, it returns true. else (user cancelled),
	# it returns false

	if {![$w closeWidget]} {
	    return
	}
    }

    # if we got here, it's really time to exit.
    # Remember geometry
    
    if {[winfo exists .x]} {
	if {[catch {open $::Info(geometryFile) w} out]} {
	} else {
	    regexp {([\d]+)[x][\d]+[+]([\d]+)[+]([\d]+)} [wm geometry .x] dummy w x y
	    if {[info exists w]} {
		puts $out "set Info(Prefs,wsWidth) $w"
		puts $out "set Info(Prefs,wsLeft)  $x"
		puts $out "set Info(Prefs,wsTop)   $y"
	    }
	    close $out
	}
    }
    
    foreach f $::surf(tmpfiles) {
	file delete -force $::surf(tmpfiles)
    }
    CleanUp
    if {[info exists ::wrap] && [info commands winico] != ""} {
	#   winico taskbar delete $::surf(board)
    }

    _exit
}

proc Exit:not {} {
    foreach w [wsurf::GetUnsavedWidgets] {
	set qst [::util::mc "Do you want to save the changes made to"]
	append qst " " \"[$w cget -title]\" "?"
	set reply [tk_messageBox -message $qst -type yesnocancel]
	switch $reply {
	    yes {
		if {[Save $w]==""} {
		    # the save operation was cancelled, don't exit
		    return
		}
	    }
	    no {
		# do nothing, really.
	    }
	    cancel {
		
		return
	    }
	}
    }

    # if we got here, it's really time to exit.
    # Remember geometry
    
    if {[winfo exists .x]} {
	if {[catch {open $::Info(geometryFile) w} out]} {
	} else {
	    regexp {([\d]+)[x][\d]+[+]([\d]+)[+]([\d]+)} [wm geometry .x] dummy w x y
	    if {[info exists w]} {
		puts $out "set Info(Prefs,wsWidth) $w"
		puts $out "set Info(Prefs,wsLeft)  $x"
		puts $out "set Info(Prefs,wsTop)   $y"
	    }
	    close $out
	}
    }
    
    foreach f $::surf(tmpfiles) {
	file delete -force $::surf(tmpfiles)
    }
    CleanUp
    if {[info exists ::wrap] && [info commands winico] != ""} {
	#   winico taskbar delete $::surf(board)
    }

    _exit
}

proc newWidget {conf {state collapsed}} {
 global surf
 set w [CreateToplevel]
 $w configure -configuration $conf
 pack $w -expand 0 -fill both -side top
 return $w
}

proc New {} {
    if {$::wsurf::Info(Prefs,defaultConfig) == ""} {
	set makedefault 0
	set conf [::wsurf::ChooseConfigurationDialog makedefault]
	if {$conf == ""} {
	    destroy $w
	    return
	}
	puts makedefault=$makedefault
	if $makedefault {
	    wsurf::SetPreference defaultConfig [file root [file tail $conf]]
	    ::SavePreferences
	}
    } else {
	set l [::wsurf::GetConfigurations]
	set ind [lsearch -regexp $l ".*$::wsurf::Info(Prefs,defaultConfig)\[\\w\\s\]*.conf"]
	if {$ind != -1} {
	    set conf [lindex $l $ind]
	} else {
	    set conf ""
	}
    }
    if {$conf == ""} return
    if {$conf == "standard"} {
	set conf ""
    }
    newWidget $conf expanded
    SetMasterWidget
}

proc deleteWidget {} {
 set w [::wsurf::GetCurrent]
 destroy $w
}

proc setMsg {m} {
 set w [::wsurf::GetCurrent]
 set mb [GetTopLevel $w].bf.lab
 setMsg2 $mb $m
}

proc setMsg2 {mb m} {
 messagebar::configure $mb -text $m
}

proc lockMessageBar {w} {
 set mb [GetTopLevel $w].bf.lab
 if {$::surf(locked) == 0} {
  messagebar::configure $mb -locked 1
  set ::surf(locked) 1
 } else {
  messagebar::configure $mb -locked 0
  set ::surf(locked) 0
 }
}

proc progressCallback {message fraction} {
 set w [::wsurf::GetCurrent]
 set mb [GetTopLevel $w].bf.lab
 progressCallback2 $mb $message $fraction
}

proc progressCallback2 {mb message fraction} {
 switch -- $message {
  "Converting rate" {
   set message [::util::mc "Converting sample rate..."]
  }
  "Converting encoding" {
   set message [::util::mc "Converting sample encoding format..."]
  }
  "Converting channels" {
   set message [::util::mc "Converting number of channels..."]
  }
  "Computing pitch" {
   set message [::util::mc "Computing pitch..."]
  }
  "Computing power" {
   set message [::util::mc "Computing power..."]
  }
  "Reading sound" {
   set message [::util::mc "Reading sound..."]
  }
  "Writing sound" {
   set message [::util::mc "Writing sound..."]
  }
  "Computing waveform" {
   set message [::util::mc "Precomputing waveform..."]
  }
  "Reversing sound" {
   set message [::util::mc "Reversing sound..."]
  }
  "Filtering sound" {
   set message [::util::mc "Filtering sound..."]
  }
  "Play" {
    set s $::wsurf::Info(ActiveSound)
    set rangeStart [util::min [expr {int($fraction*[$s cget -rate])}] \
	[expr {[$s length]-1}]]
    set rangeEnd [util::min [expr {int(($fraction+0.1)*[$s cget -rate])}] \
	[expr {[$s length]-1}]]
    set logarg [$s max -start $rangeStart -end $rangeEnd]
    if {$logarg < 1} { set logarg 1 } 
    set level [expr {log($logarg)/10.3972}]
    messagebar::configure $mb -level $level
    set w [::wsurf::GetCurrent]
    [GetTopLevel $w].tb.time configure -text [$w formatTime $fraction]
    return
  }
  "Stop" {
    messagebar::configure $mb -level 0.0
    set w [::wsurf::GetCurrent]
    [GetTopLevel $w].tb.time configure -text [$w formatTime $fraction]
    return
  }
 }

 if {$fraction==0.0} {
  append message [::util::mc " (click to cancel)"]
  set ::surf(interrupted) 0
  LockGui true
 } elseif {$fraction>=0.0 && $fraction<1.0} {
  append message [::util::mc " (click to cancel)"]
  messagebar::configure $mb -progress $fraction
  set ::surf(interrupted) 0
 } elseif {$fraction==1.0} {
  append message [::util::mc " done."]
  messagebar::configure $mb -progress 0.0
  LockGui false
 }
 
 messagebar::configure $mb -text $message
 update

 # check if someone clicked the messagebar
 if {$::surf(interrupted)} {
  return -code error
 }

 # inhibit interruption when done
 if {$fraction==1.0} {
  set ::surf(interrupted) 1
 }
}

# procedure to lock the gui under time-consuming operations. 
# grab on the messagebar frame (to recieve interrupt-click).
# On windows, the menu bar is not affected by the grab (tk-bug?) 
# so we need to swap in a dummy menu bar!

proc LockGui {state} {
 set w [::wsurf::GetCurrent]
 set mbf [GetTopLevel $w].bf

 if {$state} {
  set ::surf(oldFocus) [focus]
  focus $mbf
  grab $mbf
  if {[string match windows $::tcl_platform(platform)]} {
   foreach tl $::Info(toplevels) {
    $tl config -menu $tl.dummy
   }
  }
 } else {
  if {[info exists ::surf(oldFocus)] == 0} return
  grab release $mbf
  focus $::surf(oldFocus)
  if {[string match windows $::tcl_platform(platform)]} {
   foreach tl $::Info(toplevels) {
    $tl config -menu $tl.menu
   }
  }
 }
}

proc Interrupt {} {
 set w [::wsurf::GetCurrent]
 set mb [GetTopLevel $w].bf.lab
 if {!$::surf(interrupted)} {
  messagebar::configure $mb -progress 0.0
  messagebar::configure $mb -text [::util::mc Interrupted]
  LockGui false
  set ::surf(interrupted) 1
 }
}

proc Undo {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isLinked2File]} return
 $w undo
}

proc Cut {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isLinked2File]} return
 $w cut cbs
}

proc Copy {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isLinked2File]} return
 $w copy cbs
}

proc SelectoNew {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 foreach {left right} [$w cget -selection] break
 if {$left == $right} return
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]
 New
 set wnew [::wsurf::GetCurrent]
 set snew [$wnew cget -sound]
 $snew copy $s -start $start -end $end
}

proc ZoomIn {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 $w zoomin
}

proc ZoomOut {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 $w zoomout
}

proc ZoomSel {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 $w zoomsel
}

proc ZoomAll {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 $w zoomall
}

proc Zoom {v} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 set pps [winfo fpixels $w ${v}m]
 $w configure -pixelspersecond $pps
}

proc Paste {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isLinked2File]} return
 $w paste cbs
#    snack::menuEntryOn Edit Undo
}

proc DoMixPaste {w} {
 global mixpaste

 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]

 if {$start == $end} return
 
 cbs2 copy $s

 if [catch {$s mix cbs -start $start -end $end \
		-prescaling [expr {$mixpaste(prescale)/ 100.0}] \
		-mixscaling [expr {$mixpaste(mixscale)/ 100.0}] \
     -progress progressCallback}] {
  $s copy cbs2
  return
 }
 ::wsurf::PrepareUndo "$s swap cbs2" "$s swap cbs2"
}

proc MixPaste {} {
 global mixpaste

 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isLinked2File]} return
 foreach {left right} [$w cget -selection] break
 if {$left == $right} {
  $w configure -selection \
      [list $left [expr $left + [cbs length -unit seconds]]]
 }
 set tl .mixpaste
 catch {destroy $tl}
 toplevel $tl
 wm title $tl [::util::mc "Mix Paste"]

 pack [ ttk::label $tl.l1 -text [::util::mc "Scale paste sound by:"]] \
     -fill x
 pack [ttk::frame $tl.f1] -fill both -expand true
  pack [ttk::scale $tl.f1.s1 -command "" -orient horizontal \
	     -variable mixpaste(mixscale) -from 0.0 -to 100.0] -side left
  $tl.f1.s1 set $mixpaste(mixscale)

 pack [ttk::entry $tl.f1.e -textvariable mixpaste(mixscale) -width 5] -side left
 pack [ttk::label $tl.f1.l -text % -width 1] -side left

 pack [ttk::label $tl.l2 -text [::util::mc "Scale original sound by:"]] \
     -fill x
 pack [ ttk::frame $tl.f2] -fill both -expand true
  pack [ttk::scale $tl.f2.s1 -command "" -orient horizontal \
	     -variable mixpaste(prescale) -from 0.0 -to 100.0] -side left
  $tl.f2.s1 set $mixpaste(prescale)

 pack [ttk::entry $tl.f2.e -textvariable mixpaste(prescale) -width 5] -side left
 pack [ttk::label $tl.f2.l -text % -width 1] -side left

 insertOKCancelButtons $tl.f3 "DoMixPaste $w;destroy $tl" "destroy $tl"
}

proc SelectAll {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 set pane [lindex [$w _getPanes] 0]
 if {$pane != ""} {
  set length [$pane cget -maxtime]
 } else {
  set length [[$w cget -sound] length -unit seconds]
 }
 $w configure -selection [list 0.0 $length]
}

proc ZeroXAdjust {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 set s [$w cget -sound]
 set length [$s length]
 if {$length == 0} return
 foreach m [$w cget -selection] {
  set start [expr {int($m*[$s cget -rate])}]
  set leftmost [expr {$start-200}]
  if {$leftmost < 0} { ;# to fill sample buffer with leftmost
   $s sample 0
  } else {
   $s sample [expr {$start-200}]
  }
  for {set i 0} {$i < 200} {incr i} {
   set j [expr {$start + $i}]
   if {$j > 0 && $j < $length} {
    set s1 [lindex [$s sample $j] 0]
    set s0 [lindex [$s sample [expr {$j-1}]] 0]
    if {[expr {$s1*$s0}] < 0} {
     break
    }
   }
   set j [expr {$start - $i}]
   if {$j > 0 && $j < $length} {
    set s1 [lindex [$s sample $j] 0]
    set s0 [lindex [$s sample [expr {$j-1}]] 0]
    if {[expr {$s1*$s0}] < 0} {
     break
    }
   }
  }
  lappend limits $j
 }
 $w configure -selection [list \
	 [expr {double([lindex $limits 0])/[$s cget -rate]}] \
	 [expr {double([lindex $limits 1]-1)/[$s cget -rate]}]]
}

proc PlayPause {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 # Hack that solves double play issue due to keyboard focus and space-button
 if {[string match *play* [focus]] && $::tcl_platform(platform) == "windows"
     && $::Info(Prefs,PlayPause) == "space"} {
  return
 }
 if {[$w getInfo isPlaying] == 1} {
  $w pause
 } else {
  $w play
 }
}

proc PlayStop {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isPlaying] == 1} {
  $w stop
 } else {
  $w play
 }
}

proc PlaySelection {} {
  set w [::wsurf::GetCurrent]
  BreakIfInvalid $w
  if {[$w getInfo isPlaying] == 1} {
    $w stop
  }
  $w play
}

proc PlayAtCursor {x} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isPlaying] == 1} {
  $w stop
 }
 foreach {start end} [$w cget -selection] break

 set s [$w cget -sound]
 set rate [$s cget -rate]
 set c [[lindex [$w _getPanes] 0] canvas]
 set x [$c canvasx $x]
 set cursorTime [expr {$x/[$w cget -pixelspersecond]}]
 if {$cursorTime < $start} {
  set end $start
  set start $cursorTime
 } else {
  set start $start
  set end $cursorTime
 }

 $w play $start $end
}

proc PlayAll {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isPlaying] == 1} {
  $w stop
 }
 $w play 0 -1
}

proc PlayVisible {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isPlaying] == 1} {
  $w stop
 }
 foreach {left right} [$w cget -zoomfracs] break
 $w play $left $right
}

proc PlayLoop {} {
  set w [::wsurf::GetCurrent]
  BreakIfInvalid $w
  $w playloop
}

# -----------------------------------------------------------------------------
# Transformations

proc Reverse {} {
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isLinked2File]} return
 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]
 if {$start == $end} {
     $w configure -selection [list 0.0 [$s length -unit seconds]]
     set start 0
     set end -1
 }

 cbs copy $s
 if [catch {$s reverse -start $start -end $end \
	 -progress progressCallback}] {
     $s copy cbs
     return
 }
 ::wsurf::PrepareUndo "$s reverse -start $start -end $end" \
	 "$s reverse -start $start -end $end"
}

proc Invert {} {
 variable Info
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isLinked2File]} return
 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]
 if {$start == $end} {
  $w configure -selection [list 0.0 [$s length -unit seconds]]
  set start 0
  set end -1
 }

 $Info(filter) configure -1.0

 cbs copy $s
 if [catch {$s filter $Info(filter) -start $start -end $end \
	 -progress progressCallback}] {
  $s copy cbs
  return
 }
 ::wsurf::PrepareUndo "$s swap cbs" "$s swap cbs"
}

proc Silence {} {
 variable Info
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isLinked2File]} return
 foreach {left right} [$w cget -selection] break
 if {$left == $right} {
  InsertSilence $w
  return
 }
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]

 $Info(filter) configure 0.0

 cbs copy $s
 if [catch {$s filter $Info(filter) -start $start -end $end \
	 -progress progressCallback}] {
  $s copy cbs
  return
 }
 ::wsurf::PrepareUndo "$s swap cbs" "$s swap cbs"
}

proc DoInsertSilence {w} {
 global silence

 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set insertPos [expr {int($left*[$s cget -rate])}]

 cbs copy $s

 snack::sound _doinsertsiltmp -encoding [$s cget -encoding] \
     -rate [$s cget -rate] -channels [$s cget -channels]

 _doinsertsiltmp length [expr {int($silence(l)*[$s cget -rate])}]
 $s insert _doinsertsiltmp $insertPos
 _doinsertsiltmp destroy

 ::wsurf::PrepareUndo "$s swap cbs" "$s swap cbs"
}

proc InsertSilence {w} {
 global silence
 set tl .sil
 catch {destroy $tl}
 toplevel $tl
 wm title $tl [::util::mc "Insert Silence"]

 pack [ ttk::frame $tl.f] -fill both -expand true
 pack [ ttk::label $tl.f.l -text [::util::mc "Silence length:"]] -side left
 pack [ ttk::entry $tl.f.e -textvariable silence(l) -width 5] -side left
 pack [ ttk::label $tl.f.l2 -text seconds] -side left
 insertOKCancelButtons $tl.f3 "DoInsertSilence $w;destroy $tl" "destroy $tl"
}

proc insertOKCancelButtons {w okcmd cancelcmd} {
 pack [ ttk::frame $w] -expand true -fill both -ipadx 10 -ipady 10
 pack [ ttk::button $w.b1 -text [::util::mc OK]  \
	 -command $okcmd] -side $::ocdir -padx 3 \
	 -expand true
 pack [ ttk::button $w.b2 -text [::util::mc Cancel] \
   -command $cancelcmd] -side $::ocdir -padx 3 -expand true
}

proc insertOKCancelButtons2 {w okcmd cancelcmd} {
 set f [ ttk::frame $w]
 ttk::button $f.b1 -text [::util::mc OK] -command $okcmd
 ttk::button $f.b2 -text [::util::mc Cancel] -command $cancelcmd 
 
 grid x $f.b1 $f.b2 -pady 6 -padx 6
 grid columnconfigure $f 0 -weight 1
 grid $f
 #pack $f -side bottom -expand false -fill x
}

proc RemoveDC {} {
 variable Info
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isLinked2File]} return
 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]
 if {$start == $end} {
  $w configure -selection [list 0.0 [$s length -unit seconds]]
  set start 0
  set end -1
 }

 cbs copy $s
 if [catch {$s filter $::remdc(f) -start $start -end $end \
	 -progress progressCallback -continuedrain 0}] {
  $s copy cbs
  return
 }
 ::wsurf::PrepareUndo "$s swap cbs" "$s swap cbs"
}

proc DoConvert {w} {
 global convert

 set s [$w cget -sound]

 cbs copy $s

 if {$convert(rate) != [$s cget -rate]} {
  if {[catch {$s convert -rate $convert(rate) \
	  -progress progressCallback} ret]} {
   $s copy cbs
   if {$ret != ""} {
    error "$ret"
   }
  } else {
   set convert(rate) [$s cget -rate]
  }
 }
 if {$convert(encoding) != [$s cget -encoding]} {
  if {[catch {$s convert -encoding $convert(encoding) \
	  -progress progressCallback} ret]} {
   $s copy cbs
   if {$ret != ""} {
    error "$ret"
   }
  } else {
   set convert(encoding) [$s cget -encoding]
  }
 }
 if {$convert(channels) != [$s cget -channels]} {
  if {[catch {$s convert -channels $convert(channels) \
	  -progress progressCallback} ret]} {
   $s copy cbs
   if {$ret != ""} {
    error "$ret"
   }
  } else {
   set convert(channels) [$s cget -channels]
  }
 }

 ::wsurf::PrepareUndo "$s copy cbs" "DoConvert $w"
}

proc Convert {} {
 global convert
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isLinked2File]} return

 set s [$w cget -sound]
 set convert(rate)     [$s cget -rate]
 set convert(encoding) [$s cget -encoding]
 set convert(channels) [$s cget -channels]

 set tl .conv
 catch {destroy $tl}
 toplevel $tl
 wm title $tl [::util::mc Convert]
 wm resizable $tl 0 0

 ttk::frame $tl.q
 pack $tl.q -expand 1 -fill both -side top
 pack [ttk::frame $tl.q.f1] -side left -anchor nw -padx 3m -pady 2m
 pack [ttk::frame $tl.q.f2] -side left -anchor nw -padx 3m -pady 2m
 pack [ttk::frame $tl.q.f3] -side left -anchor nw -padx 3m -pady 2m
 pack [ttk::frame $tl.q.f4] -side left -anchor nw -padx 3m -pady 2m
 pack [ttk::label $tl.q.f1.l -text [::util::mc "Sample Rate"]]

    ttk::combobox $tl.q.f1.cb \
   -textvariable [namespace current]::convert(rate) \
   -width 7 -values [snack::audio rates]
 
 pack $tl.q.f1.cb -side left

 pack [ttk::label $tl.q.f2.l -text [::util::mc "Sample Encoding"]]
 foreach e [snack::audio encodings] {
  pack [ttk::radiobutton $tl.q.f2.r$e -text $e -value $e \
	  -variable [namespace current]::convert(encoding)] -anchor w
 }
 pack [ttk::label $tl.q.f3.l -text [::util::mc Channels]]
 pack [ttk::radiobutton $tl.q.f3.1 -text [::util::mc Mono] -value 1 \
	 -variable [namespace current]::convert(channels)] -anchor w
 pack [ttk::radiobutton $tl.q.f3.2 -text [::util::mc Stereo] -value 2 \
	 -variable [namespace current]::convert(channels)] -anchor w
 pack [ttk::radiobutton $tl.q.f3.4 -text 4 -value 4 \
	 -variable [namespace current]::convert(channels)] -anchor w
 pack [ttk::entry $tl.q.f3.e -textvariable [namespace current]::convert(channels) \
	 -width 3] -anchor w

 insertOKCancelButtons $tl.f3 "DoConvert $w;destroy $tl" "destroy $tl"
}

proc ConfAmplify {flag} {
 global amplify

 set w .amp
 if {$amplify(db) == 1} {
  $w.f.l configure -text dB
  set tmp [expr {20.0*log10(($amplify(v)+0.000000000000000001)/100.0)}]
  $w.f.s1 configure -from -96.0 -to 24.0
 } else {
  $w.f.l configure -text %
  set tmp [expr {100.0*pow(10,$amplify(v)/20.0)}]
  $w.f.s1 configure -from 0.0 -to 300.0
 }
 if {$flag} {
  set amplify(v) $tmp
   $w.f.s1 set $amplify(v)
 }
}

proc DoAmplify {w} {
 global amplify

 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]

 if {$start == $end} return

 if {$amplify(db) == 1} {
  set tmp [expr {pow(10,$amplify(v)/20.0)}]
 } else {
  set tmp [expr {$amplify(v) / 100.0}]
 }
 $amplify(f) configure $tmp

 cbs copy $s
 if [catch {$s filter $amplify(f) -start $start -end $end \
	 -progress progressCallback}] {
  $s copy cbs
  return
 }
 ::wsurf::PrepareUndo "$s swap cbs" "$s swap cbs"
}

proc Amplify {} {
 global amplify
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isLinked2File]} return
 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]
 if {$start == $end} {
  $w configure -selection [list 0.0 [$s length -unit seconds]]
 }
 set tl .amp
 catch {destroy $tl}
 toplevel $tl
 wm title $tl [::util::mc Amplify]
 wm resizable $tl 0 0

 pack [ttk::label $tl.l -text [::util::mc "Amplify by:"] -anchor w] -fill x
 pack [ ttk::frame $tl.f] -fill both -expand true
  pack [ttk::scale $tl.f.s1 -command "" -orient horizontal \
	     -variable amplify(v)] -side left
 pack [ttk::entry $tl.f.e -textvariable amplify(v) -width 5] -side left
 pack [ttk::label $tl.f.l -text xx -width 2] -side left
  pack [ttk::checkbutton $tl.cb -text [::util::mc "Decibels"] -variable amplify(db) \
	    -command [list ConfAmplify 1]] -fill both -expand true

 insertOKCancelButtons $tl.f3 "DoAmplify $w;destroy $tl" "destroy $tl"

 ConfAmplify 0
  $tl.f.s1 set $amplify(v)
}

proc DoFade {w} {
 global fade

 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set start  [expr {int($left*[$s cget -rate])}]
 set length [expr {int(($right-$left)*1000)}]
 
 if {$length == 0} return

 $fade(f) configure $fade(dir) $fade(type) $length [expr $fade(floor)/100.0]
 
 cbs copy $s
 if [catch {$s filter $fade(f) -start $start \
	 -progress progressCallback}] {
  $s copy cbs
  return
 }
 ::wsurf::PrepareUndo "$s swap cbs" "$s swap cbs"
}

proc ShowFadeType {w} {
 global fade
 switch $fade(type),$fade(dir) {
  Linear,In {
   $w coords fade 0 60 30 30 60 0
  }
  Linear,Out {
   $w coords fade 0 0 30 30 60 60
  }
  Logarithmic,In {
   $w coords fade 0 60 10 10 60 0
  }
  Logarithmic,Out {
   $w coords fade 0 0 50 10 60 60
  }
  Exponential,In {
   $w coords fade 0 60 50 50 60 0
  }
  Exponential,Out {
   $w coords fade 0 0 10 50 60 60
  }
 }
}

proc Fade {} {
 global fade
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isLinked2File]} return
 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]
 if {$start == $end} {
  $w configure -selection [list $left [expr $left+.1]]
 }
 set tl .fade
 catch {destroy $tl}
 toplevel $tl
 wm title $tl [::util::mc Fade]

 pack [ ttk::label $tl.l -text [::util::mc "Fade direction:"] -anchor c] -fill x
 pack [ ttk::frame $tl.f] -fill both -expand true
 foreach e [list In Out] {
  pack [ttk::radiobutton $tl.f.r$e -text $e -value $e \
	    -variable [namespace current]::fade(dir) \
	    -command [list ShowFadeType $tl.c]] -anchor w
 }
 
 pack [ ttk::label $tl.l2 -text [::util::mc "Fade type:"] -anchor c] -fill x
 pack [ ttk::frame $tl.f2] -fill both -expand true
 foreach e [list Linear Logarithmic Exponential] {
  pack [ttk::radiobutton $tl.f2.r$e -text $e -value $e \
	    -variable [namespace current]::fade(type) \
	    -command [list ShowFadeType $tl.c]] -anchor w
 }
 
 pack [canvas $tl.c -width 60 -height 60]
 $tl.c create line 0 0 0 0 0 0 -smooth on -tags fade
 ShowFadeType $tl.c

 pack [ ttk::frame $tl.f3] -fill x
 pack [ ttk::label $tl.f3.l -text [::util::mc "Fade floor:"]] -fill x
 pack [ ttk::frame $tl.f3.f] -fill both -expand true


  pack [ttk::scale $tl.f3.f.s1 -command "" -orient horizontal \
	 -variable fade(floor) -from 0.0 -to 100.0] -side left
  $tl.f3.f.s1 set $fade(floor)

 pack [ttk::entry $tl.f3.f.e -textvariable fade(floor) -width 5] -side left
 pack [ttk::label $tl.f3.f.l -text % -width 1] -side left


 insertOKCancelButtons $tl.f4 "DoFade $w;destroy $tl" "destroy $tl"
}

proc ConfNormalize {flag} {
 global normalize

 set w .norm
 if {$normalize(db) == 1} {
  $w.f.l configure -text dB
  set tmp [expr {20.0*log10(($normalize(v)+0.000000000000000001)/100.0)}]
  $w.f.s1 configure -from -96.0 -to 0.0
 } else {
  $w.f.l configure -text %
  set tmp [expr {100.0*pow(10,$normalize(v)/20.0)}]
  $w.f.s1 configure -from 0.0 -to 100.0
 }
 if {$flag} {
  set normalize(v) $tmp
   $w.f.s1 set $normalize(v)
 }
}

proc DoNormalize {w} {
 global normalize

 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [util::min [expr {int($right*[$s cget -rate])}] \
     [expr {[$s length]-1}]]

 if {$start == $end} return

 if {$normalize(db) == 1} {
     set tmp [expr {pow(10,$normalize(v)/20.0)}]
 } else {
     set tmp [expr {$normalize(v) / 100.0}]
 }
 if {[string match [$s cget -encoding] Lin8]} {
     set smax 255.0
 } elseif {[string match Lin24* [$s cget -encoding]]} {
     set smax 8388607.0
 } else {
     set smax 32767.0
 }
 for {set c 0} {$c < [$s cget -channels]} {incr c} {
  if {$normalize(allEqual)} {
   set max [$s max -start $start -end $end]
   set min [$s min -start $start -end $end]
  } else {
   set max [$s max -start $start -end $end -channel $c]
   set min [$s min -start $start -end $end -channel $c]
  }
  if {$max < -$min} {
   set max [expr {-$min}]
   if {$max > $smax} {
    set max $smax
   }
  }
  if {$max == 0} {
   set max 1.0
  }
  set factor [expr {$tmp * $smax / $max}]
  lappend factors $factor
  if {$normalize(allEqual)} break
  if {$c < [expr {[$s cget -channels] - 1}]} {
   for {set i 0} {$i < [$s cget -channels]} {incr i} {
    lappend factors 0.0
   }
  }
 }
 eval $normalize(f) configure $factors
 cbs copy $s
 if [catch {$s filter $normalize(f) -start $start -end $end \
   -progress snack::progressCallback}] {
  SetMsg [::util::mc "Normalize cancelled"]
  $s copy cbs
  return
 }

 ::wsurf::PrepareUndo "$s swap cbs" "$s swap cbs"
}

proc Normalize {} {
 global normalize
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isLinked2File]} return
 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]
 if {$start == $end} {
  $w configure -selection [list 0.0 [$s length -unit seconds]]
 }

 set tl .norm
 catch {destroy $tl}
 toplevel $tl
 wm title $tl [::util::mc Normalize]

    ttk::label $tl.l -text [::util::mc "Normalize to:"]
 ttk::frame $tl.f

  pack [ttk::scale $tl.f.s1 -command "" -orient horizontal \
	    -variable normalize(v) -from 0.0 -to 100.0] -side left
  $tl.f.s1 set $normalize(v)

 pack [ttk::entry $tl.f.e -textvariable normalize(v) -width 5] -side left
 pack [ttk::label $tl.f.l -text xx -width 2] -side left
  ttk::checkbutton $tl.cb1 -text [::util::mc "Decibels"] \
      -variable normalize(db) \
      -command [list ConfNormalize 1]
  ttk::checkbutton $tl.cb2 \
      -text [::util::mc "Normalize all channels equally"] \
      -variable normalize(allEqual)

 grid $tl.l  -sticky ew
 grid $tl.f  -sticky ew
 grid $tl.cb1  -sticky ew
 grid $tl.cb2  -sticky ew
 grid columnconfigure $tl 0 -weight 1 ;# vad gör denna?

 insertOKCancelButtons2 $tl.f3 "DoNormalize $w;destroy $tl" "destroy $tl"

 if {[$s cget -channels] == 1} {
  $tl.cb2 configure -state disabled
 } else {
  $tl.cb2 configure -state normal
 }
 ConfNormalize 0
}

proc Normalize {} {
 global normalize
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isLinked2File]} return
 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]
 if {$start == $end} {
  $w configure -selection [list 0.0 [$s length -unit seconds]]
 }

 set tl .norm
 catch {destroy $tl}
 toplevel $tl
 wm title $tl [::util::mc Normalize]

 pack [ttk::label $tl.l -text [::util::mc "Normalize to:"]] -fill x
 pack [ttk::frame $tl.f] -fill both -expand true

  pack [ttk::scale $tl.f.s1 -command "" -orient horizontal \
	    -variable normalize(v) -from 0.0 -to 100.0] -side left
  $tl.f.s1 set $normalize(v)

 pack [ttk::entry $tl.f.e -textvariable normalize(v) -width 5] -side left
 pack [ttk::label $tl.f.l -text xx -width 2] -side left
  pack [ttk::checkbutton $tl.cb1 -text [::util::mc "Decibels"] \
      -variable normalize(db) \
	    -command [list ConfNormalize 1]] -fill both -expand true
  pack [ttk::checkbutton $tl.cb2 \
      -text [::util::mc "Normalize all channels equally"] \
      -variable normalize(allEqual)] -fill both -expand true

 insertOKCancelButtons $tl.f3 "DoNormalize $w;destroy $tl" "destroy $tl"

 if {[$s cget -channels] == 1} {
  $tl.cb2 configure -state disabled
 } else {
  $tl.cb2 configure -state normal
 }
 ConfNormalize 0
}

proc ConfEcho {args} {
 global echo

 set iGain [expr {0.01 * $echo(iGain)}]
 set oGain [expr {0.01 * $echo(oGain)}]
 set values "$iGain $oGain "
 for {set i 1} {$i <= $echo(n)} {incr i} {
  if {![info exists echo(delay$i)]} {
    set echo(delay$i) 220.0
  }
  if {![info exists echo(decay$i)]} {
    set echo(decay$i) 60
  }
  set decay [expr {0.01 * $echo(decay$i)}]
  append values "$echo(delay$i) $decay "
 }
 
 eval $echo(f) configure $values
}

proc DoEcho {w} {
 global echo

 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]

 if {$start == $end} return

 ConfEcho

 cbs copy $s
 if [catch {$s filter $echo(f) -start $start -end $end \
	 -continuedrain $echo(drain) \
	 -progress progressCallback}] {
     $s copy cbs
     return
 }
 
 ::wsurf::PrepareUndo "$s swap cbs" "$s swap cbs"
}

proc PlayEcho {w} {
 global echo

 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]

 if {$start == $end} return

 ConfEcho

 $s stop
 $s play -filter $echo(f) -start $start -end $end
}

proc AddEcho {} {
 global echo

 if {$echo(n) > 9} return
 set tl .proc
 incr echo(n)
 AddEchoW $echo(n)
 if {$echo(n) > 1} {
  $tl.f.fe.2 configure -state normal
 }
 if {$echo(n) > 9} {
  $tl.f.fe.1 configure -state disabled
 }
}

proc AddEchoW {n} {
    global echo
    
    set tl .proc
    set f [expr {$n + 2}]
    ttk::separator $tl.f.f$f -orient vertical
    pack $tl.f.f$f -side left -before $tl.f.hidden
    if {![info exists echo(delay$n)]} {
	set echo(delay$n) 30.0
	set echo(delayI$n) 30.0
    }
    pack [ttk::label $tl.f.f$f.l -text [::util::mc "Echo $n"] -anchor c] -side top \
	-fill x
    pack [ttk::frame $tl.f.f$f.f1] -side left
    pack [ttk::scale $tl.f.f$f.f1.s -from 10.0 -to 250.0 -orient vertical \
	      -variable echo(delayI$n) -command "FlipScaleValue ::echo(delayI$n) ::echo(delay$n) 260.0;ConfEcho"]
    
    $tl.f.f$f.f1.s set $echo(delay$n)
    pack [ttk::frame $tl.f.f$f.f1.f]
    pack [ttk::entry $tl.f.f$f.f1.f.e -textvariable echo(delay$n) -width 3] \
	-side left
    pack [ttk::label $tl.f.f$f.f1.f.l -text ms] -side left
    
    if {![info exists echo(decay$n)]} {
	set echo(decay$n) 40
	set echo(decayI$n) 40
    }
    pack [ttk::frame $tl.f.f$f.f2] -side left
    pack [ttk::scale $tl.f.f$f.f2.s -from 0 -to 100 -orient vertical \
	      -variable echo(decayI$n) -command "FlipScaleValue ::echo(decayI$n) ::echo(decay$n) 100.0;ConfEcho"]
    
    $tl.f.f$f.f2.s set $echo(decay$n)
    
    pack [ttk::frame $tl.f.f$f.f2.f]
    pack [ttk::entry $tl.f.f$f.f2.f.e -textvariable echo(decay$n) -width 3] \
	-side left
    pack [ttk::label $tl.f.f$f.f2.f.l -text %] -side left
}

proc RemEcho {} {
 global echo

 if {$echo(n) < 2} return

 set tl .proc
 set f [expr {$echo(n) + 2}]
 destroy $tl.f.f$f
 incr echo(n) -1
 if {$echo(n) < 2} {
  $tl.f.fe.2 configure -state disabled
 }
 $tl.f.fe.1 configure -state normal
}

proc FlipScaleValue {scaleVar var max} {
 set $var [expr $max-[set $scaleVar]]
}

proc Echo {} {
 global echo
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isLinked2File]} return
 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]
 if {$start == $end} {
  $w configure -selection [list 0.0 [$s length -unit seconds]]
 }
 set tl .proc
 catch {destroy $tl}
 toplevel $tl
 wm title $tl [::util::mc Echo]

 pack [ttk::frame $tl.f] -expand true -fill both
 
 pack [ttk::frame $tl.f.f1] -side left
 pack [ttk::label $tl.f.f1.l -text [::util::mc In]]
  pack [ttk::scale $tl.f.f1.s -from 0 -to 100 -orient vertical \
	    -variable echo(iGainI) -command "FlipScaleValue ::echo(iGainI) ::echo(iGain) 100.0;ConfEcho"]
  $tl.f.f1.s set $echo(iGain)

 pack [ttk::frame $tl.f.f1.f]
 pack [ttk::entry $tl.f.f1.f.e -textvariable echo(iGain) -width 3] -side left
 pack [ttk::label $tl.f.f1.f.l -text %] -side left

 pack [ttk::frame $tl.f.f2] -side left
 pack [ttk::label $tl.f.f2.l -text [::util::mc Out]]
  pack [ttk::scale $tl.f.f2.s -from 0 -to 100 -orient vertical \
	    -variable echo(oGainI) -command  "FlipScaleValue ::echo(oGainI) ::echo(oGain) 100.0;ConfEcho"]

  $tl.f.f2.s set $echo(oGain)

 pack [ttk::frame $tl.f.f2.f]
 pack [ttk::entry $tl.f.f2.f.e -textvariable echo(oGain) -width 3] -side left
 pack [ttk::label $tl.f.f2.f.l -text %] -side left

 pack [ttk::frame $tl.f.fe] -side left
  pack [ttk::button $tl.f.fe.1 -text + -command AddEcho] -padx 3
  pack [ttk::button $tl.f.fe.2 -text - -command RemEcho -state disabled] -padx 3

 pack [ttk::frame $tl.f.hidden] -side left
 for {set i 1} {$i <= $echo(n)} {incr i} {
     AddEchoW $i
 }
  pack [ttk::checkbutton $tl.cb -text [::util::mc "Drain beyond selection"] \
	    -variable echo(drain)] -anchor w -fill x
 
 pack [ ttk::frame $tl.f3] -pady 0 -expand true -fill both
 pack [ ttk::button $tl.f3.b1 -style Toolbutton -image $::wsurf::Info(Img,play) -command "PlayEcho $w"] \
	 -side left -padx 3 
 pack [ ttk::button $tl.f3.b2 -style Toolbutton -image $::wsurf::Info(Img,stop) -command "$w stop"] -side left \
     -padx 3

 insertOKCancelButtons $tl.f4 "DoEcho $w;destroy $tl" "destroy $tl"

}

proc ConfMix {w args} {
 global mix

 set s [$w cget -sound]

 set n [$s cget -channels]
 for {set i 0} {$i < $n} {incr i} {
  for {set j 0} {$j < $n} {incr j} {
   set val [expr {0.01 * $mix($i,$j)}]
   append values "$val "
  }
 }
 eval $mix(f) configure $values
}

proc DoMix {w} {
 global mix

 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]

 if {$start == $end} return
 
 ConfMix $w
 
 cbs copy $s
 if [catch {$s filter $mix(f) -start $start -end $end \
   -progress progressCallback}] {
  $s copy cbs
  return
 }

 ::wsurf::PrepareUndo "$s swap cbs" "$s swap cbs"
}

proc PlayMix {w} {
 global mix

 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]
 if {$start == $end} return
 
 ConfMix $w
 
 $s stop
 $s play -filter $mix(f) -start $start -end $end
}

proc MixChan {} {
 global mix
 set w [::wsurf::GetCurrent]
 BreakIfInvalid $w
 if {[$w getInfo isLinked2File]} return
 foreach {left right} [$w cget -selection] break
 set s [$w cget -sound]
 set start [expr {int($left*[$s cget -rate])}]
 set end   [expr {int($right*[$s cget -rate])}]
 if {$start == $end} {
  $w configure -selection [list 0.0 [$s length -unit seconds]]
 }
 set tl .mix
 catch {destroy $tl}
 toplevel $tl
 wm title $tl [::util::mc "Mix Channels"]
 
 pack [ttk::frame $tl.f] -expand true -fill both
 
 ttk::label $tl.f.l -text [::util::mc "New channel"]
 grid $tl.f.l
 
 set n [$s cget -channels]
 
 for {set i 0} {$i < $n} {incr i} {
  for {set j 0} {$j < $n} {incr j} {
   if {![info exists mix($i,$j)]} {
    if {$i == $j} {
     set mix($i,$j) 100
    } else {
     set mix($i,$j) 0
    }
   }
  }
 }
 for {set i 0} {$i < $n} {incr i} {
  if {$i == 0} {
   set label Left
  } elseif {$i == 1} {
   set label Right
  } else {
   set label [expr {$i + 1}]
  }
     ttk::label $tl.f.ly$i -text $label
  grid $tl.f.ly$i -row [expr {$i + 1}] -column 0
     ttk::label $tl.f.lx$i -text [::util::mc "Channel $label"]
  grid $tl.f.lx$i -row 0 -column [expr {$i + 1}]
  for {set j 0} {$j < $n} {incr j} {
      ttk::frame $tl.f.f$i-f$j
   grid $tl.f.f$i-f$j -row [expr {$i + 1}] -column [expr {$j + 1}] -padx 5
    pack [ttk::scale $tl.f.f$i-f$j.s -orient horizontal \
	      -from -100 -to 100 -command "ConfMix $w" \
	      -variable mix($i,$j)]

    $tl.f.f$i-f$j.s set $mix($i,$j)

   pack [ttk::frame $tl.f.f$i-f$j.f]	  
   pack [ttk::entry $tl.f.f$i-f$j.f.e -textvariable mix($i,$j) -width 4] \
     -side left
   pack [ttk::label $tl.f.f$i-f$j.f.l -text %] -side left
  }
 }
 
 pack [ttk::frame $tl.f3] -expand true -fill both
 pack [ ttk::button $tl.f3.b1 -style Toolbutton -image $::wsurf::Info(Img,play) -command "PlayMix $w"] \
   -side left -padx 3 -anchor c
 pack [ ttk::button $tl.f3.b2 -style Toolbutton -image $::wsurf::Info(Img,stop) -command "$w stop"] \
   -side left -padx 3 -anchor c

 insertOKCancelButtons $tl.f4 "DoMix $w;destroy $tl" "destroy $tl"
}

# -----------------------------------------------------------------------------
# PreferencesDialog

proc PreferencesDialog {} {
 destroy .prefs
 toplevel .prefs
 wm title .prefs [::util::mc Preferences]
    wm resizable .prefs 0 0

 pack [ttk::frame .prefs.f] -side bottom -expand 0 -fill x -ipadx 10 -ipady 10
 pack [ttk::button .prefs.f.b1 -text [::util::mc OK] -width 8 -default active \
     -command "destroy .prefs;SavePreferences"] -side $::ocdir -padx 3 -expand true
 pack [ttk::button .prefs.f.b2 -text [::util::mc Cancel] -width 8 \
     -command "destroy .prefs"] -side $::ocdir -padx 3 -expand true
 pack [ttk::button .prefs.f.b3 -text [::util::mc Defaults] \
     -command SetDefaultPrefs] -side left -padx 3 -expand true 
 pack [ttk::button .prefs.f.b4 -text [::util::mc Apply] -width 8 \
     -command ApplyPreferences] -side left -padx 3 -expand true

 set notebook .prefs.nb
 set pages {}
 lappend pages [::util::mc "Keys"]
 lappend procs KeyBindingsPage

 foreach {title pageProc} [::wsurf::PreferencePages] {
  if {$title != ""} {
   lappend pages $title
   lappend procs $pageProc
  }
 }
    ttk::notebook $notebook -padding 6

 pack $notebook -fill both -expand yes
 if {[string match macintosh $::tcl_platform(platform)] || \
	 [string match Darwin $::tcl_platform(os)]} {
  update
 }
 foreach page $pages proc $procs {
   set lowpage [string tolower $page]
   $notebook add [ttk::frame $notebook.$lowpage] -text $page
   $proc $notebook.$lowpage
 }
  $notebook select 2
}


set Prefs(Table) [list \
		      PlaySelection PlaySelection "Play whole selection" \
		      PlayCursor [list PlayAtCursor %x] "Play at cursor" \
		      PlayAll PlayAll "Play whole sound" \
		      PlayVisible PlayVisible "Play visible sound" \
		      PlayLoop PlayLoop "Play loop" \
	   LockMessageBar [list lockMessageBar %W] "Toggle message bar lock" \
		      PlayPause PlayPause "Toggle play/pause" \
		      PlayStop PlayStop "Toggle play/stop" \
		      "x0" "" "File menu" \
		      Revert Revert "Revert" \
		      Chooser Chooser "Chooser..." \
		      SaveSelection SaveSelection "Save Selection..." \
		      ShowConsole ShowConsole "Show Console..." \
		      Print Print "Print..." \
		      Prefs PreferencesDialog "Preferences..." \
		      "x1" "" "Edit menu" \
		      MixPaste MixPaste "Mix Paste..." \
		      SelectAll SelectAll "Select All" \
		      SelectoNew SelectoNew "Selection to New" \
		      ZeroXAdjust ZeroXAdjust "Zero Cross Adjust" \
		      "x2" "" "Transform menu" \
		      Convert Convert "Convert..." \
		      Amplify Amplify "Amplify..." \
		      Fade Fade "Fade..." \
		      Normalize Normalize "Normalize..." \
		      Echo Echo "Echo..." \
		      MixChan MixChan "Mix Channels..." \
		      Invert Invert "Invert" \
		      Reverse Reverse "Reverse" \
		      Silence Silence "Silence" \
		      RemoveDC RemoveDC "RemoveDC" \
		      "x3" "" "View menu" \
		      ZoomIn ZoomIn "Zoom In" \
		      ZoomOut ZoomOut "Zoom Out" \
		      ZoomFullOut ZoomAll "Zoom Out Full" \
		      ZoomToSelection ZoomSel "Zoom to Selection" \
		     ]

# -----------------------------------------------------------------------------
# SavePreferences

proc SavePreferences {} {
 variable Info

 ApplyPreferences

 set pf $Info(PrefsFile)
 set f [open $pf w]

 set confspec [string trim [eval ::wsurf::GetPreferences]]
 foreach line [split $confspec \n] {
  puts $f $line
 }

 foreach {prefKey script text} $::Prefs(Table) {
  puts $f "set ::Info(Prefs,$prefKey) \{$Info(Prefs,$prefKey)\}"
 }

 close $f
}

proc ApplyPreferences {} {
 variable Info

 foreach {prefKey script text} $::Prefs(Table) {
  if {[info exists Info(Prefs,t,$prefKey)]} {
   set Info(Prefs,$prefKey) $Info(Prefs,t,$prefKey)
  }
 }

 foreach tl $::Info(toplevels) {
  BindKeys $tl
 }

 ::wsurf::ApplyPreferences
}

proc SetDefaultPrefs {} {
 ::wsurf::SetDefaultPrefs
}

proc KeyBindingsPage {p} {
    variable Info
    
    foreach {prefKey script text} $::Prefs(Table) {
	set Info(Prefs,t,$prefKey) $Info(Prefs,$prefKey)
    }
    
    set t $p.canv

    canvas $t -yscrollcommand [list $p.scroll set] -highlightthickness 0 -borderwidth 0 -height 500
#    text $t -yscrollcommand "$p.scroll set" -setgrid true -width 50 \
#	-height 10 -wrap word -highlightthickness 0 -borderwidth 0 \
#	-tabs {5c left}

    set f $t.frame
    $t create window 0 0 -anchor nw -window [ttk::frame $f] -tags frame

    bind $t <Configure> [list $t itemconfigure frame -width %w]
    bind $f <Configure> [list $t configure -scrollregion "0 0 %w %h"]

    ttk::scrollbar $p.scroll -orient vertical -command [list $t yview]
#    scrollbar $p.scroll -orient vertical -command [list $t yview]
    
    grid $t $p.scroll -sticky news
    grid columnconfigure $p 0 -weight 1
    set subi 0
    set subframe $f.l[incr subi]
    pack [ttk::labelframe $subframe] -fill x -expand 1 -side top
    foreach {prefKey script text} $::Prefs(Table) {
	if {$script == ""} {
	    set subframe $f.l[incr subi]
	    pack [ttk::labelframe $subframe -text [::util::mc ${text}]] -fill x -side top -expand 1
	} else {
	    ttk::label $subframe.l$prefKey -width 15 -text [::util::mc ${text}]
	    ttk::entry $subframe.e$prefKey -width 15 -textvar Info(Prefs,t,$prefKey)
	    grid $subframe.l$prefKey $subframe.e$prefKey -sticky we
	    grid columnconfigure $subframe 0 -weight 1
	    grid columnconfigure $subframe 1 -weight 0
	}
    }
    $t configure -state disabled
}

# GetCTTRegVars
# - check if CTT-Toolbox is installed. 
#   If it is, modify auto_path to include Toolbox directories

proc GetCTTRegVars {} {
 switch $::tcl_platform(platform) {
  windows {
   package require registry
   set key [join [list HKEY_LOCAL_MACHINE SOFTWARE CTT] \\]
   catch {
    set cttroot [registry get $key Root]
   }
  }
  unix {
   if {[info exists ::env(CTTROOT)]} {
    set cttroot $::env(CTTROOT)
   }
  }
 }
 
 if {![info exists cttroot]} return
 
 lappend ::auto_path [file join $cttroot pkg]
}


proc GetWSRegVars {} {
 if [string match windows $::tcl_platform(platform)] {
  package require registry
  set key [join [list HKEY_LOCAL_MACHINE SOFTWARE CTT WAVESURFER $::version] \\]
  catch {
   foreach d [split [registry get $key CONFIGDIR] ;] {
    lappend ::surf(configpath) $d
   }
  }
  catch {
   foreach d [split [registry get $key PLUGINDIR] ;] {
    lappend ::surf(pluginpath) $d
   }
  }
 }
}

# -----------------------------------------------------------------------------

proc CheckRegTypes {} {
 package require registry

 foreach ext $::surf(extensions) {
#  puts ext=$ext
  if {[catch {
   set class [registry get [join [list HKEY_CLASSES_ROOT $ext] \\] ""]
  }]} {
   set x($ext,assoc) 0
  } else {
#   puts class=$class
   set shellops [registry keys [join [list HKEY_CLASSES_ROOT $class shell] \\]]
   if {[lsearch -glob $shellops *WaveSurfer*]==-1} {
    set x($ext) 0
   } else {
    set x($ext) 1
   }
  }
 }
 return [array get x]
}


proc RegTypes {list} {
 package require registry

 array set conf $list
 #parray conf

 foreach key [array names conf *,assoc] {
  set ext [lindex [split $key ,] 0]
  if {[catch {
   set class [registry get [join [list HKEY_CLASSES_ROOT $ext] \\] ""]
  }]} {
   set class [string trimleft $ext .]file
   registry set [join [list HKEY_CLASSES_ROOT $ext] \\] "" $class
   registry set [join [list HKEY_CLASSES_ROOT $class] \\] "" "[string toupper [string trimleft $ext .]] sound format"
  }

  set base HKEY_CLASSES_ROOT\\$class\\shell

  if {$conf($ext,default)} {
   registry set $base "" ws.play
  }
  registry set $base\\ws.play "" "&Play using WaveSurfer"
  registry set $base\\ws.open "" "&Open using WaveSurfer"
  registry set $base\\ws.play\\command "" "$::surf(appname) -play"
  registry set $base\\ws.open\\command "" "$::surf(appname)"
  if {$conf($ext,dde)} {
   registry set $base\\ws.play\\ddeexec "" "PlayFile {%1}"
   registry set $base\\ws.open\\ddeexec "" "OpenFile {%1}"
   registry set $base\\ws.play\\ddeexec\\Application "" TclEval
   registry set $base\\ws.open\\ddeexec\\Application "" TclEval
   registry set $base\\ws.play\\ddeexec\\Topic "" WaveSurfer
   registry set $base\\ws.open\\ddeexec\\Topic "" WaveSurfer
  }
 }
}



proc RegTypesDialog {} {
 set w [toplevel .x.regTypes]
 wm title $w [::util::mc "Associate File Types"]

 set i 0
 ttk::label $w.l$i -anchor w -justify left -text [::util::mc "Check \"Associate\" to add WaveSurfer as a handler for a file type\nCheck \"Make default\" to make WaveSurfer the default handler for a file type\nCheck \"Use DDE\" to use a single instance of WaveSurfer for multiple files"]
   
 grid $w.l$i -row $i -sticky nswe -columnspan 4 -ipady 5
 incr i
 ttk::label $w.a$i -text [::util::mc "File type"]
 ttk::label $w.b$i -text [::util::mc "Associate"]
 ttk::label $w.c$i -text [::util::mc "Make default"]
 ttk::label $w.d$i -text [::util::mc "Use DDE"]
 grid $w.a$i $w.b$i $w.c$i $w.d$i -row $i -sticky we
 incr i
 foreach ext $::surf(extensions) {
  set ::_RegTypesDialog($ext,assoc) 1
  set ::_RegTypesDialog($ext,default) 0
  set ::_RegTypesDialog($ext,dde) 1
  ttk::label $w.l$i -text $ext
  ttk::checkbutton $w.a$i -variable _RegTypesDialog($ext,assoc) -command [list \
    if \$_RegTypesDialog($ext,assoc) [list $w.b$i configure -state normal]\n[list $w.c$i configure -state normal] else [list $w.b$i configure -state disabled]\n[list $w.c$i configure -state disabled]]
  ttk::checkbutton $w.b$i -variable _RegTypesDialog($ext,default)
  ttk::checkbutton $w.c$i -variable _RegTypesDialog($ext,dde)
  grid $w.l$i $w.a$i $w.b$i $w.c$i -row $i -sticky nswe
  incr i
 }
# insertOKCancelButtons $w.bf [list set _RegTypesDialog(selection) ok] \
   [list set _RegTypesDialog(selection) cancel]
 ttk::button $w.ok -text [::util::mc "OK"] -command [list set _RegTypesDialog(selection) ok]
 ttk::button $w.cancel -text [::util::mc "Cancel"] -command [list set _RegTypesDialog(selection) cancel]
 grid $w.ok $w.cancel -columnspan 2 -row $i -sticky nswe -ipadx 20 -ipady 5
 vwait ::_RegTypesDialog(selection)
 destroy $w
 if {[string match ok $::_RegTypesDialog(selection)]} {
  RegTypes [array get ::_RegTypesDialog]
  tk_messageBox -message [::util::mc "The specified file associations have been created"]
 }
}

proc About {} {
 tk_messageBox -title "About WaveSurfer" -message "@ABOUTWAVESURFER@\n"
}

if {![string match macintosh $::tcl_platform(platform)]} {
    rename source _source
    proc source {args} {
	incr ::splash::filecount
	set ::splash::progress "$::splash::filecount"
	update idletasks
	uplevel _source $args
    }
}

if {[string match macintosh $::tcl_platform(platform)]} {
  console hide
  option add *background lightgrey
  option add *Entry.background white
}

package require -exact wsurf $version

if {$tcl_version<8.2} {
 set Info(Version) 1.1
} else {
 set Info(Version) [package present wsurf]
}

set surf(count) 0
set surf(interrupted) 1
set surf(locked) 0
set surf(tmpfiles) ""

if {![file readable $env(HOME)]} {
  if {![file readable [file join [util::tmpdir] .wavesurfer]]} {
    lower .splash
    tk_messageBox -message "Unable to use home directory [file join $env(HOME) .wavesurfer].\nWill use [file join [util::tmpdir] .wavesurfer] instead"
    raise .splash
  }
  set env(HOME) [util::tmpdir]
}
# Use lappend instead of set here since env(HOME) might contain spaces
lappend userplugindir [file join $env(HOME) .wavesurfer $version plugins]
lappend userconfigdir [file join $env(HOME) .wavesurfer $version configurations]

set surf(pluginpath) $userplugindir
set surf(configpath) $userconfigdir

set oldHomes [list [file join $env(HOME) .wavesurfer 1.0] \
		  [file join $env(HOME) .wavesurfer 1.1] \
		  [file join $env(HOME) .wavesurfer 1.2] \
		  [file join $env(HOME) .wavesurfer 1.3] \
		  [file join $env(HOME) .wavesurfer 1.4] \
		  [file join $env(HOME) .wavesurfer 1.5] \
		  [file join $env(HOME) .wavesurfer 1.6] \
		  [file join $env(HOME) .wavesurfer 1.7]]
set newHome [file join $env(HOME) .wavesurfer $version]
set lastVersion [file join $env(HOME) .wavesurfer 1.0]
set newVersion 0
foreach home $oldHomes {
 if {[file exists $home] && ![file exists [lindex $surf(configpath) 0]]} {
  set lastVersion $home
  set newVersion 1
 }
}

GetCTTRegVars
GetWSRegVars

if {![file exists [lindex $userplugindir 0]]} {
 file mkdir [lindex $userplugindir 0]
}
if {![file exists [lindex $userconfigdir 0]]} {
 file mkdir [lindex $userconfigdir 0]
}

if {[info exists ::wrap]} {
 set surf(appname) "\"[file nativename [info nameofexecutable]]\""
} else {
 set surf(appname) "\"[file nativename [info nameofexecutable]]\" \"[info script]\""
}

set Info(Prefs,wsWidth) 600
set Info(Prefs,wsLeft)  20
set Info(Prefs,wsTop)   20
set Info(geometryFile) [file join $::env(HOME) .wavesurfer $Info(Version) \
    geometry]
if {[file readable $Info(geometryFile)]} { source $Info(geometryFile) }

wm withdraw .
toplevel .x
#wm iconbitmap .x snackPlay
set Info(toplevels) .x
wm withdraw .x
wm title .x "WaveSurfer @RELEASE@"
wm minsize .x 200 1
wm resizable .x 1 0
wm protocol .x WM_DELETE_WINDOW [list KillWindow .x]
wm geometry .x +$Info(Prefs,wsLeft)+$Info(Prefs,wsTop)

if {$::tcl_platform(os) == "Darwin"} {
 set AccKey Command
 set AccKeyM Command
} elseif {$::tcl_platform(platform) == "unix"} {
 set AccKey Alt
 set AccKeyM Alt
} else {
 set AccKey Control
 set AccKeyM Ctrl
}

proc Binding2Text binding {
 if {[string match *-? $binding] == 0} { return $binding }
 foreach {key1 key2} [split $binding -] break
 return "$key1+[string toupper $key2]"
}

proc CreateMenus {p} {
 set m [menu $p.menu]
 set m2 [menu $p.dummy]
 $m add cascade -label [::util::mc "File"] -menu $m.file -underline 0
 $m2 add cascade -label [::util::mc "File"]
 menu $m.file -tearoff 0 -postcommand [list ConfigureFileMenu $m]
 $m.file add command -label [::util::mc "New"] -command [list New] \
   -accelerator $::AccKeyM+N
 $m.file add command -label [::util::mc "Open..."] \
   -command [list Open] -accelerator $::AccKeyM+O
 $m.file add command -label [::util::mc "Revert"] \
     -command [list Revert]
 $m.file add command -label [::util::mc "Chooser..."] \
     -command [list Chooser]
 $m.file add separator
 $m.file add command -label [::util::mc "Save"] \
   -command [list Save] -accelerator $::AccKeyM+S
 $m.file add command -label [::util::mc "Save As..."] \
   -command [list SaveAs]
 $m.file add command -label [::util::mc "Save Selection..."] \
   -command [list SaveSelection]
 $m.file add separator
 set ::fileMenuIndex 13
# if 1 {
#  set tkconfile [file join [file dirname [info script]] tkcon.tcl]
#  if {[info command console]!="" || [file exists $tkconfile]} {
   $m.file add command -label [::util::mc "Show Console..."] \
     -command ShowConsole
   $m.file add separator
   incr ::fileMenuIndex 2
#  }
# }
 
 $m.file add command -label [::util::mc "Print..."] -command Print
 $m.file add separator
 $m.file add command -label [::util::mc "Preferences..."] \
		     -command PreferencesDialog

 if {$::tcl_platform(platform) == "unix"} {
  $m.file add command -label [::util::mc "Mixer..."] \
      -command snack::mixerDialog
  incr ::fileMenuIndex
 }
 if {$::tcl_platform(platform) == "windows"} {
  $m.file add command -label [::util::mc "Associate File Types..."] \
    -command RegTypesDialog
  incr ::fileMenuIndex
 }
 
 set recentfilesfile [file join $::env(HOME) .wavesurfer $::Info(Version) \
   recent-files]
 if {[file readable $recentfilesfile]} {source $recentfilesfile}
 if {[info exists ::recentFiles]} {
  $m.file add separator
  foreach e $::recentFiles {
   set l $e
   if {[string length $e] > 30} {
    set l ...[string range $e [expr {[string length $e]-30}] end]
   }
   $m.file add command -label $l -command [list OpenFile $e]
  }
 }
 
 $m.file add separator
 $m.file add command -label [::util::mc Close] -command [list Close $p] \
   -accelerator $::AccKeyM+W
 if {$::tcl_platform(os) != "Darwin"} {
  $m.file add command -label [::util::mc Exit] -command Exit
 }
 $m add cascade -label [::util::mc Edit] -menu $m.edit -underline 0
 $m2 add cascade -label [::util::mc Edit]
 menu $m.edit -tearoff 0 -postcommand [list ConfigureEditMenu $m]
 $m.edit add command -label [::util::mc Undo] -command Undo
 $m.edit add separator
 $m.edit add command -label [::util::mc Cut] -command Cut \
     -accelerator $::AccKeyM+X
 $m.edit add command -label [::util::mc Copy] -command Copy \
     -accelerator $::AccKeyM+C
 $m.edit add command -label [::util::mc Paste] -command Paste \
     -accelerator $::AccKeyM+V
 $m.edit add command -label [::util::mc "Mix Paste..."] -command MixPaste
 $m.edit add separator
 $m.edit add command -label [::util::mc "Select All"] -command SelectAll 
 $m.edit add command -label [::util::mc "Selection to New"] \
     -command SelectoNew
 $m.edit add command -label [::util::mc "Zero Cross Adjust"] \
     -command ZeroXAdjust

 $m add cascade -label [::util::mc Transform] -menu $m.trans -underline 0
 $m2 add cascade -label [::util::mc Transform]
 menu $m.trans -tearoff 0 -postcommand [list ConfigureTransformMenu $m]
 $m.trans add command -label [::util::mc Convert...] -command Convert
 $m.trans add command -label [::util::mc Amplify...] -command Amplify
 $m.trans add command -label [::util::mc Fade...] -command Fade \
   -accelerator $::AccKeyM+D
 $m.trans add command -label [::util::mc Normalize...] -command Normalize
 $m.trans add command -label [::util::mc Echo...] -command Echo
 $m.trans add command -label [::util::mc "Mix Channels..."] -command MixChan
 $m.trans add command -label [::util::mc Invert] -command Invert
 $m.trans add command -label [::util::mc Reverse] -command Reverse
 $m.trans add command -label [::util::mc Silence] -command Silence
 $m.trans add command -label [::util::mc "Remove DC"] -command RemoveDC
 
 menu $m.view -tearoff 0 -postcommand [list ConfigureViewMenu $m]
 set slaves [menu $m.view.slaves -tearoff 0]
 $m.view add cascade -label [::util::mc "Master Sound"] \
   -command proctrace::showTraceGUI -menu $slaves
 $m add cascade -label [::util::mc View] -menu $m.view
 $m2 add cascade -label [::util::mc View] -menu $m.view
 $m.view add command -label [::util::mc "Zoom In"] -command ZoomIn
 $m.view add command -label [::util::mc "Zoom Out"] -command ZoomOut
 $m.view add command -label [::util::mc "Zoom Out Full"] -command ZoomAll
 $m.view add command -label [::util::mc "Zoom to Selection"] -command ZoomSel
 $m.view add separator
 $m.view add command -label [::util::mc "10 mm/s"] -command [list Zoom 10]
 $m.view add command -label [::util::mc "50 mm/s"] -command [list Zoom 50]
 $m.view add command -label [::util::mc "100 mm/s"] -command [list Zoom 100]
 $m.view add command -label [::util::mc "250 mm/s"] -command [list Zoom 250]


 if {[info commands proctrace::showTraceGUI]!=""} {
  menu $m.debug -tearoff 0
  $m.debug add command -label [::util::mc "Trace Procedure Calls"] \
    -command proctrace::showTraceGUI
 $m add cascade -label [::util::mc Debug] -menu $m.debug
  
  set level [menu $m.debug.level -tearoff 0]
  $m.debug add cascade -label [::util::mc "Snack Trace Level"] \
    -command proctrace::showTraceGUI -menu $level
  $m.debug.level add radiobutton -label [::util::mc "None"] -value 0 \
    -variable ::wsurf::Info(debug) -command proctrace::configureSnackDebug
  foreach level {1 2 3 4 5} {
   $m.debug.level add radiobutton -label [::util::mc "Level $level"] \
       -value $level \
       -variable ::wsurf::Info(debug) -command proctrace::configureSnackDebug
  }
  #  wsurf::_callback nowidget addMenuEntriesProc nopane $m help 0 0
  # proctrace::showTraceGUI
 }

 # search for a local version of the manual. This can be in different places
 # depending on whether we're running wrapped, source or development version.
 # Use web-url as fallback.
 set manurl http://www.speech.kth.se/wavesurfer/man$::version_major$::version_minor.html
 foreach manpath [list \
   [info nameofexecutable]/doc \
   $::surf(wavesurferdir)/doc \
   $::surf(wavesurferdir)/../web] {
  set f $manpath/man$::version_major$::version_minor.html
  if [file exists $f] {
   set manurl file:$f 
   break
  }
 }

 #<< "manurl:$manurl"


 menu $m.help -tearoff 0
 $m add cascade -label [::util::mc Help] -menu $m.help -underline 0
 $m2 add cascade -label [::util::mc Help]
 # $m.help add command -label [::util::mc "About WaveSurfer"] \
  \#   -command [list util::showURL http://www.speech.kth.se/wavesurfer/index.html]
if {[tk windowingsystem] eq "aqua"} {

    proc ::tk::mac::ShowHelp {} {
	set manurl http://www.speech.kth.se/wavesurfer/man$::version_major$::version_minor.html
	eval util::showURL $manurl
    }
    proc tkAboutDialog {} {
	About
    }

    proc ::tk::mac::ShowPreferences {} {
	PreferencesDialog
    }
}

   if {[tk windowingsystem] ne "aqua"} {
    $m.help add command -label [::util::mc "Manual"] \
	-command [list util::showURL $manurl]
}

 $m.help add command -label [::util::mc "FAQ"] \
   -command [list util::showURL http://www.speech.kth.se/wavesurfer/faq.html]
 $m.help add command -label [::util::mc "Forum"] \
   -command [list util::showURL http://www1.speech.kth.se/prod/wavesurferforum/phpBB2/index.php]
 $m.help add separator
 $m.help add command -label [::util::mc "About Plug-ins"] \
  -command ::wsurf::pluginsDialog
 $m.help add command -label [::util::mc "About WaveSurfer"] \
  -command [list About]

 $p config -menu $m
}

snack::sound cbs
snack::sound cbs2
set Info(filter) [snack::filter map 0.0]
set remdc(f) [snack::filter iir -numerator "0.99 -0.99" -denominator "1 -0.99"]
set echo(f) [snack::filter echo 0.6 0.6 30 0.4]
set echo(n) 1
set echo(drain) 1
set echo(iGain) 50
set echo(oGain) 50
set mix(f) [snack::filter map 0.0]
set amplify(f) [snack::filter map 1.0]
set amplify(v) 100.0
set amplify(db) 0
set silence(l) 3.0
set fade(f) [snack::filter fade in linear 100]
set fade(dir)  In
set fade(type) Linear
set fade(floor)  0.0
set normalize(f) [snack::filter map 1.0]
set normalize(v) 100.0
set normalize(db) 0
set normalize(allEqual) 1
set mixpaste(prescale) 100.0
set mixpaste(mixscale) 100.0

set Info(MasterWidget) none

proc ConfigureFileMenu {m} {
 set w [::wsurf::GetCurrent]

 if {$w != "" && [$w needSave]} {
  $m.file entryconfigure [::util::mc Save] -state normal
 } else {
  $m.file entryconfigure [::util::mc Save] -state disabled
 }
 if {$w != "" && [$w getInfo hasPanes] &&
 [string compare macintosh $::tcl_platform(platform)]} {
  $m.file entryconfigure [::util::mc Print...] -state normal
 } else {
  $m.file entryconfigure [::util::mc Print...] -state disabled
 }
 if {$w == ""} {
  $m.file entryconfigure [::util::mc "Save As..."] -state disabled
  $m.file entryconfigure [::util::mc Close] -state disabled
 } else {
  $m.file entryconfigure [::util::mc "Save As..."] -state normal
  $m.file entryconfigure [::util::mc Close] -state normal
 }
 if {$w != ""} {
  foreach {left right} [$w cget -selection] break
 }
 if {$w != "" && $left != $right} {
  $m.file entryconfigure [::util::mc "Save Selection..."] -state normal
 } else {
  $m.file entryconfigure [::util::mc "Save Selection..."] -state disabled
 }

 $m.file entryconfigure [::util::mc "Revert"] \
     -accelerator [Binding2Text $::Info(Prefs,Revert)]
 $m.file entryconfigure [::util::mc "Chooser..."] \
     -accelerator [Binding2Text $::Info(Prefs,Chooser)]
 $m.file entryconfigure [::util::mc "Save Selection..."] \
     -accelerator [Binding2Text $::Info(Prefs,SaveSelection)]
 $m.file entryconfigure [::util::mc "Show Console..."] \
     -accelerator [Binding2Text $::Info(Prefs,ShowConsole)]
 $m.file entryconfigure [::util::mc "Print..."] \
     -accelerator [Binding2Text $::Info(Prefs,Print)]
 $m.file entryconfigure [::util::mc "Preferences..."] \
     -accelerator [Binding2Text $::Info(Prefs,Prefs)]
}

proc ConfigureEditMenu {m} {
 set w [::wsurf::GetCurrent]

 set state "disabled"
 if {$w != "" && [$w getInfo isLinked2File] == 0} {
  set state "normal"
 }
 $m.edit entryconfigure [::util::mc Undo] -state $state
 $m.edit entryconfigure [::util::mc Cut] -state $state
 $m.edit entryconfigure [::util::mc Copy] -state $state
 $m.edit entryconfigure [::util::mc Paste] -state $state
 $m.edit entryconfigure [::util::mc "Mix Paste..."] -state $state \
     -accelerator [Binding2Text $::Info(Prefs,MixPaste)]

 if {$w == ""} {
  set state "disabled"
 } else {
  set state "normal"
 }
 $m.edit entryconfigure [::util::mc "Select All"] -state $state \
     -accelerator [Binding2Text $::Info(Prefs,SelectAll)]
 $m.edit entryconfigure [::util::mc "Selection to New"] -state $state \
     -accelerator [Binding2Text $::Info(Prefs,SelectoNew)]
 $m.edit entryconfigure [::util::mc "Zero Cross Adjust"] -state $state \
     -accelerator [Binding2Text $::Info(Prefs,ZeroXAdjust)]
}

proc ConfigureTransformMenu {m} {
 set w [::wsurf::GetCurrent]

 set state "disabled"
 set mixState "disabled"
 set SilenceLabel [::util::mc Silence...]
 set SilenceEntry [::util::mc Silence]*
 if {$w != ""} {
  if {[$w getInfo isLinked2File] == 0} {
   set state "normal"
  }

  # Special handling for Silence item since its name depends on selection state
  foreach {left right} [$w cget -selection] break
  if {$left == $right} {
   set SilenceLabel [::util::mc Silence...]
  } else {
   set SilenceLabel [::util::mc Silence]
  }
  set SilenceEntry [::util::mc Silence]*

  # Disable "Mix Channels" for mono files
  set s [$w cget -sound]
  set mixState $state
  if {[$s cget -channels] == 1} {
   set mixState "disabled"
  }
 }
 $m.trans entryconfigure [::util::mc Convert...] -state $state \
     -accelerator [Binding2Text $::Info(Prefs,Convert)]
 $m.trans entryconfigure [::util::mc Amplify...] -state $state \
     -accelerator [Binding2Text $::Info(Prefs,Amplify)]
 $m.trans entryconfigure [::util::mc Fade...] -state $state \
     -accelerator [Binding2Text $::Info(Prefs,Fade)]
 $m.trans entryconfigure [::util::mc Normalize...] -state $state \
     -accelerator [Binding2Text $::Info(Prefs,Normalize)]
 $m.trans entryconfigure [::util::mc Echo...] -state $state \
     -accelerator [Binding2Text $::Info(Prefs,Echo)]
 $m.trans entryconfigure [::util::mc "Mix Channels..."] -state $mixState \
     -accelerator [Binding2Text $::Info(Prefs,MixChan)]
 $m.trans entryconfigure [::util::mc Invert] -state $state \
     -accelerator [Binding2Text $::Info(Prefs,Invert)]
 $m.trans entryconfigure [::util::mc Reverse] -state $state \
     -accelerator [Binding2Text $::Info(Prefs,Reverse)]
 $m.trans entryconfigure $SilenceEntry -state $state \
     -accelerator [Binding2Text $::Info(Prefs,Silence)] -label $SilenceLabel
 $m.trans entryconfigure [::util::mc Silence]* -state $state \
    -accelerator [Binding2Text $::Info(Prefs,Silence)]
 $m.trans entryconfigure [::util::mc "Remove DC"] -state $state \
     -accelerator [Binding2Text $::Info(Prefs,RemoveDC)]
}

proc ConfigureViewMenu {m} {
 set w [::wsurf::GetCurrent]
 $m.view.slaves delete 0 end
 if {[llength $::wsurf::Info(widgets)] > 1} {
  set state normal
 } else {
  set state disabled
 }
 $m.view.slaves add radiobutton -state $state -label [::util::mc None] \
     -variable ::Info(MasterWidget) -command SetMasterWidget -value none
 $m.view.slaves add radiobutton -state $state -label [::util::mc Any] \
     -variable ::Info(MasterWidget) -command SetMasterWidget -value any
 foreach widget $::wsurf::Info(widgets) {
  set label [$widget cget -title]
  $m.view.slaves add radiobutton -state $state -label $label \
      -variable ::Info(MasterWidget) -command SetMasterWidget -value $widget 
 }

 $m.view entryconfigure [::util::mc "Zoom In"] \
     -accelerator [Binding2Text $::Info(Prefs,ZoomIn)]
 $m.view entryconfigure [::util::mc "Zoom Out"] \
     -accelerator  [Binding2Text $::Info(Prefs,ZoomOut)]
 $m.view entryconfigure [::util::mc "Zoom Out Full"] \
     -accelerator [Binding2Text $::Info(Prefs,ZoomFullOut)]
 $m.view entryconfigure [::util::mc "Zoom to Selection"] \
     -accelerator [Binding2Text $::Info(Prefs,ZoomToSelection)]
}

proc SetMasterWidget {} {
 set widgets $::wsurf::Info(widgets)
 foreach widget $widgets {
  if {[string match any     $::Info(MasterWidget)] || \
    [string match $widget $::Info(MasterWidget)] || \
    [string match [$widget getInfo fileName] $::Info(MasterWidget)]} {
   set n [lsearch $widgets $widget]
   $widget configure -slaves [lreplace $widgets $n $n]
   if {[string match any $::Info(MasterWidget)] == 0} {
    set ::Info(MasterWidget) $widget
   }
  } else {
   $widget configure -slaves ""
  }
 }
}

# In tclkits it seems that TCLLIBPATH is not automatically included 
# in the auto_path. If so, let's do that ourselves:
if [info exists env(TCLLIBPATH)] {
 foreach dir $env(TCLLIBPATH) {
  if {[lsearch $auto_path $dir] == -1} {
   lappend auto_path $dir
  }
 }
}

# Create toolbar icons

set Info(Img,new) [image create photo -data R0lGODlhEAAQALMAAAAAAMbGxv///////////////////////////////////////////////////////yH5BAEAAAEALAAAAAAQABAAAAQwMMhJ6wQ4YyuB+OBmeeDnAWNpZhWpmu0bxrKAUu57X7VNy7tOLxjIqYiapIjDbDYjADs=]
set Info(Img,open) [image create photo -data R0lGODlhEAAQALMAAAAAAISEAMbGxv//AP///////////////////////////////////////////////yH5BAEAAAIALAAAAAAQABAAAAQ4UMhJq6Ug3wpm7xsHZqBFCsBADGTLrbCqllIaxzSKt3wmA4GgUPhZAYfDEQuZ9ByZAVqPF6paLxEAOw==]
set Info(Img,save) [image create photo -data R0lGODlhEAAQALMAAAAAAISEAMbGxv///////////////////////////////////////////////////yH5BAEAAAIALAAAAAAQABAAAAQ3UMhJqwQ4a30DsJfwiR4oYt1oASWpVuwYm7NLt6y3YQHe/8CfrLfL+HQcGwmZSXWYKOWpmDSBIgA7]
set Info(Img,print) [image create photo -data R0lGODlhEAAQALMAAAAAAISEhMbGxv//AP///////////////////////////////////////////////yH5BAEAAAIALAAAAAAQABAAAAQ5UMhJqwU450u67wCnAURYkZ9nUuRYbhKalkJoj1pdYxar40ATrxIoxn6WgTLGC4500J6N5Vz1roIIADs=]
set Info(Img,cut)   [image create photo -data R0lGODlhEAAQALMAAAAAAAAAhMbGxv///////////////////////////////////////////////////yH5BAEAAAIALAAAAAAQABAAAAQvUMhJqwUTW6pF314GZhjwgeXImSrXTgEQvMIc3ONtS7PV77XNL0isDGs9YZKmigAAOw==]
set Info(Img,copy)  [image create photo -data R0lGODlhEAAQALMAAAAAAAAAhMbGxv///////////////////////////////////////////////////yH5BAEAAAIALAAAAAAQABAAAAQ+UMhJqwA4WwqGH9gmdV8HiKYZrCz3ecG7TikWf3EwvkOM9a0a4MbTkXCgTMeoHPJgG5+yF31SLazsTMTtViIAOw==]
set Info(Img,paste) [image create photo -data R0lGODlhEAAQALMAAAAAAAAAhISEAISEhMbGxv//AP///////////////////////////////////////yH5BAEAAAQALAAAAAAQABAAAARMkMhJqwUYWJlxKZ3GCYMAgCdQDqLKXmUrGGE2vIRK7usu94GgMNDqDQKGZDI4AiqXhkDOiMxEhQCeAPlUEqm0UDTX4XbHlaFaumlHAAA7]
set Info(Img,undo) [image create photo -data R0lGODlhEAAQALMAAAAAhMbGxv///////////////////////////////////////////////////////yH5BAEAAAEALAAAAAAQABAAAAQgMMhJq704622BB93kUSAJlhUafJj6qaLJklxc33iuXxEAOw==]
set Info(Img,zoomall) [image create photo -data R0lGODlhFAATAMIAAAAAAF9fXwAA/8zM/8zMzP///////////yH5BAEAAAcALAAAAAAUABMAAAM9eLrc/tCB2OayVOGz6Z5dxTFAaZ7oN0YgmV3uu2pQUAY07ARFb8/AS6/XygCGhVANqazdSrJGQICL6qyOBAA7]
set Info(Img,zoomsel) [image create photo -data R0lGODlhFAATAMIAAAAAAF9fXwAA/8zM/8zMzP///////////yH5BAEAAAcALAAAAAAUABMAAAM7eLrc/jAqwKhcdl5cN83H9wBkWZXkGHYgBLbRu2lKQAZeXez2ZQG7HcwVLAxHxePDBmDOGgEB7smhPhIAOw==]

snack::createIcons

proc CreateToolbar {p} {
    set opt "-style"
    set val "Toolbutton"
    
    pack [ ttk::frame $p.tb -relief raised -borderwidth 1] -side top -fill x
    eval pack [ ttk::button $p.tb.new  -image $::Info(Img,new) -command New \
		    $opt $val] -side left
    eval pack [ ttk::button $p.tb.open -image $::Info(Img,open) -command Open \
		    $opt $val] -side left
    eval pack [ ttk::button $p.tb.save -image $::Info(Img,save) -command Save \
		    $opt $val] -side left
    
    pack [ ttk::frame $p.tb.sep1 -borderwidth 1 -relief sunken -width 2] \
	-side left -fill y -padx 4 -anchor w -pady 2
    eval pack [ ttk::button $p.tb.print -image $::Info(Img,print) -command Print \
		    $opt $val] -side left
    eval pack [ ttk::button $p.tb.mixer -image snackGain -command snack::mixerDialog \
		    $opt $val] -side left
    #pack [ttk::button $p.tb.prefs -image $::Info(Img,preferences) -command PreferencesDialog -relief flat] -side left
    pack [ ttk::frame $p.tb.sep2 -borderwidth 1 -relief sunken -width 2] -side left \
	-fill y -padx 4 -anchor w -pady 2
    eval pack [ ttk::button $p.tb.cut   -image $::Info(Img,cut) -command Cut $opt $val] \
	-side left
    eval pack [ ttk::button $p.tb.copy -image $::Info(Img,copy) -command Copy \
		    $opt $val] -side left
    eval pack [ ttk::button $p.tb.paste -image $::Info(Img,paste) -command Paste \
		    $opt $val] -side left
    eval pack [ ttk::button $p.tb.undo -image $::Info(Img,undo) -command Undo \
		    $opt $val] -side left
    pack [ ttk::frame $p.tb.sep3 -borderwidth 1 -relief sunken -width 2] -side left \
	-fill y -padx 4 -anchor w -pady 2
    eval pack [ ttk::button $p.tb.zoomin  -image snackZoomIn -command ZoomIn \
		    $opt $val] -side left
    eval pack [ ttk::button $p.tb.zoomout -image snackZoomOut -command ZoomOut \
		    $opt $val] -side left
    eval pack [ ttk::button $p.tb.zoomall -image $::Info(Img,zoomall) -command ZoomAll \
		    $opt $val] -side left
    eval pack [ ttk::button $p.tb.zoomsel -image $::Info(Img,zoomsel) -command ZoomSel \
		    $opt $val] -side left
    pack [ ttk::frame $p.tb.sep4 -borderwidth 1 -relief sunken -width 2] -side left \
	-fill y -padx 4 -anchor w -pady 2
    pack [ ttk::label $p.tb.time -text 00.000 -relief flat] \
	-side left
    
}


proc CreateMessagebar {p} {
 pack [ ttk::frame $p.bf] -side bottom -fill x
 messagebar::create $p.bf.lab -text "" -progress 0.0 -command Interrupt \
   -width $::Info(Prefs,wsWidth)
 pack $p.bf.lab -side left -expand yes -fill x
}

proc dropFileCallback {droppedfiles} {
    puts [info level 0]
    foreach file $droppedfiles {
	OpenFile $file
    }
}


# Create toolbar

CreateToolbar .x

# Create messagebar

CreateMessagebar .x


update idletasks  ;# <------- is this necessary?

# Initialize wsurf package

::wsurf::Initialize -plugindir $surf(pluginpath) -configdir $surf(configpath)

set Info(Prefs,PlayPause) space
set Info(Prefs,PlaySelection)   F3
set Info(Prefs,PlayCursor)      F1
set Info(Prefs,PlayAll)         F2
set Info(Prefs,PlayVisible)     F5
set Info(Prefs,PlayLoop)        F8
set Info(Prefs,PlayStop)        F6

set Info(Prefs,Revert)          $::AccKey-r
set Info(Prefs,Chooser)         ""
set Info(Prefs,SaveSelection)   ""
set Info(Prefs,ShowConsole)     ""
set Info(Prefs,Print)           ""
set Info(Prefs,Print)           ""
set Info(Prefs,Prefs)           ""
set Info(Prefs,MixPaste)        $::AccKey-m
set Info(Prefs,SelectoNew)      ""
set Info(Prefs,SelectAll)       $::AccKey-a
set Info(Prefs,ZeroXAdjust)     F4
set Info(Prefs,LockMessageBar)  F9
set Info(Prefs,ZoomOut)         $::AccKey-minus
set Info(Prefs,ZoomIn)          $::AccKey-plus
set Info(Prefs,ZoomFullOut)     F11
set Info(Prefs,ZoomToSelection) F12
set Info(Prefs,Fade)            $::AccKey-d

set Info(Prefs,Convert)         ""
set Info(Prefs,Amplify)         ""
set Info(Prefs,Normalize)       ""
set Info(Prefs,Echo)            ""
set Info(Prefs,MixChan)         ""
set Info(Prefs,Invert)          ""
set Info(Prefs,Reverse)         ""
set Info(Prefs,Silence)         ""
set Info(Prefs,RemoveDC)        ""

# fix for headings in KeyBindingsPage
set Info(Prefs,x0) ""
set Info(Prefs,x1) ""
set Info(Prefs,x2) ""
set Info(Prefs,x3) ""

# SetDefaultPrefs
# read user preferences
set Info(PrefsFile) [file join $::env(HOME) .wavesurfer $Info(Version) \
	preferences]
set pf $Info(PrefsFile)
if {[file readable $pf]} {source $pf}

# for backward compatibility with pre 1.8.8 prefs files:
if [string match "Show dialog" $::wsurf::Info(Prefs,defaultConfig)] {set ::wsurf::Info(Prefs,defaultConfig) ""}

# Create menus

CreateMenus .x

# Set-up key bindings

wsurf::AddEvent PopupEvent $wsurf::Info(Prefs,popupEvent)
event add <<Delete>> <Delete>

catch {event add <<Delete>> <hpDeleteChar>}

proc ManageFocus {w} {
 if {[string match $w $::Info(current)] == 0} {
  set ::Info(current) $w
  set n [lsearch $::Info(toplevels) $w]
  if {$n >= 0} {
   set tl [lindex $::Info(toplevels) $n]
   set i [lsearch [winfo children $tl] $tl.s*]
   if {$i >= 0} {
    set wsurf [lindex [winfo children $tl] $i]
    wsurf::MakeCurrent $wsurf    
    set ::WSURF  $wsurf
    set ::SOUND [$wsurf cget -sound]
   }
  }
 }
}

proc BindKeys {p} {
 bind $p <$::AccKey-n> New
 bind $p <$::AccKey-o> Open
 bind $p <$::AccKey-s> Save
 bind $p <$::AccKey-w> [list Close $p]\nbreak
 bind $p <$::AccKey-x> Cut
 bind $p <$::AccKey-c> Copy
 bind $p <$::AccKey-v> Paste

 foreach {prefKey script text} $::Prefs(Table) {
  if {$::Info(Prefs,$prefKey) != ""} {
   bind $p <$::Info(Prefs,$prefKey)> $script
  }
 }
 
 bind $p <FocusIn> [list ManageFocus $p]
 bind $p <Delete> Cut
 # fixes for TPB project
 bind $p <F1> ChooseNext
 bind $p <Key-Up> {
  #puts [focus]
  ::wsurf::trans::Cursor2FirstLabel [::wsurf::GetCurrent]
 }
}
BindKeys .x

set Info(current) ""
set Info(chooser,replacecurrent) 1
set Info(chooser,autoplay) 1
set Info(chooser,autozoom) 0

set surf(extensions) [list .wav .au .mp3 .aiff .aif .smp .sd .snd .nsp .raw]
foreach ext $surf(extTypes) {
 lappend ::surf(extensions) $ext
}
foreach {ext rate enc chan bo skip} $::wsurf::Info(Prefs,rawFormats) {
  lappend ::surf(extensions) $ext
}

set surf(loadTypes) [concat $surf(loadTypes) \
    [list {{Common Files} {.wav}} {{Common Files} {.au}} {{Common Files} {.aif}} {{Raw Files} {.raw}}]]
foreach {ext rate enc chan bo skip} $::wsurf::Info(Prefs,rawFormats) {
  set surf(loadTypes) [concat $surf(loadTypes) [list "{Raw Files} $ext"]]
}
set surf(loadKeys) [concat $surf(loadKeys) [list WAV AU AIFF RAW]]
snack::addExtTypes [concat $surf(extTypes)]
snack::addLoadTypes $surf(loadTypes) $surf(loadKeys)
snack::addSaveTypes $surf(saveTypes) $surf(saveKeys)

#bind .x <Destroy> {if [string match %W .x] exit}

# Command line parsing

set surf(filelist) ""
set surf(play) 0
set surf(conf) [list "unspecified"]

# Remove Process ID given by Finder in Mac OS X
if {[string match Darwin $::tcl_platform(os)]} {
 set psnIndex [lsearch -regexp $argv {^-psn_0_[0-9]+$}]
 if {$psnIndex != -1} {
  set argv [lreplace $argv $psnIndex $psnIndex]
 }
}

package require cmdline

set argvcopy ""
while {$argvcopy != $argv} {
 set argvcopy $argv
 
 # First let all plug-ins parse argv
 ::wsurf::getopt argv
 
 # Parse what's left of argv
 
 if {[cmdline::getopt argv {usage} opt arg] == 1} {
  puts "Usage: wavesurfer \[options\] file file2 ..."
  puts "Options"
  puts "-play"
  puts "-config name"
  puts "-filelist file"
  puts "-master file"
  puts "-debug n"
  exit
 }

 if {[cmdline::getopt argv {play} opt arg] == 1} {
  set surf(play) 1
  continue
 }
 
 if {[cmdline::getopt argv {config.arg} opt arg] == 1} {
  if {$surf(conf) == "unspecified"} {
   set surf(conf) {}
  }
  if {[file exists $arg] && [string match *.conf $arg]} {
   lappend surf(conf) $arg
   continue
  }
  if {[string match *.conf $arg]} {
   set arg [file root $arg] 
  }
  set l [::wsurf::GetConfigurations]
  set ind [lsearch -regexp $l ".*$arg\[\\w\\s\]*.conf"]
  if {$ind != -1 && $arg != ""} {
   lappend surf(conf) [lindex $l $ind]
  } else {
   lappend surf(conf) ""
  }
  continue
 }
 
 if {[cmdline::getopt argv {filelist.arg} opt arg] == 1} {
  ReadFileList $arg
  Chooser
  .chooser.frame.list selection set 0
 }
 
 if {[cmdline::getopt argv {master.arg} opt arg] == 1} {
  set ::Info(MasterWidget) $arg
  SetMasterWidget
  continue
 }

 if {[cmdline::getopt argv {debug.arg} opt arg] == 1} {
  set ::wsurf::Info(debug) $arg
  if {$arg > 5} {
   snack::debug $arg ~/wsurf.log
  } else {
   snack::debug $arg
  }
 }
}
#set ::wsurf::Info(debug) 5
#snack::debug 5 ~/wsurf.log

if {$argv == {} && [info exists listfiles] && [llength $listfiles] > 0} {
 set argv [lindex [split [lindex $listfiles 0] ;] 0]
}

# argv should only contain sound files now

set surf(filelist) $argv

# register dde server

if {[string match windows $::tcl_platform(platform)]} {
 package require dde
 dde servername WaveSurfer
}

# display gui & rid splash

CleanUp
wm deiconify .x
SetIcon .x
destroy $splash::splash
update idletasks

if {$surf(conf) == "unspecified" && $::wsurf::Info(Prefs,defaultConfig) != ""} {
    set l [::wsurf::GetConfigurations]
    set ind [lsearch -regexp $l ".*$::wsurf::Info(Prefs,defaultConfig)\[\\w\\s\]*.conf"]
    if {$ind != -1} {
	set surf(conf) {}
	lappend surf(conf) [lindex $l $ind]
    } else {
	set surf(conf) [list "unspecified"]
    }
}


# create wsurf widgets

if {[llength $surf(filelist)] == 1 && [file isdirectory $surf(filelist)]} {
 set surf(filelist) ""
}


if {[llength $surf(filelist)] == 0} {
 # no files given on command line, pack an empty widget 
 set w [wsurf .x.s[incr surf(count)] -messageproc setMsg \
   -progressproc progressCallback -playpositionproc progressCallback -dropfileproc dropFileCallback]
 pack $w -expand 0 -fill both -side top
 set Info(widgets,.x) $w
 if {$surf(conf) != "unspecified"} {
  $w configure -configuration [lindex $surf(conf) 0]
 }
} else {
 # load files specified on the command line into widgets
 set i 0
 foreach file $surf(filelist) {
  if {$surf(conf) != "unspecified"} {
   OpenFile $file [lindex $surf(conf) $i]
  } else {
   OpenFile $file
  }
  incr i
  if {$i == [llength $surf(conf)]} { incr i -1 }
 }
}

if {[string match macintosh $::tcl_platform(platform)]} {
  bind .x <Configure> FixHeight
  set oldwi 0

  proc FixHeight {} {
    regexp {([\d]+)[x][\d]+[+][\d]+[+][\d]+} [wm geometry .x] dummy width
    if {$::oldwi == $width} return
    if {$::oldwi == 0} {
      set ::oldwi $width
      return
    }
    bind .x <Configure> ""
    wm geometry .x {}
    update idletasks
    regexp {[\d]+[x]([\d]+)[+][\d]+[+][\d]+} [wm geometry .x] dummy height
    wm geometry .x ${width}x$height
    set ::oldwi $width
    bind .x <Configure> FixHeight
  }
}
if {$newVersion} {
  tk_messageBox -message [::util::mc "This is the first time you run WaveSurfer $Info(Version). You might have old configuration files and plug-ins in $lastVersion that need to be moved to $newHome."]
}



