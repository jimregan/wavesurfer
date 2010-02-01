#
#  Copyright (C) 2000-2006 Jonas Beskow and Kare Sjolander 
#
# This file is part of the WaveSurfer package.
# The latest version can be found at http://www.speech.kth.se/wavesurfer/
#

package provide wsurf 1.8

package require snack 2.2
package require surfutil
package require combobox

if {0} {
    #&& [catch {package require tile 0.7} msg]
 set useTile 0
 set ::ocdir right
} 
if 0 {
 set useTile 1
 rename scale tk_scale
 namespace import -force ttk::scale
 rename menubutton tk_menubutton
 namespace import -force ttk::menubutton
 rename checkbutton tk_checkbutton
 namespace import -force ttk::checkbutton
 namespace import -force ttk::radiobutton
 namespace import -force ttk::scale
    rename scrollbar tk_scrollbar
    namespace import -force ttk::scrollbar
 rename label tk_label
 namespace import -force ttk::label
 rename button tk_button
 namespace import -force ttk::button
 rename frame tk_frame
 namespace import -force ttk::frame
 namespace import -force ttk::entry
 namespace import -force ttk::combobox
 namespace import -force ttk::notebook
 namespace import -force ttk::labelframe
 namespace import -force ttk::separator
}

if 1 {
    set useTile 1
    foreach cmd {scale menubutton checkbutton radiobutton scrollbar label button frame entry combobox notebook labelframe separator} {
	puts "$cmd ..."
	if {[info command $cmd]!=""} {
	    rename $cmd tk_$cmd
	}
	proc ::$cmd {args} "uplevel ttk::$cmd \$args"
      
    }
}

proc ::tk_optionMenu {w varName firstValue args} {
    upvar #0 $varName var
                                                                                
    if {![info exists var]} {
        set var $firstValue
    }
    if {$::useTile} {
     tk_menubutton $w -textvariable $varName -indicatoron 1 -menu $w.menu \
	 -relief raised -bd 2 -highlightthickness 2 -anchor c \
	 -direction flush
    } else {
     menubutton $w -textvariable $varName -indicatoron 1 -menu $w.menu \
	 -relief raised -bd 2 -highlightthickness 2 -anchor c \
	 -direction flush
    }
    menu $w.menu -tearoff 0
    $w.menu add radiobutton -label $firstValue -variable $varName
    foreach i $args {
        $w.menu add radiobutton -label $i -variable $varName
    }
    return $w.menu
}

namespace eval wsurf {
    variable Info
    
    # find out what directory this package lives in
    set Info(dir) [file dirname [info script]]
    set Info(parentdir) [file dirname [file dirname [file normalize [info script]]]]

    proc ::wsurf {w args} {eval wsurf::create $w $args}
    
    set Info(debug) 0
    set Info(snackDebug) 0 ;#$Info(debug)
    snack::debug $Info(snackDebug)
}


# -----------------------------------------------------------------------------
#
# Methods
# -------
# There are two categories of methods: meta methods and widget methods.
#
# Meta methods:
#
# Meta methods are "global" in the sense that they don't operate
# on widget instances. They deal with plugin registration etc.
#
# Widget methods:
#
# Widget methods operate on a specific widget instance. The widget methods 
# can be further divided into internal and external - the internal widget 
# methods are intended only to be called by the widget's own methods and 
# by it's plugins. The external widget methods constitute the published 
# widget API.
# The first argument to a widget method must always be the widget's name. 
# When a new widget is created, it will create a procedure bearing the name 
# of the widget (such as .foo). That procedure expects a method name as the 
# first argument, and will invoke that method with the with the widget name as
# the first argument. Therefore, the follwoing two ways to call a method 
# are equivalent:
#
#   $w method <args>
#   method $w <args>
#
# The first way is prefered for users of the widget, it's slightly more 
# elegant and follows Tk's widget conventions.
# The second way is prefered for use from within the widget.
# It requires a qualified method name if called from outside the namespace.
#
# Method naming convension:
#
# Meta-method names have the first letter capitalized
# Internal widget methods start with an underscore followed by a lowercase letter. 
# External widget methods start with a lowercase letter.
#
# Variables
# ---------
# Meta-data (i.e. non-widget-specific data) is kept in the 
# namespace variable Info.
# In addition, each widget creates it's own child namespace
# where widget-specific data is kept. If a widget with the name .foo,
# is created, it will create the namespace ::wsurf::.foo
# with variables such as ::wsurf::.foo::widgets and 
# ::wsurf::.foo::data
# In each widget method, the widget variables can be 
# bound to local variables like this:
#   upvar [namespace current]::${w}::widgets wid
#   upvar [namespace current]::${w}::data d
#


# -----------------------------------------------------------------------------
# Meta methods
# -----------------------------------------------------------------------------

proc wsurf::Initialize {args} {
 variable Info
 array set a [list \
  -plugindir [list] \
  -configdir [list] \
 ]
 array set a $args

 set Info(Img,plus) [image create bitmap -data {
  #define arrow1_width 13
  #define arrow1_height 13
  static char arrow1_bits[] = {
   0x03, 0x00, 0x0f, 0x00, 0x3f, 0x00, 0xf3, 0x00, 0xc3, 0x03, 0x03, 0x0f, 
   0x03, 0x1c, 0x03, 0x0f, 0xc3, 0x03, 0xf3, 0x00, 0x3f, 0x00, 0x0f, 0x00, 
   0x03, 0x00, };
 }]
 set Info(Img,minus) [image create bitmap -data {
  #define arrow2_width 13
  #define arrow2_height 13
  static char arrow2_bits[] = {
   0xff, 0x1f, 0xff, 0x1f, 0x06, 0x0c, 0x06, 0x0c, 0x0c, 0x06, 0x0c, 0x06, 
   0x18, 0x03, 0x18, 0x03, 0xb0, 0x01, 0xb0, 0x01, 0xe0, 0x00, 0xe0, 0x00, 
   0x40, 0x00, };
  }]
 set Info(Img,close) [image create bitmap -data {
  #define x_width 18
  #define x_height 17
  static unsigned char x_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x60, 0x00,
   0x30, 0x30, 0x00, 0x60, 0x18, 0x00, 0xc0, 0x0c, 0x00, 0x80, 0x07, 0x00,
   0x00, 0x03, 0x00, 0x80, 0x07, 0x00, 0xc0, 0x0c, 0x00, 0x60, 0x18, 0x00,
   0x30, 0x30, 0x00, 0x18, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, };
  }]
 set Info(Img,zoomin) snackZoomIn
 set Info(Img,zoomout) snackZoomOut
 set Info(Img,print) snackPrint
 snack::createIcons

 set Info(Img,playloop) [image create photo -data R0lGODlhEwATAPABAAAAAP///yH5BAEAAAEALAAAAAATABMAAALMTJgwYcKECRMmTJgwYcKECRMmTJgwYUKAAAECBAgQIMKECBMmTJgwYcKECBEmTJgwYcKECRMCTJgwIMKECRMmDIgwYUKAABMmTJgQYMKEAQECRJgwYcCACRMCBAgQYMKACQMCBAgQIECAABMmTJgQIECAABMmTJgwYUCAABEmTJgwYcKEAAEmTJgwYcKECQMiTJgwYcKECRMmTJgwYcKECRMmTJgwYcKECRMmTJgwYcKECRMmTJgwYcKECRMmTJgwYcKECRMmTJgwYcIUADs=]

 set Info(Img,playall) [image create photo -data R0lGODlhFQAVAKEAANnZ2QAA/////////yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgAAACwAAAAAFQAVAAACJISPqcvtD10IUc1Zz7157+h5Txg2pMicmESCqLt2VEbX9o1XBQA7]

 set Info(Img,zoomsel) [image create photo -data R0lGODlhFAATAMIAAAAAAF9fXwAA/8zM/8zMzP///////////yH5BAEAAAcALAAAAAAUABMAAAM7eLrc/jAqwKhcdl5cN83H9wBkWZXkGHYgBLbRu2lKQAZeXez2ZQG7HcwVLAxHxePDBmDOGgEB7smhPhIAOw==]

 set Info(Img,zoomall) [image create photo -data R0lGODlhFAATAMIAAAAAAF9fXwAA/8zM/8zMzP///////////yH5BAEAAAcALAAAAAAUABMAAAM9eLrc/tCB2OayVOGz6Z5dxTFAaZ7oN0YgmV3uu2pQUAY07ARFb8/AS6/XygCGhVANqazdSrJGQICL6qyOBAA7]

 set Info(Img,play) [image create photo -data R0lGODlhFQAVAKEAANnZ2QAAAP///////yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgAAACwAAAAAFQAVAAACJISPqcvtD10IUc1Zz7157+h5Txg2pMicmESCqLt2VEbX9o1XBQA7]

set Info(Img,pause) [image create photo -data R0lGODlhFQAVAKEAANnZ2QAAAP///////yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgAAACwAAAAAFQAVAAACLISPqcvtD12Y09DKbrC3aU55HfBlY7mUqKKO6emycGjSa9LSrx1H/g8MCiMFADs=]

set Info(Img,stop) [image create photo -data R0lGODlhFQAVAKEAANnZ2QAAAP///////yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgAAACwAAAAAFQAVAAACJISPqcvtD12YtM5mc8C68n4xIPWBZXdqabZarSeOW0TX9o3bBQA7]

set Info(Img,beg) [image create photo -data R0lGODlhFgAVAKEAANnZ2QAAAP///////yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgAAACwAAAAAFgAVAAACMISPqcvtDyMIlFV7Ec1q680l3gSOS4mGXwo2bOm+ZnexcbDOotpi+PmTCIfEolFSAAA7]

set Info(Img,end) [image create photo -data R0lGODlhFgAVAKEAANnZ2QAAAP///////yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgAAACwAAAAAFgAVAAACMISPqcvtDyMIgdFqr9L5YsMtngdSzYiaXRpuLLm+Z1p+LlzPKtImu/+TCIfEohFSAAA7]

set Info(Img,record) [image create photo -data R0lGODlhFQAVAKEAANnZ2f8AAP///////yH+FUNyZWF0ZWQgd2l0aCBUaGUgR0lNUAAh+QQBCgAAACwAAAAAFQAVAAACJoSPqcvtDyMINMhZM8zcuq41ICeOVWl6S0p95pNu4BVe9o3n+lIAADs=]

 set Info(ValidPluginOptions) {
  -description                description
  -url                        URL
  -dependencies               dependencies
  -registercallbackproc       registerCallbackProc
  -addmenuentriesproc	      addMenuEntriesProc       
  -widgetcreatedproc	      widgetCreatedProc        
  -widgetdeletedproc	      widgetDeletedProc        
  -panecreatedproc	      paneCreatedProc          
  -panedeletedproc	      paneDeletedProc          
  -redrawproc                 redrawProc               
  -getboundsproc	      getBoundsProc            
  -scrollproc		      scrollProc               
  -setselectionproc	      setSelectionProc         
  -cursormovedproc	      cursorMovedProc          
  -printproc		      printProc                
  -propertiespageproc         propertiesPageProc         
  -applypropertiesproc	      applyPropertiesProc      
  -getconfigurationproc	      getConfigurationProc     
  -soundchangedproc	      soundChangedProc         
  -openfileproc		      openFileProc             
  -savefileproc		      saveFileProc             
  -needsaveproc 	      needSaveProc          
  -playproc		      playProc                 
  -pauseproc		      pauseProc                
  -recordproc		      recordProc               
  -stopproc		      stopProc                 
  -cutproc		      cutProc                  
  -copyproc		      copyProc                 
  -pasteproc		      pasteProc                
  -undoproc		      undoProc                 
  -getoptproc                 getoptProc
  -stateproc                  stateProc
  -before                     before
  -sounddescriptionproc       soundDescriptionProc
 }
 foreach {opt name} $Info(ValidPluginOptions) {
  set Info(PluginOption,$opt) $name
 }

 set Info(widgets) {}
 set Info(current) ""
 set Info(Plugins) {}
 set Info(ConfigDir) $a(-configdir)
 set Info(PluginDir) $a(-plugindir)
 set Info(ActiveSound) ""
 set Info(blockRecursion) 0
 set Info(PropsDialogWidget) ""
 set Info(PrefsPageProcList)    {}
 set Info(PrefsApplyProcList)   {}
 set Info(PrefsGetProcList)     {}
 set Info(PrefsDefaultProcList) {}

 bind Wsurf    <ButtonPress-1> [namespace code [list MakeCurrent %W]]
 bind Wavebar  <ButtonPress-1> [namespace code [list MakeCurrent %W]]
 bind Vtcanvas <ButtonPress-1> [namespace code [list MakeCurrent %W]]
 
 LoadPlugins [GetPlugins]
 foreach dir $Info(PluginDir) {
  LoadPlugins [glob -nocomplain [file join $dir *.plug]]
 }

 set Info(Prefs,outDev) [lindex [snack::audio outputDevices] 0]
 set Info(Prefs,inDev)  [lindex [snack::audio inputDevices] 0]
 if {[string match unix $::tcl_platform(platform)]} {
  set Info(Prefs,PrintCmd) {lpr $FILE}
  set Info(Prefs,PrintPVCmd) {ghostview $FILE}
} elseif {[string match windows $::tcl_platform(platform)]} {
  set Info(Prefs,PrintCmd) {"C:/Program Files/PrintFile/prfile32.exe" /q $FILE}
  #  set Info(Prefs,PrintPVCmd) {"C:/Program Files/Ghostgum/gsview/gsview32" $FILE}
  # check registry for GSview location
  set key [join [list HKEY_LOCAL_MACHINE SOFTWARE Ghostgum GSview] \\]
  if [catch {registry values $key} versions] {
      set Info(Prefs,PrintPVCmd) {}
  } else {
      set latestver [string trim [lindex [lsort -dictionary $versions] end]]
      set gsviewdir [file normalize [registry get $key $latestver]]
      set Info(Prefs,PrintPVCmd) "\"[file join $gsviewdir gsview gsview32]\" \$FILE"
  }
} else {
    set Info(Prefs,PrintCmd)   {}
  set Info(Prefs,PrintPVCmd) {}
 }   
 set Info(Prefs,tmpDir) [util::tmpdir]
 set Info(PrintFile) {tmp$N.ps}
 set Info(Prefs,recordLimit) 60
 set Info(Prefs,linkFile) 0
 set Info(Prefs,autoScroll) None
 set Info(Prefs,defaultConfig) "Show dialog"
 set Info(Prefs,showLevel) 1
 set Info(Prefs,prefsWithConf) 0
 set Info(Prefs,maxPixelsPerSecond) 10000.0
 set Info(Prefs,icons) [list beg play playloop pause stop record close]
 foreach icon [list beg play playloop pause stop record close] {
  set Info(Prefs,$icon) 1
 }
 foreach icon [list playall end print zoomin zoomout zoomall zoomsel] {
  set Info(Prefs,$icon) 0
 }
if {[string match macintosh $::tcl_platform(platform)] || \
	[string match Darwin $::tcl_platform(os)]} {
    set Info(Prefs,popupEvent) [list Control-ButtonPress-1 ButtonPress-2]
} else {
    set Info(Prefs,popupEvent) ButtonPress-3
}
# event add <<PopupEvent>> <$Info(Prefs,popupEvent)>
 set Info(Prefs,timeFormat) hms.ddd
 set Info(Prefs,hms) 0
 set Info(Prefs,hms.d) 1
 set Info(Prefs,hms.dd) 2
 set Info(Prefs,hms.ddd) 3
 set Info(Prefs,hms.dddd) 4
 set Info(Prefs,hms.ddddd) 5
 set Info(Prefs,hms.dddddd) 6
 set Info(Prefs,samples) n
 set Info(Prefs,seconds) s
 set Info(Prefs,10ms\ frames) f
 set Info(Prefs,PAL\ frames) p
 set Info(Prefs,NTSC\ frames) t

 set Info(Prefs,defRate) 16000
 set Info(Prefs,defEncoding) Lin16
 set Info(Prefs,defChannels) 1

 set Info(Prefs,createWidgets) separate
 set Info(Prefs,yaxisWidth) 40

 set Info(PrintSelection) 0

 set Info(Prefs,rawFormats) {.alw 8000 Alaw 1 "" 0}


 if {$::useTile} {
  set THEMELIST {
   default  	"Default"
   classic  	"Classic"
   alt      	"Revitalized"
   winnative	"Windows native"
   xpnative	"XP Native"
   aqua	"Aqua"
  }
  array set THEMES $THEMELIST
  
  
  foreach name [ttk::style theme names] {
   if {![info exists THEMES($name)]} {
    lappend THEMELIST $name [set THEMES($name) [string totitle $name]]
   }
  }
  set Info(Themes) {}
  set Info(themes) {}
  foreach {theme name} $THEMELIST {
   if {[lsearch -exact [package names] tile::theme::$theme] != -1} {
    lappend Info(Themes) $name
    lappend Info(themes) $theme
   }
  }

  if {$::tcl_platform(os) == "Darwin"} {
   set Info(Prefs,theme) "aqua"
  } elseif {$::tcl_platform(platform) == "unix"} {
   set Info(Prefs,theme) "default"
  } else {
   if {$::tcl_platform(osVersion) == "5.1"} {
    set Info(Prefs,theme) "xpnative"
   } else {
    set Info(Prefs,theme) "winnative"
   }
  }
  ttk::style theme use $Info(Prefs,theme)
 }

 set Info(Initialized) 1
 SetDefaultPrefs

 return 0
}


proc wsurf::SetDefaultPrefs {} {
 variable Info

 set Info(Prefs,t,outDev) [lindex [snack::audio outputDevices] 0]
 set Info(Prefs,t,inDev)  [lindex [snack::audio inputDevices] 0]
 if {[string match unix $::tcl_platform(platform)]} {
  set Info(Prefs,t,PrintCmd) {lpr $FILE}
  set Info(Prefs,t,PrintPVCmd) {ghostview $FILE}
 } elseif {[string match windows $::tcl_platform(platform)]} {
  set Info(Prefs,t,PrintCmd) {"C:/Program Files/PrintFile/prfile32.exe" /q $FILE}
  set Info(Prefs,t,PrintPVCmd) {"C:/Program Files/Ghostgum/gsview/gsview32" $FILE}
 } else {
  set Info(Prefs,t,PrintCmd)   {}
  set Info(Prefs,t,PrintPVCmd) {}
 }   
 set Info(Prefs,t,tmpDir) [util::tmpdir]
 set Info(PrintFile) {tmp$N.ps}
 set Info(Prefs,t,recordLimit) 20
 set Info(Prefs,t,linkFile) 0
 set Info(Prefs,t,storage) "load into memory"
 set Info(Prefs,t,autoScroll) None
 set Info(Prefs,t,defaultConfig) "Show dialog"
 set Info(Prefs,t,showLevel) 1
 set Info(Prefs,t,prefsWithConf) 0
 set Info(Prefs,t,maxPixelsPerSecond) 10000.0
 set Info(Prefs,t,icons) [list beg play playloop pause stop record close]
 foreach icon [list beg play playloop pause stop record close] {
  set Info(Prefs,t,$icon) 1
 }
 foreach icon [list playall end print zoomin zoomout zoomall zoomsel] {
  set Info(Prefs,t,$icon) 0
 }
 if {[string match macintosh $::tcl_platform(platform)] || \
	 [string match Darwin $::tcl_platform(os)]} {
  set Info(Prefs,t,popupEvent) Control-ButtonPress-1
 } else {
  set Info(Prefs,t,popupEvent) ButtonPress-3
 }
 set Info(Prefs,t,timeFormat) hms.ddd
 set Info(Prefs,t,defRate) 16000
 set Info(Prefs,t,defEncoding) Lin16
 set Info(Prefs,t,defChannels) 1

 set Info(Prefs,t,createWidgets) separate
 set Info(Prefs,t,yaxisWidth) 40

 set Info(Prefs,t,rawFormats) {.alw 8000 Alaw 1 "" 0}

 if {$::tcl_platform(os) == "Darwin"} {
  set Info(Prefs,t,theme) "aqua"
 } elseif {$::tcl_platform(platform) == "unix"} {
  set Info(Prefs,t,theme) "default"
 } else {
  if {$::tcl_platform(osVersion) == "5.1"} {
   set Info(Prefs,t,theme) "xpnative"
  } else {
   set Info(Prefs,t,theme) "winnative"
  }
 }

 foreach proc $Info(PrefsDefaultProcList) {
   eval $proc
 }
}

proc wsurf::SetPreference {pref val} {
 variable Info

 set Info(Prefs,$pref) $val
}

proc wsurf::GetPreference {pref} {
 variable Info

 set Info(Prefs,$pref)
}

proc wsurf::InterpretRawDialog {ext} {
 variable Info

 set w .rawDialog
 toplevel $w -class Dialog
 frame $w.q
 pack $w.q -expand 1 -fill both -side top
 pack [frame $w.q.f1] -side left -anchor nw -padx 3m -pady 2m
 pack [frame $w.q.f2] -side left -anchor nw -padx 3m -pady 2m
 pack [frame $w.q.f3] -side left -anchor nw -padx 3m -pady 2m
 pack [frame $w.q.f4] -side left -anchor nw -padx 3m -pady 2m
 pack [label $w.q.f1.l -text [::util::mc "Sample Rate"]]
 foreach e [snack::audio rates] {
  pack [radiobutton $w.q.f1.r$e -text $e -value $e \
	  -variable [namespace current]::Info(guessRate)] -anchor w
 }
 pack [entry $w.q.f1.e -textvariable [namespace current]::Info(guessRate) \
     -width 5] -anchor w
 pack [label $w.q.f2.l -text [::util::mc "Sample Encoding"]]
 foreach e [snack::audio encodings] {
  pack [radiobutton $w.q.f2.r$e -text $e -value $e \
	  -variable [namespace current]::Info(guessEnc)] -anchor w
 }
 pack [label $w.q.f3.l -text [::util::mc Channels]]
 pack [radiobutton $w.q.f3.1 -text [::util::mc Mono] -value 1 \
	 -variable [namespace current]::Info(guessChan)] -anchor w
 pack [radiobutton $w.q.f3.2 -text [::util::mc Stereo] -value 2 \
	 -variable [namespace current]::Info(guessChan)] -anchor w
 pack [radiobutton $w.q.f3.4 -text 4 -value 4 \
	 -variable [namespace current]::Info(guessChan)] -anchor w
 pack [entry $w.q.f3.e -textvariable [namespace current]::Info(guessChan) \
	 -width 3] -anchor w

 pack [label $w.q.f4.l -text [::util::mc "Byte Order"]]
 pack [radiobutton $w.q.f4.ri -text [::util::mc "Little Endian (Intel)"] \
	 -value littleEndian \
	 -variable [namespace current]::Info(guessByteOrder)] -anchor w
 pack [radiobutton $w.q.f4.rm -text [::util::mc "Big Endian (Motorola)"] \
	 -value bigEndian \
	 -variable [namespace current]::Info(guessByteOrder)] -anchor w

 pack [label $w.q.f4.f] -pady 30
 pack [label $w.q.f4.f.l2 -text [::util::mc "Read Offset (bytes)"]]
 pack [entry $w.q.f4.f.e -textvar [namespace current]::Info(guessSkip) -wi 6]

 set Info(assoc) 0
 if {$ext != ""} {
  pack [label $w.q.f4.f2] -pady 10
  pack [checkbutton $w.q.f4.f2.cb -variable [namespace current]::Info(assoc) \
    -text "[::util::mc {Associate extension}] \n $ext [::util::mc {with these values}]"] -side bottom
 }
 
 set res [snack::makeDialogBox $w -title [::util::mc "Interpret Raw File As"] \
	 -type okcancel -default ok]
 if {$res == "ok" && $Info(assoc) == 1} {
  set Info(Prefs,t,rawFormats) [linsert $Info(Prefs,t,rawFormats) 0 \
   $ext $Info(guessRate) $Info(guessEnc) \
   $Info(guessChan) $Info(guessByteOrder) $Info(guessSkip)]
  if {[info procs ::SavePreferences] != ""} {
   # need real solution
   ::SavePreferences
  }
 }
 return $res
}

proc wsurf::_deleteRawFileDef {p} {
 variable Info

 set index [$p.f1.lb curselection]
 if {$index != ""} {
  $p.f1.lb delete $index
  set start [expr {$index * 6}]
  set end   [expr {$index * 6+5}]
  set Info(Prefs,t,rawFormats) [lreplace $Info(Prefs,t,rawFormats) $start $end]
 }
}


proc wsurf::AddEvent {name bindinglist} {
 event delete <<$name>>
 foreach binding $bindinglist {
  puts "event add <<$name>> <$binding>"
  event add <<$name>> <$binding>
 }
}

# -----------------------------------------------------------------------------
proc wsurf::LoadPlugins {pluginfiles} {
 variable Info

 set Info(TempPluginReg) [list]

 foreach plug $pluginfiles {
  set Info(CurrentPluginPath) $plug
  #<< "loading plugin: $plug"
  source $plug
 }
 if {[info exists Info(CurrentPluginPath)]} {
  unset Info(CurrentPluginPath)
 }

 # do actual plugin registration and resolve all dependencies
 set nlist [list]
 foreach {name args} $Info(TempPluginReg) {
  set a($name) $args
  lappend nlist $name
 }
 
 while {[llength $nlist] > 0} {
  set name [lindex $nlist 0]
  #<< "resolving $name..."
  if [info exists b] {unset b}
  array set b $a($name)
  if [info exists b(-dependencies)] {
   set deplist $b(-dependencies)
   #<< "  deplist: $deplist"
   foreach depname $deplist {
    #<< "    dependency: $depname"

    if {[lsearch [GetRegisteredPlugins] $depname] != -1} {
     # dependee already loaded. do nothing
     #<< "    ...already loaded"
    } elseif {[info exists a($depname)]} {
     # dependee will be loaded first
     set name $depname
     #<< "    ...will be loaded next"
     break
    } else {
     # dependee is unheard of
     #<< "    ...not found"
     error "unresolved plugin dependency: plugin \"$name\" depends on non-existing plug-in \"$depname\""
    }
   }
  } 
  #<< "now registering plugin $name"
  eval ExecuteRegisterPlugin $name $a($name)
  set i [lsearch $nlist $name]
  set nlist [lreplace $nlist $i $i]
 }
}

proc wsurf::GetStandardPlugins {} {
 variable Info

 glob -nocomplain [file join $Info(parentdir) plugins *.plug]
}

proc wsurf::GetLocalPlugins {} {
 variable Info

 set res {}
 if {[info exists ::env(WSPLUGINDIR)]} {
  if {[string match unix $::tcl_platform(platform)]} {
   set dirs [split $::env(WSPLUGINDIR) :]
  } elseif {[string match windows $::tcl_platform(platform)]} {
   set dirs [split $::env(WSPLUGINDIR) ;]
  } else {
   set dirs [split $::env(WSPLUGINDIR) :]
  }   
  foreach dir $dirs {
   set res [concat $res [glob -nocomplain [file join $dir *.plug]]]
  }
 }

 return $res
}

proc wsurf::GetPlugins {} {
 variable Info
 concat [lsort [GetLocalPlugins]] [lsort [GetStandardPlugins]]
}

# -----------------------------------------------------------------------------

proc wsurf::GetStandardConfigurations {} {
 variable Info
 set tmp $Info(parentdir)
 if {[regexp {.+\[.+\].+} $tmp]} { tk_messageBox -message "Error: WaveSurfer file name must not contain \"\[ \]\" characters." }
 # regsub {\[} $tmp \\\[ tmp
 # puts $tmp,[glob  -nocomplain [file join $tmp configurations *.conf]]
 if {[util::freewrapversion]>=5} {
  zvfs::list */configurations/*.conf
 } elseif {[info exists ::wrap]} {  
  set ::wrap(configurations)
 } else { 
  glob -nocomplain [file join $tmp configurations *.conf]
 }
}

proc wsurf::GetLocalConfigurations {} {
 variable Info

 set res {}
 if {[info exists ::env(WSCONFIGDIR)]} {
  if {[string match unix $::tcl_platform(platform)]} {
   set dirs [split $::env(WSCONFIGDIR) :]
  } elseif {[string match windows $::tcl_platform(platform)]} {
   set dirs [split $::env(WSCONFIGDIR) ;]
  } else {
   set dirs [split $::env(WSCONFIGDIR) :]
  }   
  foreach dir $dirs {
   set res [concat $res [glob -nocomplain [file join $dir *.conf]]]
  }
 }
 return $res
}

proc wsurf::GetConfigurations {} {
 variable Info
 set conflist [list]
 foreach dir [concat . $Info(ConfigDir)] {
  set conflist [concat $conflist \
    [lsort [glob -nocomplain [file join $dir *.conf]]]]
 }
 set conflist [concat $conflist \
   [lsort [GetLocalConfigurations]] \
   [lsort [GetStandardConfigurations]]]
}

proc wsurf::ChooseConfigurationDialog {} {
 variable Info

 set wi .config
 catch {destroy $wi}
 toplevel $wi
 wm title $wi [::util::mc "Choose Configuration"]
 wm iconname $wi Dialog
 wm protocol $wi WM_DELETE_WINDOW [list set ::wsPriv(b) cancel]

 if {$::useTile} {
  pack [tk_frame $wi.f2 -relief raised -bd 1] -fill x -side bottom
 } else {
  pack [frame $wi.f2 -relief raised -bd 1] -fill x -side bottom
 }
 pack [frame $wi.f1] -expand yes -fill both -side top -padx 3m -pady 2m

 button $wi.f2.b1 -text [::util::mc OK] -width 6 \
     -command [list set ::wsPriv(b) ok] -default active
 button $wi.f2.b2 -text [::util::mc Cancel] \
     -command [list set ::wsPriv(b) cancel]
 pack $wi.f2.b1 $wi.f2.b2 -side $::ocdir -expand yes -padx 3m -pady 2m

 pack [scrollbar $wi.f1.sb -command [list $wi.f1.lb yview]] -fill y -side right
 pack [listbox $wi.f1.lb -yscroll [list $wi.f1.sb set] -wi 24] -side left \
	 -expand true -fill both

 # due to a bug in tk8.3+/dash-patch, we need to add an explicit button
 # release to the event sequence, or the release event will get lost when the 
 # window is destroyed
 bind $wi.f1.lb <Double-Button-1><ButtonRelease-1> [list set ::wsPriv(b) ok]

 set tmp [::wsurf::GetConfigurations]

 if {$Info(current) != ""} {
   set currConf [$Info(current) cget -configuration]
   set i [lsearch $tmp $currConf]
   if {$i == -1} { set i end }
 } else {
   set i end
 }

 foreach conf $tmp {
  if {[string length $conf]} {
   $wi.f1.lb insert end [file rootname [file tail $conf]]
  }
 }
 $wi.f1.lb insert end standard
 lappend tmp standard
 $wi.f1.lb selection set $i
 $wi.f1.lb activate $i

 wm withdraw $wi
 update idletasks
 set x [expr {[winfo screenwidth $wi]/2 - [winfo reqwidth $wi]/2 \
	 - [winfo vrootx [winfo parent $wi]]}]
 set y [expr {[winfo screenheight $wi]/2 - [winfo reqheight $wi]/2 \
	 - [winfo vrooty [winfo parent $wi]]}]
 if {![info exists Info(choosewinw)]} {
  wm geom $wi +$x+$y
 } else {
  wm geom $wi $Info(choosewinw)x$Info(choosewinh)+$x+$y
 }
 wm deiconify $wi
 focus $wi.f1.lb
 bind $wi.f1.lb <Key-Return> [list set ::wsPriv(b) ok]

 list {
  set oldFocus [focus]
  set oldGrab [grab current $wi]
  if {[string compare $oldGrab ""]} {
   set grabStatus [grab status $oldGrab]
  }
  grab $wi
  focus $wi
 }
 tkwait variable ::wsPriv(b)
 set res ""
 if {$::wsPriv(b) == "ok"} {
  set index [$wi.f1.lb curselection]
  if {$index != ""} {
   set res [lindex $tmp $index]
  }
 }
 
 wm withdraw $wi
 list  {
  if {[string compare $oldGrab ""]} {
   if {![string compare $grabStatus "global"]} {
    grab -global $oldGrab
   } else {
    grab $oldGrab
   }
  }
 }

 set geom [lindex [split [wm geometry $wi] +] 0]
 set Info(choosewinw) [lindex [split $geom x] 0]
 set Info(choosewinh) [lindex [split $geom x] 1]
# set Info(choosewinx) [lindex [split [wm geometry $wi] +] 1]
# set Info(choosewiny) [lindex [split [wm geometry $wi] +] 2]

 return $res
}

# -----------------------------------------------------------------------------

proc wsurf::CreateUniqueTitle {title} {
 variable Info

 set tlist {}
 foreach w $Info(widgets) {
  lappend tlist [cget $w -title]
 }
 set tmp $title
 set n 2
 if {[lsearch $tlist $tmp] == -1} {
  return $title
 }

 while {[lsearch $tlist $tmp] != -1} {
  set tmp "$title #$n"
  incr n
 }
 set tmp
}

# -----------------------------------------------------------------------------

proc wsurf::GetWidgetPath {name} {
 variable Info
 return $Info(path,$name)
}

# -----------------------------------------------------------------------------
# RegisterPlugin
# - this gets called by each plugin, typically when its .plug file is 
#   sourced from wsurf::Initialize 

proc wsurf::RegisterPlugin {name args} {
 variable Info

 # Info(Plugins)   {plug1 plug2 ...}
 # Info(PluginActive,plug1) <boolean>
 # Info(Callback,plugin name,proc name)

 if {[lsearch [GetRegisteredPlugins] $name] != -1} return
 set Info(PluginActive,$name) 1
 
 set Info(PluginData,$name,description) ""
 set Info(PluginData,$name,URL) ""

 # if  ... check if plugin file is wrapped ...
 #  set loc "Built-in"
 # .. else ..
 if {[info exists Info(CurrentPluginPath)]} {
  set loc $Info(CurrentPluginPath)
  set Info(PluginData,$name,location) $loc
 }

 lappend Info(TempPluginReg) $name $args
}

proc wsurf::ExecuteRegisterPlugin {name args} {
 variable Info

 if {[lsearch [GetRegisteredPlugins] $name] != -1} return
 
 set specialOpts [list]
 foreach {opt val} $args {
  if [string match -*::* $opt] {
   lappend specialOpts $opt $val
   continue
  }
  if {![info exists Info(PluginOption,$opt)]} {
   error "Invalid option \"$opt\""
  }
  set optname $Info(PluginOption,$opt)
  switch -glob -- $optname {
   *Proc {
    set Info(Callback,$name,$optname) $val
   }
   before {
     set before $val
   }
   default {
    set Info(PluginData,$name,$optname) $val
   }
  } 
 }
 foreach {opt val} $specialOpts {
  set handler [lindex [split [string trimleft $opt -] :] 0]
  if {[info exists Info(Callback,$handler,registerCallbackProc)]} {
   $Info(Callback,$handler,registerCallbackProc) $name $opt $val
  } else {
   error "unresolved callback option \"$opt\" (by plugin \"$name\")"
  }
 }
 if {[info exists before]} {
   set index [lsearch [GetRegisteredPlugins] $before]
   set Info(Plugins) [linsert $Info(Plugins) $index $name]
 } else {
   lappend Info(Plugins) $name
 }
}
 
# -----------------------------------------------------------------------------

proc wsurf::GetRegisteredPlugins {} {
 variable Info
 return $Info(Plugins) 
}

# -----------------------------------------------------------------------------

proc wsurf::PluginEnabled {plug} {
 variable Info
 
 if {[info exists Info(PluginActive,$plug)]} {
  return $Info(PluginActive,$plug)
 } else {
  return 0
 }
}

# -----------------------------------------------------------------------------
# for backward compatibility of configuration files

namespace eval ssurfer {}

proc ssurfer::PluginEnabled {plug} {
 return [wsurf::PluginEnabled $plug]
}

# -----------------------------------------------------------------------------

proc wsurf::GetCurrent {} {
 variable Info
 return $Info(current)
}

# -----------------------------------------------------------------------------

proc wsurf::MakeCurrent {w} {
 variable Info

 while {![info exists [namespace current]::${w}::data]} {
  set w [winfo parent $w]
 }

 if {$Info(current) != ""} {
   if {[string compare $Info(current) $w] == 0} return
   _callback $Info(current) stateProc 0
 }

 set Info(current) $w
 _callback $w stateProc 1

 # --- here we use hard-coded colors to indicate current widget 
 #   - blue+white+border = current
 #   - gray+lightgray = not current
 # check: how can we get the colors from windows?
 foreach widget $Info(widgets) {
  [set [namespace current]::${widget}::widgets(title)] config \
    -background #7f7f7f -fg #cfcfcf
  [set [namespace current]::${widget}::widgets(top)] config -relief flat
 }
 [set [namespace current]::${w}::widgets(title)] config \
   -background #00007f -fg #ffffff
 [set [namespace current]::${w}::widgets(top)] config -relief solid

 set pane [lindex [_getPanes $w] 0]
 if {$pane != ""} {
   set c [$pane canvas]
   focus $c
 }
}

# -----------------------------------------------------------------------------

proc wsurf::NeedSave {} {
 variable Info
 foreach w $Info(widgets) {
  upvar [namespace current]::${w}::data d
  if {$d(soundChanged)} { return 1 }
  foreach pane [_getPanes $w] {
   foreach res [_callback $w needSaveProc $pane] {
    if {$res} { return 1 }
   }
  }
 }
 return 0
}

# -----------------------------------------------------------------------------

proc wsurf::getopt {arglistVar} {
 variable Info
 upvar 1 $arglistVar argv

 foreach plug $Info(Plugins) {
  if {$Info(PluginActive,$plug)} {
   if {[info exists Info(Callback,$plug,getoptProc)]} {
    set cb $Info(Callback,$plug,getoptProc)
    eval $cb argv
   }
  }
 }
}

# -----------------------------------------------------------------------------
# Internal Widget Methods
# -----------------------------------------------------------------------------

proc wsurf::zoomin {w} {
 upvar [namespace current]::${w}::data d

 set pos $d(selectionT0)
 set left $d(xviewT1)
 set right $d(xviewT2)
 set pane [lindex [_getPanes $w] 0]
 if {$pane != ""} {
  set length [$pane cget -maxtime]
 } else {
  set length [$d(sound) length -unit seconds]
 }
 set delta [expr ($right-$left)/(6*$length)]
 set newleft  [expr $pos/$length-$delta]
 set newright [expr $pos/$length+$delta]
 xzoom $w $newleft $newright
 update
 xscroll $w moveto $newleft
}

proc wsurf::zoomout {w} {
 upvar [namespace current]::${w}::data d

 set pos $d(selectionT0)
 set left $d(xviewT1)
 set right $d(xviewT2)
 set pane [lindex [_getPanes $w] 0]
 if {$pane != ""} {
  set length [$pane cget -maxtime]
 } else {
  set length [$d(sound) length -unit seconds]
 }
 set delta [expr 1.67*($right-$left)/$length]
 set newleft  [util::max [expr $pos/$length-$delta] 0.0]
 set newright [util::min [expr $pos/$length+$delta] 1.0]
 xzoom $w $newleft $newright
 update
 xscroll $w moveto $newleft
}

proc wsurf::zoomsel {w} {
 upvar [namespace current]::${w}::data d

 set pane [lindex [_getPanes $w] 0]
 if {$pane != ""} {
  set length [$pane cget -maxtime]
 } else {
  set length [$d(sound) length -unit seconds]
 }
 set start $d(selectionT0)
 set end $d(selectionT1)
 if {$start == $end} return
 xzoom $w [expr {$start/$length}] [expr {$end/$length}]
 update
 xscroll $w moveto [expr {$start/$length}]
}

proc wsurf::zoomall {w} {
 xscroll $w moveto 0.0
 xzoom $w 0.0 1.0
}

proc wsurf::xzoom {w frac1 frac2} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 if {[info exists d(xzoomLock)]} return
 set d(xzoomLock) 1

 set time1 [frac->t $w $frac1]
 set time2 [frac->t $w $frac2]
 
 if {[llength [_getPanes $w]] == 0} return
 set winwidth [[lindex [_getPanes $w] 0] cget -width]
 if {$time1 == $time2} {
  set d(pixelsPerSecond) $Info(Prefs,maxPixelsPerSecond)
 } else {
  set d(pixelsPerSecond) [expr {(double($winwidth)/($time2-$time1))}]
 }
 if {$d(maxtime)!=0.0 && $d(maxtime)*$d(pixelsPerSecond) < $winwidth} {
  #<< "setting pps to $winwidth/$d(maxtime) = [expr {$winwidth/$d(maxtime)}]"
  set d(pixelsPerSecond) [expr {$winwidth/$d(maxtime)}]
 }
 foreach pane [_getPanes $w] {
  $pane configure -pixelspersecond $d(pixelsPerSecond)
 }
 set d(xviewT1) $time1
 set d(xviewT2) $time2

 _redraw $w
 # xscroll $w moveto $frac1
 if {$Info(blockRecursion) == 0} {
   set Info(blockRecursion) 1
   foreach slave $d(slaves) {
     if {[winfo exists $slave]} {
       xzoom $slave $frac1 $frac2
       update ; # Make sure wavebars and canvases synch
       xscroll $slave moveto $frac1
     }
   }
   set Info(blockRecursion) 0
 }
 unset d(xzoomLock)
}

# -----------------------------------------------------------------------------

proc wsurf::create {w args} {
 variable Info

 if {![info exists Info(Initialized)]} Initialize
 
 namespace eval [namespace current]::$w {
  variable widgets
  variable data
 }
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 array set a [list \
   -state expanded \
   -icons $Info(Prefs,icons) \
   -messageproc "" \
   -progressproc "" \
   -playpositionproc "" \
   -slaves "" \
   -collapser 1 \
   -sound "" \
   -configuration "" \
   -playmapfilter "1" \
   -wavebarheight 25 \
   -title "Sound"
 ]
 array set a $args
 
 set d(messageLocked) 0
 set d(paneCount) 0
 set d(panes) {}
 set d(canvasWidth) 1
 set d(xviewT1) 0.0
 set d(xviewT2) 0.0
 if {$a(-sound) == ""} {
  if {$Info(Prefs,linkFile)} {
   set d(sound) [snack::sound -rate $Info(Prefs,defRate) \
     -encoding $Info(Prefs,defEncoding) -channels $Info(Prefs,defChannels) \
     -file [file join $Info(Prefs,tmpDir) \
     $w.[pid].wav] -debug $Info(snackDebug) \
     -changecommand [namespace code [list _soundChanged $w]]]
  } else {
   set d(sound) [snack::sound -rate $Info(Prefs,defRate) \
     -encoding $Info(Prefs,defEncoding) -channels $Info(Prefs,defChannels) \
     -debug $Info(snackDebug) \
     -changecommand [namespace code [list _soundChanged $w]]]
  }
  set d(externalSoundObj) 0
 } else {
  set d(sound) $a(-sound)
  set d(externalSoundObj) 1
 }
 set d(mintime) 0
 set d(maxtime) 0
 set d(pixelsPerSecond) 400.0
 set d(xfracDown) 0.0
 set d(messageProc) $a(-messageproc)
 set d(progressProc) $a(-progressproc)
 set d(playpositionProc) $a(-playpositionproc)
 set d(slaves) $a(-slaves)
 set d(configuration) $a(-configuration)
 set d(isRecording) 0
 set d(isPaused) 0
 set d(playStartPos) 0
 set d(soundChanged) 0
 set d(fileName) ""
 set d(linkFile) $Info(Prefs,linkFile)
 set d(oldFracs) ""
 set d(oldXScrollArgs) 0
 set d(scrollInterval) 0
 set Info(undoCmd) ""
 set Info(redoCmd) ""
 set d(cutTime)  -1
 set d(cutStart) 0
 set d(icons) $a(-icons)
 set d(mapFilterStr) $a(-playmapfilter)
 if {$d(mapFilterStr) == 1} {
  set d(mapFilter) ""
 } else {
  set d(mapFilter) [eval snack::filter map $d(mapFilterStr)]
 }
 set d(looping) 0
 set d(loopStartPos) 0
 set d(selectionT0) 0.0
 set d(selectionT1) 0.0
 set d(showExitDialog) 1

 # main container frame
 if {$::useTile} {
  tk_frame $w -bd 1 -relief flat
 } else {
  frame $w -bd 1 -relief flat
 }
 set wid(top) $w.top
 rename $w ::$wid(top)
 #[set wid(top) [namespace current]::$w.top]
 proc ::$w {cmd args} "return \[eval wsurf::\$cmd $w \$args\]"

 bind $w <Destroy> [namespace code "if \[string match %W $w\] \"_delete $w\""]

 # top level widgets
 if {$::useTile} {
  set wid(titlebar) [tk_frame $w.titlebar -relief solid -bd 0] 
 } else {
  set wid(titlebar) [frame $w.titlebar -relief solid -bd 0] 
 }
 set wid(workspace) [frame $w.workspace]

 if {$::useTile} {
  set wid(collapser) [button $wid(titlebar).collapser \
   -style Toolbutton -padding 0 \
   -command [namespace code [list _collapseToggle $w]] -takefocus 0]
  set wid(title_f) [frame $wid(titlebar).title]
  set wid(title) [tk_label $wid(titlebar).title.t -anchor w -foreground white]
 } else {
  set wid(collapser) [button $wid(titlebar).collapser \
   -highlightthickness 0 -bd 1 -relief flat -width 16 -height 10\
   -command [namespace code [list _collapseToggle $w]] -takefocus 0]
  set wid(title_f) [frame $wid(titlebar).title]
  set wid(title) [label $wid(titlebar).title.t -anchor w]
 }
 pack $wid(title) -fill both -expand 1
 pack propagate $wid(title_f) 0

 array set opCol [list beg black play black playall blue \
		      pause black stop black end black record red]
 array set imOp  [list zoomin zoomin zoomout zoomout \
		      zoomall zoomall zoomsel zoomsel \
		      print printDialog close closeWidget playloop playloop \
    		      play play playall playall beg beg end end stop stop pause pause \
		      record record]
 array set iconType [list beg image play image playall image \
			 playloop image pause image stop image end image \
			 record image print image close image \
			 zoomin image zoomout image\
			 zoomall image zoomsel image]
 array set iconName [list beg snackPlayPrev play snackPlay playall \
   snackPlay pause snackPause stop snackStop \
			 end snackPlayNext record snackRecord]

 #<< d(icons)=$d(icons)
 set buttons {}
 foreach icon [list beg play playall playloop pause stop end record \
		   zoomin zoomout zoomall zoomsel print close] {
  if {$Info(Prefs,$icon) == 1} {
   #<< "creating icon $icon"
   if {[string match bitmap $iconType($icon)]} {
    set wid(${icon},button) [button $wid(titlebar).${icon}button \
     -bitmap $iconName($icon) -fg $opCol($icon) \
     -command [namespace code [list $icon $w]] \
     -highlightthickness 0 -bd 1 -relief flat -takefocus 0]
     if {$icon == "play"} {
       bind $wid(${icon},button) <<PopupEvent>> \
	   [namespace code [list playPopupMenu $w %X %Y]]
     }
    lappend buttons $wid(${icon},button)
   } else {
    set op $imOp($icon)
    if {$::useTile} {
     set wid($op,button) [button $wid(titlebar).{$op}button \
     -image $Info(Img,$icon) -style Toolbutton -padding 0 \
     -command [namespace code [list $op $w]] -takefocus 0]
    } else {
     set wid($op,button) [button $wid(titlebar).{$op}button \
     -image $Info(Img,$icon) -highlightthickness 1 -bd 1 \
     -command [namespace code [list $op $w]] -relief flat -takefocus 0]
    }
    lappend buttons $wid($op,button)
   }
  }
 }

 grid $wid(titlebar) -sticky we
 if {[string match expanded $a(-state)]} {
  _collapseToggle $w; # grid workspace frame and configure collapser button
 } else {
  $wid(collapser) configure -image $Info(Img,plus)
 }
 grid rowconfigure $w 1 -weight 1
 grid columnconfigure $w 0 -weight 1
 if {$a(-collapser) != 0} {
  grid $wid(collapser) -column 0 -row 0 -sticky news
  grid $wid(title_f)   -column 1 -row 0 -sticky news
 }
 set i 2
 foreach button $buttons {
  grid $button -column $i -row 0 -sticky news
  incr i
 }

 grid columnconfigure $wid(titlebar) 1 -weight 1

 util::setClass $w Wsurf

 _callback $w widgetCreatedProc

 MakeCurrent $w

 # create wavebar

 set wid(wavebar) $wid(workspace).wavebar
 wavebar::create $wid(wavebar) -sound $d(sound) \
   -height $a(-wavebarheight) \
   -zoomcommand [namespace code [list xzoom $w]] \
   -formattimecommand [namespace code [list formatTime $w]] \
   -command [namespace code [list xscroll $w]] -state passive -shadowwidth 1 \
   -messageproc [namespace code [list messageProc $w]] -foreground black

 pack $wid(wavebar) -side top -expand 0 -fill both
 pack propagate $wid(wavebar) 0
 set d($wid(wavebar),lastPropertyPage) 1
 set d(,lastPropertyPage) 0

 resizer::addResizer $wid(wavebar) -type divider -height 4 \
   -minheight 10 -maxheight 300

 bind $wid(wavebar).c0 <<PopupEvent>> \
	 [namespace code [list popupMenu $w %X %Y %x %y $wid(wavebar)]]

 bind $wid(title) <<PopupEvent>> \
	 [namespace code [list popupMenu $w %X %Y %x %y ""]]

 bind $wid(title) <Enter> [namespace code [list showInfo $w]]

 bind $wid(title) <Leave> [namespace code [list clearMessages $w]]

 configure $w -title $a(-title)

 if {$a(-configuration) != ""} {
  loadConfiguration $w $a(-configuration)
 }

 lappend Info(widgets) $w

 return $w
}

# -----------------------------------------------------------------------------

proc wsurf::xscroll {w args} {
 variable Info
 upvar [namespace current]::${w}::data d

 foreach pane [_getPanes $w] {
  set c [$pane canvas]
  eval $c xview $args
#  foreach {frac1 frac2} [$c xview] break
  if {[$pane cget -maxtime] > 0.0} {
   set dt [expr [$pane cget -width]/$d(pixelsPerSecond)/[$pane cget -maxtime]]
   set frac1 [expr [$c canvasx 0.0]/$d(pixelsPerSecond)/[$pane cget -maxtime]]
   set frac2 [expr $dt+$frac1]
  } else {
   set frac1 0.0
   set frac2 1.0
  }
  _callback $w scrollProc $pane $frac1 $frac2
 }
 if {$Info(blockRecursion) == 0} {
   set Info(blockRecursion) 1
   foreach slave $d(slaves) {
     if {[winfo exists $slave]} {
       eval xscroll $slave $args
     }
   }
   set Info(blockRecursion) 0
 }
}

# -----------------------------------------------------------------------------

proc wsurf::_delete {w} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 if {$w == $Info(current)} {
  set Info(current) ""
 }
 while {[llength $d(panes)] != 0} {
  _callback $w paneDeletedProc [lindex $d(panes) 0]
  set d(panes) [lreplace $d(panes) 0 0]
 }
 _callback $w widgetDeletedProc
 if {![info exists d]} return
 if {$d(externalSoundObj) == 0} {
  $d(sound) destroy
 }
 catch {file delete -force [file join $Info(Prefs,tmpDir) $w.[pid].wav]}
 unset wid
 unset d
 
 if {[string compare $Info(PropsDialogWidget) $w] == 0} {
  destroy .props
 }

 set n [lsearch $Info(widgets) $w]
 set Info(widgets) [lreplace $Info(widgets) $n $n]

 if {$n > 0} {
  MakeCurrent [lindex $Info(widgets) [expr {$n-1}]]
 } else {
  if {[llength $Info(widgets)] > 0} {
   MakeCurrent [lindex $Info(widgets) end]
  }
 }

 #  foreach key [array names Info $w,*] {unset Info($key)}
 if {[string length [info command $w]]} {rename $w {}}
}

# -----------------------------------------------------------------------------

proc wsurf::_collapseToggle {w} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d
 
 set ws $wid(workspace)
 if {[string match grid [winfo manager $ws]]} {
  grid forget $ws
  $wid(collapser) configure -image $Info(Img,plus)
 } else {
  grid $ws -row 1 -sticky news
  $wid(collapser) configure -image $Info(Img,minus)
 }
}

# -----------------------------------------------------------------------------
# _showYSB - display vertical scrollbars or fillers as needed

proc wsurf::_showYSB {w} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d
 
 set ysbNeeded 0
 foreach pane [_getPanes $w] {
  if {[$pane ysbNeeded]} {set ysbNeeded 1}
 }
 # if at least one of the panes needs a scrollbar...
 foreach pane [_getPanes $w] {
  $pane configure -yscrollbar $ysbNeeded
 }
}

# -----------------------------------------------------------------------------
# _callback - Invoke registered callbacks 
# Returns a list containing the results from each call

proc wsurf::_callback {w proc args} {
 variable Info

 set result {}
 foreach plug $Info(Plugins) {
  if {$Info(PluginActive,$plug)} {
   if {[info exists Info(Callback,$plug,$proc)]} {
    #<< "invoking callback: plugin=$plug\tproc=$proc"
    set cb $Info(Callback,$plug,$proc)
    lappend result [eval [list $cb] [list $w] $args]
   }
  }
 }
 return $result
}

# -----------------------------------------------------------------------------

proc wsurf::_getPanes {w} {
 upvar [namespace current]::${w}::data d
 
 return $d(panes)
}

# -----------------------------------------------------------------------------
# _redraw  - redraw all panes

proc wsurf::_redraw {w} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 foreach pane [_getPanes $w] {
  _scheduleRedrawPane $w $pane
 }
}

proc wsurf::updateBounds {w fix} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 set d(oldFracs) ""
 foreach pane [_getPanes $w] {
  updatePaneBounds $w $pane $fix
 }
}


# _scheduleRedrawPane 
# schedule a _redrawPane to occur when the application is idle

proc wsurf::_scheduleRedrawPane {w pane} {
 upvar [namespace current]::${w}::data d
 upvar [namespace current]::${w}::widgets wid
 variable Info

 # configure wavebar zoomlimit based on maxPixelsPerSecond. This is done 
 # here because this proc gets called when a vtcanvas window is
 # resized, and we want to do this whenever the canvas width 
 # has changed. Should rename things I guess...
 $wid(wavebar) configure -zoomlimit \
   [expr {1.0*[winfo width $pane]/$Info(Prefs,maxPixelsPerSecond)}]

 set cmd1 [namespace code [list _redrawPane $w $pane]]
 set cmd2 [list after 0 $cmd1]

 after cancel $cmd1
 after cancel $cmd2
 after idle $cmd2
}

# -----------------------------------------------------------------------------
# _redrawPane - redraw the contents of the pane

proc wsurf::_redrawPane {w pane} {
 upvar [namespace current]::${w}::data d

 updatePaneBounds $w $pane dummy
 _callback $w redrawProc $pane
}

proc wsurf::updatePaneBounds {w pane fix} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 # ---

 _showYSB $w

 set time0 ""
 set time1 ""
 set val0 ""
 set val1 ""

 if {[$d(sound) length]>0} {
  set time0 0.0
  set time1 [$d(sound) length -unit seconds]
 }
 
 # get the bounds for all plugins.
 # To be continued... also, look at updateBounds
 foreach p [_getPanes $w] {
   foreach boundlist [_callback $w getBoundsProc $p] {
     if {[llength $boundlist] == 0} continue
     foreach {t0 v0 t1 v1} $boundlist break
     if {$time0!=""} {set time0 [util::min $t0 $time0]} else {set time0 $t0}
     if {$time1!=""} {set time1 [util::max $t1 $time1]} else {set time1 $t1}
   }
 }
 foreach boundlist [_callback $w getBoundsProc $pane] {
  if {[llength $boundlist] == 0} continue
  foreach {t0 v0 t1 v1} $boundlist break
  if {$val0!=""}  {set val0 [util::min $v0 $val0]} else {set val0 $v0}
  if {$val1!=""}  {set val1 [util::max $v1 $val1]} else {set val1 $v1}
 }
 if {$time0 == ""} {set time0 0.0}
 if {$time1 == ""} {set time1 0.0}
 if {$val0  == ""} {set val0 0.0}
 if {$val1  == ""} {set val1 0.0}
 
 #<< pane=$pane
 #<< "mintime=$time0\tmaxtime=$time1"
 #<< "minval =$val0\tmaxval =$val1"
 
 set d(mintime) $time0
 set d(maxtime) $time1
 set p $pane
 $p configure -minvalue $val0 -maxvalue $val1 -mintime $time0 -maxtime $time1
 set c [$p canvas]

 if {$fix != "noraise"} {
  $c raise cursor
 }
 $c raise top
 $c lower bottom

 set x0 [expr {[$p getCanvasX $time0]+1}]
 set y0 [$p getCanvasY $val1]
 # set x1 [expr [util::max [$p getCanvasX $time1] [winfo width $c]]-1]
 set x1 [expr {[$p getCanvasX $time1]-1}]
 set y1 [$p getCanvasY $val0]

 if {[$pane cget -width] > 1+[$pane getCanvasX $d(maxtime)] && $d(maxtime)!=$d(mintime)} {
  #<< "pane-width=[$pane cget -width],canvasX maxtime = [$pane getCanvasX $d(maxtime)]"
  #<< "mintime=$d(mintime), maxtime=$d(maxtime)"
  xzoom $w 0 1; return
 }
 
 $c configure -scrollregion [list $x0 $y0 $x1 $y1]
 $c xview moveto [lindex [$wid(wavebar) getfracs] 0]
 
 [$p yaxis] configure -scrollregion \
   [list 0 [$p getCanvasY $val1] 0 [$p getCanvasY $val0]]

 $wid(wavebar) configure -mintime $d(mintime) -maxtime $d(maxtime) \
   -pixelspersecond $d(pixelsPerSecond)

}

proc wsurf::frac->t {w frac} {
 upvar [namespace current]::${w}::data d
 
 expr {$d(mintime)+($d(maxtime)-$d(mintime))*$frac}
}

# conversion: time to fraction
proc wsurf::t->frac {w t} {
 upvar [namespace current]::${w}::data d
 if {$d(mintime) == $d(maxtime)} {return 0.0}
 expr {double($t-$d(mintime))/($d(maxtime)-$d(mintime))}
}

# -----------------------------------------------------------------------------
# _xsbSet - bound to -xscrollcommand of each pane's main canvas

proc wsurf::_xsbSet {w frac1 frac2} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 if {[string compare $d(oldFracs) $frac1,$frac2] == 0} return
 set d(oldFracs) $frac1,$frac2

 $wid(wavebar) setfracs $frac1 $frac2
 set d(xviewT1) [frac->t $w $frac1]
 set d(xviewT2) [frac->t $w $frac2]
}

# -----------------------------------------------------------------------------

proc wsurf::_setCursor {w p x y t v} {

 if {![snack::audio active]} {
  foreach pane [_getPanes $w] {
   set c [$pane canvas]
   set h [$pane cget -scrollheight]
   $c coords cursor $x 0 $x $h
  }
 }

 if {$p == "" || $x < 0} return

 upvar [namespace current]::${w}::data d
 array unset d msg,*
 _callback $w cursorMovedProc $p $t $v
}

proc wsurf::formatTime {w t} {
  variable Info
  upvar [namespace current]::${w}::data d

  if {$Info(Prefs,timeFormat) == "samples"} {
    set s [$w cget -sound]
    expr {int($t*[$s cget -rate])}
  } elseif {$Info(Prefs,timeFormat) == "seconds"} {
    return [format "%.3f" $t]s
  } elseif {$Info(Prefs,timeFormat) == "10ms frames"} {
    set s [$w cget -sound]
    expr {int($t*100)}
  } elseif {$Info(Prefs,timeFormat) == "PAL frames"} {
    set s [$w cget -sound]
    expr {int($t*25)}
  } elseif {$Info(Prefs,timeFormat) == "NTSC frames"} {
    set s [$w cget -sound]
    expr {int($t*30)}
  } else {
    set fmt $Info(Prefs,$Info(Prefs,timeFormat))
    util::formatTime $t $d(maxtime) %.${fmt}f
  }
}

# -----------------------------------------------------------------------------
# External methods
# -----------------------------------------------------------------------------

# popupMenu
# - build and post the popup menu

proc wsurf::popupMenu {w X Y x y {pane ""}} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 MakeCurrent $w
 set m $w.popup
 if {[winfo exists $m]} {destroy $m}
 menu $m -tearoff 0

 # all panes
 
 # give all plugins chance to own main pop-up menu
 if {$pane==""} {set cp $wid(wavebar)} else {set cp $pane} 
 if {$pane!="" && ![string match $pane $wid(wavebar)] && \
  [string match *1* [_callback $w addMenuEntriesProc $cp $m query $x $y]]} {
#  set newMain [menu $m.main -tearoff 0]
#  set oldMain $m
  _callback $w addMenuEntriesProc $cp $m main $x $y
#  set m $newMain
 }
 # let all plugins add their entries to the 'create' menu
 set create [menu $m.create -tearoff 0]
 $m add cascade -label [::util::mc "Create Pane"] -menu $create -columnbreak 1
_callback $w addMenuEntriesProc $cp $m create $x $y

 #  add "Delete Pane" item for all panes except the wavebar
 if {$pane!="" && ![string match $pane $wid(wavebar)]} {
  $m add command -label [::util::mc "Delete Pane"] \
    -command [namespace code [list deletePane $w $pane]]
 }

 # all panes

 $m add command -label [::util::mc "Apply Configuration..."] \
   -command [namespace code [list _applyConfiguration $w]]
 $m add command -label [::util::mc "Save Configuration..."] \
   -command [namespace code [list saveConfiguration $w]]
 $m add command -label [::util::mc "Properties..."] \
   -command [namespace code [list _propertiesDialog $w $pane]]
 
 # let all plugins add their entries to the main menu
 
 if {$pane==$wid(wavebar)} {set pp ""} else {set pp $pane}
 _callback $w addMenuEntriesProc $pp $m "" $x $y

 if {[info exists oldMain]} {
  $oldMain add cascade -label [::util::mc "Main Menu"] -menu $newMain -columnbreak 1
 }

 # post the menu

 if {[string match macintosh $::tcl_platform(platform)]} {
  tk_popup $w.popup $X $Y 0
 } else {
  tk_popup $w.popup $X $Y
 }
}

proc wsurf::_applyConfiguration {w} {
 set conf [wsurf::ChooseConfigurationDialog]
 if {$conf == ""} return
 if {$conf == "standard"} {
  set conf ""
 }
 applyConfiguration $w $conf
}

# -----------------------------------------------------------------------------

proc wsurf::configure {w args} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 if {[llength $args]%2} {
  error "wrong # args, must be wsurf::configure ?option value?..."
 }
 foreach {opt val} $args {
  switch -- $opt {
   -background -
   -foreground -
   -troughcolor -
   -cursorcolor {
    $wid(wavebar) configure $opt $val
   }
   -icons {

   }
   -pixelspersecond {
     if {$val > $Info(Prefs,maxPixelsPerSecond)} {
       set val $Info(Prefs,maxPixelsPerSecond)
     }
     if {$val < 1.0} {
       set val 1
     }
     set d(pixelsPerSecond) $val
     if {[lindex [_getPanes $w] 0] != ""} {
       set winwidth [[lindex [_getPanes $w] 0] cget -width]
       set dt [expr {double($winwidth) / $val}]
       set df [t->frac $w $dt] 
       $w xzoom $d(xviewT1) [expr {$d(xviewT1) + $df}]
     }
     $wid(wavebar) configure -pixelspersecond $val
   }
   -wavebarheight {
    $wid(wavebar) configure -height $val
   }
   -state {
    if {![string match [$w cget -state] $val]} {
     _collapseToggle $w
    }
   }
   -messageproc {
    set d(messageProc) $val
   }
   -progressproc {
    set d(progressProc) $val
   }
   -playpositionproc {
    set d(playpositionProc) $val
   }
   -slaves {
    if {[lsearch $val $w] != -1} {
     error "Master widget can not be slave of itself"
    }
    set d(slaves) $val
   }
   -title {
    set d(title) [CreateUniqueTitle $val]
    $wid(title) config -text $d(title)
    set Info(path,$d(title)) $w
   }
   -configuration {
    set d(configuration) $val
    applyConfiguration $w $d(configuration)
   }
   -playmapfilter {
    set d(mapFilterStr) $val
    _confPlayProps $w mapFilterStr
   }
   -selection {
# Prevent master-slave loops
    if {$d(selectionT0) == [lindex $val 0] && \
	$d(selectionT1) == [lindex $val 1]} return
    set d(selectionT0) [lindex $val 0]
    set d(selectionT1) [lindex $val 1]
    if {$d(isPaused)} {
     stop $w
    }
    foreach pane [_getPanes $w] {
     $pane configure -selection [list $d(selectionT0) $d(selectionT1)]
     _callback $w setSelectionProc $pane $d(selectionT0) $d(selectionT1)
    }
    # update wavebar selection
    $wid(wavebar) configure -selection [list $d(selectionT0) $d(selectionT1)]
    foreach slave $d(slaves) {
     if {[winfo exists $slave]} {
      eval configure $slave $args
     }
    }
   }
   -sound {
    $d(sound) destroy
    set d(sound) $val
    set d(externalSoundObj) 1
    $wid(wavebar) configure -sound $val
    $val configure -changecommand [namespace code [list _soundChanged $w]]
    _soundChanged $w New
   }
   default {
    error "unknown option \"$opt\""
   }
  }
 }
}

proc wsurf::cget {w option} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 switch -- $option {
  -background -
  -foreground -
  -troughcolor -
  -cursorcolor {
   return [$wid(wavebar) cget $option]
  }
  -icons {
   return $d(icons)
  }
  -pixelspersecond {
   return $d(pixelsPerSecond)
  }
  -zoomfracs {
   # zoomfracs is a misleading name, change...
   return [list $d(xviewT1) $d(xviewT2)]
  }
  -wavebarheight {
   return [$wid(wavebar) cget -height]
  }
  -state {
   if {[string match grid [winfo manager $wid(workspace)]]} {
    return expanded
   } else {
    return collapsed
   }
  }
  -messageproc {
   set d(messageProc)
  }
  -progressproc {
   set d(progressProc)
  }
  -playpositionproc {
   set d(playpositionProc)
  }
  -slaves {
   set d(slaves)
  }
  -title {
   set d(title)
  }
  -playmapfilter {
   set d(mapFilterStr)
  }
  -configuration {
   set d(configuration)
  }
  -selection {
   list $d(selectionT0) $d(selectionT1)
  }
  -sound {
   set d(sound)
  }
 }
}

# -----------------------------------------------------------------------------

proc wsurf::loadConfiguration {w configFile} {
 set widget $w
 source $configFile
}

# -----------------------------------------------------------------------------
# addPane - add a new pane to the widget
#

proc wsurf::addPane {w args} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d
 
 # --- fix real option handling incl. error checking !! ---
 array set a [list \
   -before $wid(wavebar) \
   -state normal \
   -minheight 10 \
   -maxheight 2048 \
   -yaxiswidth ""]

 foreach {opt val} $args {
  if {[info exists a($opt)]} {
   set a($opt) $val
  } else {
   lappend paneopts $opt $val
  }
 }

 set pane $wid(workspace).pane_[incr d(paneCount)]
 if {[string length [set before $a(-before)]]==0} {
  lappend d(panes) $pane
 } elseif {[string match $a(-before) $wid(wavebar)]} {
  lappend d(panes) $pane
 } else {
  set i [lsearch -exact $d(panes) $a(-before)]
  set d(panes) [linsert $d(panes) $i $pane]
 }
 $wid(wavebar) configure -state interactive

 if {$a(-yaxiswidth) == ""} {
  set width $Info(Prefs,yaxisWidth)
 } else {
  set width $a(-yaxiswidth)
 }
 lappend paneopts \
   -selection        [list $d(selectionT0) $d(selectionT1)] \
   -xscrollcommand   [namespace code [list _xsbSet $w]] \
   -selectioncommand [namespace code [list _drawSelection $w]] \
   -redrawcommand    [namespace code [list _scheduleRedrawPane $w $pane]] \
   -cursorcommand    [namespace code [list _setCursor $w $pane]] \
   -pixelspersecond  [$w cget -pixelspersecond] \
   -formattimecommand [namespace code [list formatTime $w]] \
   -yaxiswidth       $width \
   -state            $a(-state)

 eval vtcanvas::create $pane $paneopts
 set c [$pane canvas]

 pack $pane -before $before -expand 0 -fill both
 pack propagate $pane 0

 resizer::addResizer $pane -type divider -height 4 \
   -minheight $a(-minheight) -maxheight $a(-maxheight)

 set d($pane,minheight) $a(-minheight)
 set d($pane,maxheight) $a(-maxheight)
 set d($pane,state)     $a(-state)
 set d($pane,lastPropertyPage) 1
 set d($pane,showExitDialog) 1

 if {[string equal "normal" $a(-state)]} {
  bind $c <<PopupEvent>> [namespace code [list popupMenu $w %X %Y %x %y $pane]]
 }
 bind $c <Leave> [namespace code [list clearMessages $w]]

 _callback $w paneCreatedProc $pane
 updatePaneBounds $w $pane dummy
 
 return $pane
}

proc wsurf::_movePane {w pane before} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 pack forget $pane
 pack $pane -before $before -expand 0 -fill both
 pack propagate $pane 0
}

proc wsurf::_drawSelection {w _t0 _t1 x event} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 set t0 [util::max $d(mintime) [util::min $_t0 $_t1]]
 set t1 [util::min $d(maxtime) [util::max $_t0 $_t1]]
 $w configure -selection [list $_t0 $_t1]

 if {[string compare $event <ButtonRelease-1>] == 0} {
  set d(scrollInterval) 0
  return
 }

 set l [expr {int($d(xviewT1)*$d(pixelsPerSecond) - $x)}]
 set r [expr {int($x - $d(xviewT2)*$d(pixelsPerSecond))}]

 if {$l > 0} {
  if {$d(scrollInterval) == 0} {
   after 10 [namespace code [list _selectionScroll $w -1]]
  }
  if {$l > 50} {
   set d(scrollInterval) 30
  } elseif {$l > 15} {
   set d(scrollInterval) 100
  } else {
   set d(scrollInterval) 200
  }
 } elseif {$r > 0} {
  if {$d(scrollInterval) == 0} {
   after 10 [namespace code [list _selectionScroll $w 1]]
  }
  if {$r > 50} {
   set d(scrollInterval) 30
  } elseif {$r > 15} {
   set d(scrollInterval) 100
  } else {
   set d(scrollInterval) 200
  }
 } else {
  set d(scrollInterval) 0
 }
}

proc wsurf::_selectionScroll {w direction} {
 upvar [namespace current]::${w}::data d
 upvar [namespace current]::${w}::widgets wid

 if {[info exists d(scrollInterval)] == 0 || $d(scrollInterval) == 0} return

 xscroll $w scroll $direction unit

 foreach pane [_getPanes $w] {
  foreach {t0 t1} [$pane cget -selection] break
  if {$direction == 1} {
   $pane configure -selection [list $t0 $d(xviewT2)]
   _callback $w setSelectionProc $pane $t0 $d(xviewT2)
  } else {
   $pane configure -selection [list $d(xviewT1) $t1]
   _callback $w setSelectionProc $pane $d(xviewT1) $t1
  }
 }

 # update wavebar selection
 $wid(wavebar) configure -selection [list $t0 $t1]

 after $d(scrollInterval) [namespace code [list _selectionScroll $w $direction]]
}

# -----------------------------------------------------------------------------
# deletePane
# - destroy all the pane's widgets and clear its fields in the arrays

proc wsurf::deletePane {w pane} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d
 
 set doCheck 0
 foreach res [_callback $w needSaveProc $pane] {
  if {$res} { set doCheck 1 }
 }
 if {$doCheck} {
  if {$d($pane,showExitDialog)} {
   set d($pane,showExitDialog) 0
   if {[string match no \
     [tk_messageBox -message "You have unsaved changes.\nDo you\
     really want to delete this pane?" -type yesno -icon question]]} {
    set d($pane,showExitDialog) 1
    return
   }
  } else {
   return
  }
 }
 
 _callback $w paneDeletedProc $pane

 destroy $pane
 foreach key [array names wid $w,$pane*] {unset Info($key)}
 foreach key [array names d $w,$pane*] {unset Info($key)}
 set n [lsearch $d(panes) $pane]
 set d(panes) [lreplace $d(panes) $n $n]
 if {[llength $d(panes)]==0} {
  $wid(wavebar) configure -state passive
 }

 _showYSB $w
}

# -----------------------------------------------------------------------------
# saveConfiguration

proc wsurf::saveConfiguration {w} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d
 
 set initialdir [lindex $Info(ConfigDir) 0]
 if {[string match macintosh $::tcl_platform(platform)]} {
    set fn [tk_getSaveFile -initialdir $initialdir]
    # Macintosh does not support -defaultextension, try to fix name
    if {![string match -nocase *.conf $fn]} { set fn $fn.conf }
  } else {
   #<< initialdir:$Info(ConfigDir)
    set fn [tk_getSaveFile -initialdir $initialdir \
	-defaultextension .conf \
	-initialfile [file tail $d(configuration)] \
	-filetypes [list {"Configuration" {.conf}} {"All files" {*}}]]
  }
 if {$fn != ""} {

# Ugly Windows-tcl bug workaround, not needed for Tk8.3

  set ext [file extension $fn]
  if {$ext == ".con"} {
   set fn [append fn f]
  }

  if {[catch {open $fn w} out]} {
   error $out
  } else {
   puts $out "# -*-Mode:Tcl-*-"
   puts $out "# This file is automatically generated by WaveSurfer"
   puts $out ""

   # widget options

   foreach opt {-background -foreground -troughcolor -cursorcolor -wavebarheight -pixelspersecond -playmapfilter} {
    set val [$w cget $opt]
    puts $out "\$widget configure $opt \"$val\""
   }

   foreach plug $Info(Plugins) {
    if {$Info(PluginActive,$plug)} {
     if {[info exists Info(Callback,$plug,getConfigurationProc)]} {
      set confspec [string trim [eval $Info(Callback,$plug,getConfigurationProc) $w {""}]]
      if {$confspec!=""} {
       puts $out "if \{\[wsurf::PluginEnabled $plug\]\} \{"
       foreach line [split $confspec \n] {puts $out "    $line"}
       puts $out "\}"
       puts $out ""
      }
     }
    }
   }

   # per-pane options

   puts $out ""
   foreach pane [_getPanes $w] {
    puts $out "set pane \[\$widget addPane -maxheight $d($pane,maxheight) \
      -minheight $d($pane,minheight)]"
    set p $pane
    puts $out [$pane getConfiguration]
    foreach plug $Info(Plugins) {
     if {$Info(PluginActive,$plug)} {
      if {[info exists Info(Callback,$plug,getConfigurationProc)]} {
       set confspec [string trim [eval $Info(Callback,$plug,getConfigurationProc) $w $pane]]
       if {$confspec!=""} {
	puts $out "if \{\[wsurf::PluginEnabled $plug\]\} \{"
	foreach line [split $confspec \n] {puts $out "    $line"}
	puts $out "\}"
	puts $out ""
       }
      }
     }
    }
   }
  }
  if {$Info(Prefs,prefsWithConf)} {
   puts $out "\n\# Optional preferences section\n"
   set confspec [string trim [eval GetPreferences]]
   foreach line [split $confspec \n] {
    puts $out $line
   }
  }
  close $out
 }
}

# -----------------------------------------------------------------------------
# applyConfiguration

proc wsurf::applyConfiguration {w conf} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 if {[info exists d]} {
  foreach pane [_getPanes $w] {
   deletePane $w $pane
  }
  set widget $w
  if {$conf != ""} {
   source $conf
  }
  set d(configuration) $conf
  if {$conf != ""} {
   set cfgtxt "\t\[Configuration: [file root [file tail $conf]]\]"
  } else {
   set cfgtxt ""
  }
  $wid(title) config -text "$d(title)$cfgtxt"
 }
}

# -----------------------------------------------------------------------------
# _propertiesDialog

proc wsurf::_propertiesDialog {w pane} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d
 destroy .props
 toplevel .props
 if {[lsearch $d(panes) $pane] >= 0} {
  set ptitle pane:[lsearch $d(panes) $pane]
 } else {
  set ptitle WaveBar
 }
 wm title .props "[::util::mc Properties:] $d(title) ($ptitle)"
 set Info(PropsDialogWidget) $w

 pack [frame .props.f] -side bottom -fill both -expand true -ipadx 10 -ipady 10
 pack [button .props.f.b1 -text [::util::mc OK] -command \
   [namespace code [list _properties $w $pane]\n[namespace code [list _closePropertiesDialog $w $pane]]] \
   -default active] -side $::ocdir -padx 3 -expand true
 pack [button .props.f.b2 -text [::util::mc Cancel] \
	 -command [namespace code [list _closePropertiesDialog $w $pane]]] \
	 -side $::ocdir -padx 3 -expand true
 pack [button .props.f.b3 -text [::util::mc Apply] \
   -command [namespace code [list _properties $w $pane]]] -side left -padx 3 \
     -expand true

 _drawPropertyPages $w $pane
}

proc wsurf::_drawPropertyPages {w pane} {

 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 destroy .props.nb
 set notebook .props.nb

 if {$pane==""} {
  set pp ""
  # this space is intentionally left blank
 } elseif {[string match $pane $wid(wavebar)]} {
  set pp ""
  lappend pages [::util::mc Wavebar]
  lappend procs _panePropertiesPage
 } else {
  set pp $pane
  lappend pages [::util::mc Pane]
  lappend procs _panePropertiesPage
 }
 foreach {title pageProc} [eval concat [_callback $w propertiesPageProc $pp]] {
  if {$title != ""} {
   lappend pages $title
   lappend procs $pageProc
  }
 }
 lappend pages [::util::mc Sound]
 lappend procs _soundPropertiesPage
 lappend pages [::util::mc Playback]
 lappend procs _playPropertiesPage
 
 if {$::useTile} {
  notebook $notebook -padding 6
 } else {
  Notebook:create $notebook -pages $pages -pad 0
 }
 pack $notebook -fill both -expand yes
 if {[string match macintosh $::tcl_platform(platform)] || \
	 [string match Darwin $::tcl_platform(os)]} {
  update
 }
 foreach page $pages proc $procs {
  if {$::useTile} {
   set lowpage [string tolower $page]
   $notebook add [frame $notebook.$lowpage] -text $page
   $proc $w $pane $notebook.$lowpage
  } else {
   set p [Notebook:frame $notebook $page]
   $proc $w $pane $p
  }
 }
 if {$::useTile} {
  $notebook select $d($pane,lastPropertyPage)
 } else {
  Notebook:raise.page $notebook $d($pane,lastPropertyPage)
 }
    update idletasks 
}

proc wsurf::_remeberPropertyPage {w pane} {
 upvar [namespace current]::${w}::data d
 if {$::useTile} {
 } else {
  set d($pane,lastPropertyPage) [Notebook:current .props.nb]
 }
}

proc wsurf::_closePropertiesDialog {w pane} {
 _remeberPropertyPage $w $pane
 destroy .props
}

proc wsurf::_properties {w pane} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 if {![info exists wid(wavebar)]} return ;# widget has been deleted
 
 if {$pane==""} {
  # this space is intentionally left blank
 } elseif {[string match $pane $wid(wavebar)]} {
  set propList [list background foreground troughcolor cursorColor \
      wavebarheight wavefill pixelspersecond]
  foreach var $propList {
   if {[string compare $d($pane,$var) $d($pane,t,$var)] != 0} {
    set d($pane,$var) $d($pane,t,$var)
    set doConf 1
   }
  }
 } else {
  set propList [list height yzoom cursorColor fillColor \
    frameColor background yaxisColor yaxisFont displayLength]
  foreach var $propList {
   if {[string compare $d($pane,$var) $d($pane,t,$var)] != 0} {
    set d($pane,$var) $d($pane,t,$var)
    set doConf 1
   }
  }
 }

 foreach var [list setRate setEncoding setChannels] {
  if {[string compare $d($var) $d(t,$var)] != 0} {
   set d($var) $d(t,$var)
   _soundConfigure $w $var
  }
 }

 foreach var [list mapFilterStr] {
  if {[string compare $d($var) $d(t,$var)] != 0} {
   set d($var) $d(t,$var)
   _confPlayProps $w $var
  }
 }

 if {[info exists doConf]} {
  foreach prop $propList {
   _paneConfigure $w $pane $prop
  }
 }
 _callback $w applyPropertiesProc $pane
}

proc wsurf::_panePropertiesPage {w pane path} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 if {[string match $pane $wid(wavebar)]} {
  set widget $w
  set d($pane,t,background)      [$widget cget -background]
  set d($pane,t,foreground)      [$widget cget -foreground]
  set d($pane,t,troughcolor)     [$widget cget -troughcolor]
  set d($pane,t,cursorColor)     [$widget cget -cursorcolor]
  set d($pane,t,wavebarheight)   [$widget cget -wavebarheight]
  set d($pane,t,wavefill)        [$widget cget -wavefill]
  set d($pane,t,pixelspersecond) [$widget cget -pixelspersecond]
  set d($pane,background)        $d($pane,t,background)
  set d($pane,foreground)        $d($pane,t,foreground)
  set d($pane,troughcolor)       $d($pane,t,troughcolor)
  set d($pane,cursorColor)       $d($pane,t,cursorColor)
  set d($pane,wavebarheight)     $d($pane,t,wavebarheight)
  set d($pane,wavefill)          $d($pane,t,wavefill)
  set d($pane,pixelspersecond)   $d($pane,t,pixelspersecond)
 } else {
  set widget $pane
  set d($pane,t,height)          [$widget cget -height]
#  set d($pane,t,scrollHeight)    [$widget cget -scrollheight]
#  set d($pane,t,scrolled)        [$widget cget -scrolled]
  set d($pane,t,yzoom)           [expr int(100*[$widget cget -yzoom])]
  set d($pane,t,cursorColor)     [$widget cget -cursorcolor]
  set d($pane,t,fillColor)       [$widget cget -fillcolor]
  set d($pane,t,frameColor)      [$widget cget -framecolor]
  set d($pane,t,background)      [$widget cget -background]
  set d($pane,t,yaxisColor)      [$widget cget -yaxiscolor]
  set d($pane,t,yaxisFont)       [$widget cget -yaxisfont]
  set d($pane,t,displayLength)   [$widget cget -displaylength]
  set d($pane,height)            $d($pane,t,height)
#  set d($pane,scrollHeight)      $d($pane,t,scrollHeight)
#  set d($pane,scrolled)          $d($pane,t,scrolled)
  set d($pane,yzoom)             $d($pane,t,yzoom)
  set d($pane,cursorColor)       $d($pane,t,cursorColor)
  set d($pane,fillColor)         $d($pane,t,fillColor)
  set d($pane,frameColor)        $d($pane,t,frameColor)
  set d($pane,background)        $d($pane,t,background)
  set d($pane,yaxisColor)        $d($pane,t,yaxisColor)
  set d($pane,yaxisFont)         $d($pane,t,yaxisFont)
  set d($pane,displayLength)     $d($pane,t,displayLength)
 }

 foreach f [winfo children $path] {
  destroy $f	
 }
 if {[string match $pane $wid(wavebar)]} {
  colorPropItem $path.f1 "Background color:" 20 \
      [namespace current]::${w}::data($pane,t,background)
  colorPropItem $path.f2 "Foreground color:" 20 \
      [namespace current]::${w}::data($pane,t,foreground)
  colorPropItem $path.f3 "Trough color:" 20 \
      [namespace current]::${w}::data($pane,t,troughcolor)
  colorPropItem $path.f4 "Cursor color:" 20 \
      [namespace current]::${w}::data($pane,t,cursorColor)
  stringPropItem $path.f5 "Height:" 20 10 "pixels" \
      [namespace current]::${w}::data($pane,t,wavebarheight)
  stringPropItem $path.f6 "Time scale:" 20 10 "pixels/second" \
      [namespace current]::${w}::data($pane,t,pixelspersecond)
#  pack [entry $path.f6.e2 -width 5] -side left
#  pack [label $path.f6.l3 -text "mm/s"] -side left
 } else {
  colorPropItem $path.f1 "Selection color:" 20 \
      [namespace current]::${w}::data($pane,t,fillColor)
  colorPropItem $path.f2 "Selection frame color:" 20 \
      [namespace current]::${w}::data($pane,t,frameColor)
  colorPropItem $path.f3 "Y-axis color:" 20 \
      [namespace current]::${w}::data($pane,t,yaxisColor)
  stringPropItem $path.f4 "Y-axis font:" 20 10 "" \
      [namespace current]::${w}::data($pane,t,yaxisFont)
  colorPropItem $path.f5 "Background color:" 20 \
      [namespace current]::${w}::data($pane,t,background)
  colorPropItem $path.f6 "Cursor color:" 20 \
      [namespace current]::${w}::data($pane,t,cursorColor)
  stringPropItem $path.f7 "Pane height:" 20 10 pixels \
      [namespace current]::${w}::data($pane,t,height)
#  booleanPropItem $path.f8 "Pane scrolled" \
#      [namespace code [list _scrolledConfigure $w $pane $path.f9.entry]] \
#      [namespace current]::${w}::data($pane,t,scrolled)
#  stringPropItem $path.f9 "Pane scroll height:" 20 10 pixels \
#      [namespace current]::${w}::data($pane,t,scrollHeight)
#  if {$d($pane,t,scrolled)} {
#   $path.f9.entry configure -state normal
#  } else {
#   $path.f9.entry configure -state disabled
#  }
#  stringPropItem $path.f9 "Y zoom:" 20 10 % \
#      [namespace current]::${w}::data($pane,t,yzoom)

  set p $path.f9
  pack [frame $p] -anchor w -ipady 2
  label $p.label -text [::util::mc "Vertical zoom factor:"] -width 20 -anchor w
  if {$::useTile} {
   combobox $p.combobox -textvariable [namespace current]::${w}::data($pane,t,yzoom) -width 10 -values {100 150 200 500 1000}
  } else {
   combobox::combobox $p.combobox -textvariable [namespace current]::${w}::data($pane,t,yzoom) -width 10 -editable 1
   $p.combobox list insert 0 100 150 200 500 1000
  }
  label $p.l2 -text [::util::mc %] -anchor w
  pack $p.label $p.combobox $p.l2 -side left -padx 3
  booleanPropItem $path.f10 "Display selection length" "" \
      [namespace current]::${w}::data($pane,t,displayLength)
 }
}

proc colorPropItem {path label width var} {
  upvar $var v
  pack [frame $path] -anchor w -ipady 2
  label $path.label -text [::util::mc $label] -width $width -anchor w
  entry $path.entry -textvar $var -width 10
  if {$::useTile} {
   tk_label $path.l2 -text "    " -bg $v
  } else {
   label $path.l2 -text "    " -bg $v
  }
  button $path.button -text [::util::mc Choose...] \
      -command [list util::chooseColor $var $path.l2]
  pack $path.label $path.entry $path.l2 $path.button -side left -padx 3
}

proc stringPropItem {path label labelWidth entryWidth unit var} {
  pack [frame $path] -anchor w -ipady 2
  label $path.label -text [::util::mc $label] -width $labelWidth -anchor w
  entry $path.entry -textvar $var -width $entryWidth
  label $path.l2 -text [::util::mc $unit] -anchor w
  pack $path.label $path.entry $path.l2 -side left -padx 3
}

proc filenamePropItem {path label labelWidth entryWidth browsetext dialogcmd var} {
  pack [frame $path] -anchor w -ipady 2
  label $path.label -text [::util::mc $label] -width $labelWidth -anchor w
  entry $path.entry -textvar $var -width $entryWidth
  button $path.b -text $browsetext -command [namespace code "set $var \[$dialogcmd\]"]
  pack $path.label $path.entry $path.b -side left -padx 3
}

proc booleanPropItem {path label command var} {
  upvar $var v
  pack [frame $path] -anchor w -ipady 2
 if {$::useTile} {
  pack [tk_checkbutton $path.b -text [::util::mc $label] -anchor w \
	    -variable $var -command $command]
 } else {
  pack [checkbutton $path.b -text [::util::mc $label] -anchor w \
	    -variable $var -command $command]
 }
  pack $path.b -side left -padx 3
}

proc wsurf::_scrolledConfigure {w pane entry} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 if {$d($pane,t,scrolled)} {
  $entry configure -state normal
 } else {
  $entry configure -state disabled
 }
 _paneConfigure $w $pane scrolled
}

proc wsurf::_paneConfigure {w pane property} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 if {[string match $pane $wid(wavebar)]} {
  set widget $w
 } else {
  set widget $pane
 }
 switch $property {
  cursorColor {
   $widget configure -cursorcolor $d($pane,cursorColor)
  }
  fillColor {
   $widget configure -fillcolor $d($pane,fillColor)
  }
  frameColor {
   $widget configure -framecolor $d($pane,frameColor)
  }
  wavefill {
#   $widget configure -wavefill $d($pane,wavefill)
  }
  selectfill {
   $widget configure -selectfill $d($pane,fillColor)
  }
  background { 
   $widget configure -background $d($pane,background)
  }
  height {
    $widget configure -height $d($pane,height)
  }
  wavebarheight {
    $widget configure -wavebarheight $d($pane,wavebarheight)
  }
  scrollHeight {
   $widget configure -scrollheight $d($pane,scrollHeight)
  }
  yzoom {
   $widget configure -yzoom [expr {.01*$d($pane,yzoom)}]
  }
  pixelspersecond {
   $widget configure -pixelspersecond $d($pane,pixelspersecond)
  }
  yaxisColor {
   $widget configure -yaxiscolor $d($pane,yaxisColor)
  }
  yaxisFont {
   $widget configure -yaxisfont $d($pane,yaxisFont)
  }
  scrolled {
   $widget configure -scrolled $d($pane,scrolled)
  }
  displayLength {
   $widget configure -displaylength $d($pane,displayLength)
  }
  foreground {
   $widget configure -foreground $d($pane,foreground)
  }
  troughcolor { 
   $widget configure -troughcolor $d($pane,troughcolor)
  }
  default {
   error "no such property \"$property\""
  }
 }
}

proc wsurf::clearMessages {w} {
 upvar [namespace current]::${w}::data d
 array unset d msg,*
 # hide cursor line when mouse pointer leaves pane
 foreach pane [_getPanes $w] {
  set c [$pane canvas]
  $c coords cursor -1 -1 -1 -1
 }
}

proc wsurf::showInfo {w} {
 upvar [namespace current]::${w}::data d
 array unset d msg,*
 set info "File: $d(fileName),"
 set s [$w cget -sound] 
 append info " rate: [$s cget -rate],"
 append info " encoding: [$s cget -encoding],"
 append info " channels: [$s cget -channels],"
 set tse [$s length -unit sec]
 append info " length: [util::formatTime $tse $tse %.3f] (hms.d)"
 messageProc $w $info wsurf
}

proc wsurf::_soundPropertiesPage {w pane path} {
 variable Info
 upvar [namespace current]::${w}::data d

 set s [$w cget -sound]
 set d(t,setRate)      [$s cget -rate]
 set d(t,setEncoding)  [$s cget -encoding]
 set d(t,setChannels)  [$s cget -channels]
 set d(setRate)        $d(t,setRate)
 set d(setEncoding)    $d(t,setEncoding)
 set d(setChannels)    $d(t,setChannels)

 foreach f [winfo children $path] {
  destroy $f
 }

 set fn $d(fileName)
 if {[string length $fn] > 30} {
   set fn ...[string range $fn [expr {[string length $fn]-30}] end]
 }

 if {$::useTile} {
  pack [labelframe $path.tf -text [::util::mc "Sound file properties"] \
	    -padding 6] -fill both -padx 6 -pady 6
  set text [::util::mc "Filename:"]
  append text " $fn"
  pack [label $path.tf.l1 -text $text] -anchor w
 } else {
  pack [frame $path.tf] -anchor w
  pack [label $path.tf.l1 -text "Sound file properties for $fn"] \
      -anchor w
 }

 set text [::util::mc "Sound file format:"]
 append text " [lindex [$s info] 6]"
 pack [label $path.tf.l2 -text $text] -anchor w

 set text [::util::mc "Sample rate:"]
 append text "  $d(t,setRate)"
 pack [label $path.tf.l3 -text $text] -anchor w

 set text [::util::mc "Number of channels:"]
 append text " $d(t,setChannels)"
 pack [label $path.tf.l4 -text $text] \
     -anchor w
 set text [::util::mc "Sample format encoding:"]
 append text " $d(t,setEncoding)"
 pack [label $path.tf.l5 -text $text] -anchor w
 set tse [$s length -unit sec]
 set tsa [$s length -unit samples]
 set text [::util::mc "Sound length:"]
 append text " [util::formatTime $tse $tse %.3f] (hms.d), $tsa (samples)"
 pack [label $path.tf.l6 -text $text] -anchor w
 if {$d(fileName) != ""} {
   set kb [expr [file size $d(fileName)] / 1024]
   set date [clock format [file mtime $d(fileName)]]
 } else {
   set kb 0
   set date ""
 }
 set text [::util::mc "File size:"]
 append text " $kb (Kb)"
 pack [label $path.tf.l7 -text $text] -anchor w
 set text [::util::mc "File date:"]
 append text " $date"
 pack [label $path.tf.l8 -text $text] -anchor w
 if {[string match *MP3* [$s info]]} {
   pack [label $path.tf.lmp3 \
       -text "MPEG layer 3 bitrate: [$s config -bitrate]"] \
       -anchor w
 }
 set n 10
 foreach desc [_callback $w soundDescriptionProc $pane] {
   foreach line $desc {
     pack [label $path.tf.l$n -text $line] -anchor w
     incr n
   }
 }

 set rateList [snack::audio rates]
 if {$rateList == ""} {
  set rateList {11025 22050 44100}
 }

 if {$::useTile} {
  pack [labelframe $path.bf -text [::util::mc "Change sound properties"] \
	    -padding 6] -fill both -padx 6 -pady 6
 } else {
  pack [frame $path.f0 -bd 1 -width 400 -relief ridge] -anchor w -fill x
  pack [canvas $path.f0.l -height 0] -fill x -expand true
  pack [frame $path.bf] -anchor w
 }
 pack [frame $path.bf.f1] -anchor w -ipady 2
 label $path.bf.f1.l -text [::util::mc "Set sample rate:"] -width 26 -anchor w

 if {$::useTile} {
  combobox $path.bf.f1.cb -values $rateList -width 7 \
      -textvariable [namespace current]::${w}::data(t,setRate)
 } else {
  combobox::combobox $path.bf.f1.cb \
      -textvariable [namespace current]::${w}::data(t,setRate) \
      -width 5 -editable 1
  eval $path.bf.f1.cb list insert end $rateList
 }
 pack $path.bf.f1.l $path.bf.f1.cb -side left

 pack [frame $path.bf.f3] -anchor w -ipady 2
 label $path.bf.f3.l -text [::util::mc "Set sample encoding:"] -width 26 \
     -anchor w
 tk_optionMenu $path.bf.f3.om [namespace current]::${w}::data(t,setEncoding) \
	 Lin16 Mulaw Alaw Lin8offset Lin8 Lin24 Lin24packed Lin32 Float
 pack $path.bf.f3.l $path.bf.f3.om -side left

 pack [frame $path.bf.f5] -anchor w -ipady 2
 label $path.bf.f5.l -text [::util::mc "Set number of channels:"] \
     -width 26 -anchor w
 entry $path.bf.f5.e -textvar [namespace current]::${w}::data(t,setChannels) -wi 6
 pack $path.bf.f5.l $path.bf.f5.e -side left
}

proc wsurf::_confPlayProps {w pane} {
 upvar [namespace current]::${w}::data d

 if {$d(mapFilter) != ""} {
  eval $d(mapFilter) configure $d(mapFilterStr)
 } else {
  set d(mapFilter) [eval snack::filter map $d(mapFilterStr)]
 }
}

proc wsurf::_buildMapStr {w pane} {
 upvar [namespace current]::${w}::data d

 set s [$w cget -sound]
 if {[$s cget -channels] > 1} {
  foreach c {Left Right} {
   for {set i 0} {$i < [$s cget -channels]} {incr i} {
    append str "$d(play,$c,$i) "
   }
  }
  set d(t,mapFilterStr) $str
 }
}

proc wsurf::_playPropertiesPage {w pane path} {
 variable Info
 upvar [namespace current]::${w}::data d

 set d(t,mapFilterStr) $d(mapFilterStr)

 foreach f [winfo children $path] {
  destroy $f
 }

 pack [frame $path.f0] -anchor w
 pack [label $path.f0.l -text [::util::mc "Channel mapping:"] -anchor w]

 set s [$w cget -sound]
 if {[$s cget -channels] == 1} {
  pack [frame $path.f1] -anchor w
  pack [label $path.f1.l -text [::util::mc "None (single channel sound)"] -anchor w]
 } else {
  if {$d(mapFilterStr) == 1} {
   foreach c {Left Right} {
    for {set i 0} {$i < [$s cget -channels]} {incr i} {
     set d(play,$c,$i) 0.0
    }
   }
   set d(play,Left,0)  1.0
   set d(play,Right,1) 1.0
  }
  foreach c {Left Right} {
   pack [frame $path.f$c] -anchor w
   pack [label $path.f$c.l -text "[::util::mc $c] [::util::mc "out:"]" -anchor w -width 12] -side left
   for {set i 0} {$i < [$s cget -channels]} {incr i} {
    if {$i == 0} {
     set label L
    } elseif {$i == 1} {
     set label R
    } else {
     set label [expr $i + 1]
    }
    if {$::useTile} {
     pack [tk_scale $path.f$c.s$i -from 0.0 -to 1.0 -showvalue yes \
	       -variable [namespace current]::${w}::data(play,$c,$i) -length 70 \
	       -command [namespace code [list _buildMapStr $w]] \
	      ] -side left
     $path.f$c.s$i set $d(play,$c,$i)
    } else {
     pack [scale $path.f$c.s$i -label $label -from 1.0 -to 0.0 -resolution .01 \
	       -variable [namespace current]::${w}::data(play,$c,$i) -length 70 \
	       -command [namespace code [list _buildMapStr $w]] \
	      ] -side left
    }
   }
  }
  pack [label $path.l -text [::util::mc "Input channel"]] \
	  -anchor n
 }
}

proc wsurf::_soundConfigure {w property} {
 upvar [namespace current]::${w}::data d

 set s [$w cget -sound]
 switch $property {
  setRate {
   $s configure -rate $d(setRate)
  }
  setEncoding {
   $s configure -encoding $d(setEncoding)
  }
  setChannels {
   $s configure -channels $d(setChannels)
  }
  byteOrder {
   $s configure -byteorder $d(byteOrder)
  }
 }
}

# -----------------------------------------------------------------------------

proc wsurf::GetPreferences {} {
    variable Info
    
    set result {}
    
    foreach item [list outDev inDev PrintCmd PrintPVCmd recordLimit linkFile \
		      autoScroll maxPixelsPerSecond tmpDir icons popupEvent defaultConfig \
		      timeFormat showLevel defRate defEncoding defChannels createWidgets \
		      rawFormats prefsWithConf yaxisWidth theme beg play playall playloop pause \
		      stop record close end print zoomin zoomout zoomall zoomsel] {
	if [info exists Info(Prefs,$item)] {
	    append result "set wsurf::Info(Prefs,$item) \{$Info(Prefs,$item)\}" "\n"
	}
    }
    if [info exists Info(Prefs,theme)] {
	append result "\nwsurf::setTheme \{$Info(Prefs,theme)\}\n"
    }
    append result "wsurf::_selectOutDevice dummy \{$Info(Prefs,outDev)\}\n"
    append result "wsurf::_selectInDevice dummy \{$Info(Prefs,inDev)\}\n\n"
    
    foreach plugin [GetRegisteredPlugins] {
	append result "set wsurf::Info(PluginActive,$plugin) $Info(PluginActive,$plugin)" "\n"
    }
    foreach proc $Info(PrefsGetProcList) {
	append result [eval $proc]
    }
    
    return $result
}

# -----------------------------------------------------------------------------

proc wsurf::ApplyPreferences {} {
    variable Info
    
    foreach var [list outDev inDev PrintCmd PrintPVCmd recordLimit linkFile \
		     autoScroll maxPixelsPerSecond tmpDir icons popupEvent defaultConfig \
		     timeFormat showLevel defRate defEncoding defChannels createWidgets \
		     rawFormats prefsWithConf yaxisWidth theme beg play playall playloop pause \
		     stop record close end print zoomin zoomout zoomall zoomsel] {
	if [info exists Info(Prefs,$var)] {
	    if {[string compare $Info(Prefs,$var) $Info(Prefs,t,$var)] != 0} {
		switch $var {
		    popupEvent {
			AddEvent PopupEvent $Info(Prefs,t,$var)
		    }
		    inDev {
			_selectInDevice dummy $Info(Prefs,t,$var)
		    }
		    outDev {
			_selectOutDevice dummy $Info(Prefs,t,$var)
		    }
		    theme {
			setTheme $Info(Prefs,t,$var)
		    }
		}
		
		set Info(Prefs,$var) $Info(Prefs,t,$var)
	    }
	}
    }
    foreach proc $Info(PrefsApplyProcList) {
	eval $proc
    }
}

proc wsurf::PreferencePages {} {
  variable Info

 concat [list [::util::mc "Raw files"] [namespace code _rawFiles] \
	     [::util::mc "Misc"] [namespace code _miscPage] \
	     [::util::mc "Sound I/O"] [namespace code _soundPage]] \
      $Info(PrefsPageProcList)
}

proc wsurf::AddPreferencePage {title pageProc applyProc getProc defProc} {
  variable Info

  lappend Info(PrefsPageProcList)    $title $pageProc
  lappend Info(PrefsApplyProcList)   $applyProc
  lappend Info(PrefsGetProcList)     $getProc
  lappend Info(PrefsDefaultProcList) $defProc
}

proc wsurf::_miscPage {p} {
 variable Info
 
 foreach f [winfo children $p] {
  destroy $f	
 }

 foreach var [list  autoScroll maxPixelsPerSecond icons popupEvent \
		  defaultConfig createWidgets \
		  timeFormat yaxisWidth prefsWithConf theme beg play playall \
		  playloop pause \
		  stop record close end print zoomin zoomout zoomall zoomsel] {
     if [info exists Info(Prefs,$var)] {
	 set Info(Prefs,t,$var) $Info(Prefs,$var)
     }
 }
 
 set wid 26

 array set opCol [list beg black play black playall blue \
		      pause black stop black end black record red]
 array set imOp  [list zoomin zoomin zoomout zoomout \
		      zoomall zoomall zoomsel zoomsel \
		      print printDialog close closeWidget playloop playloop \
		      play play playall playall beg beg end end stop stop pause pause \
		      record record]
 array set iconType [list beg image play image playall image \
			 playloop image pause image stop image end image \
			 record image print image close image \
			 zoomin image zoomout image\
			 zoomall image zoomsel image]
 array set iconName [list beg snackPlayPrev play snackPlay playall snackPlay \
			 pause snackPause stop snackStop end snackPlayNext \
			 record snackRecord]
 pack [frame $p.f1] -anchor w -ipady 2
 if {$::useTile} {
  pack [tk_label $p.f1.l -text [::util::mc "Icons:"] -anchor w -width 20] \
      -side left
 } else {
  pack [label $p.f1.l -text [::util::mc "Icons:"] -anchor w -width 20] \
      -side left
 }
 list {
 foreach icon [list beg play playall playloop pause stop end record \
		   print close] {
  if {[lsearch $Info(Prefs,t,icons) $icon] == -1} {
   set relief raised
  } else {
   set relief sunken
  }
  if {[string match bitmap $iconType($icon)]} {
   pack [button $p.f1.${icon}button -bitmap $iconName($icon) \
    -fg $opCol($icon) \
    -highlightthickness 0 -bd 1 -relief $relief \
    -command [namespace code [list _iconButton $p.f1.${icon}button $icon]] \
    ] -side left
  } else {
   set op $imOp($icon)
   if {$::useTile} {
    pack [button $p.f1.${op}button -image $Info(Img,$icon) \
	      -padding 0 -borderwidth 1 -relief $relief \
	      -command [namespace code [list _iconButton $p.f1.${op}button $icon]] \
	     ] -side left
   } else {
    pack [button $p.f1.${op}button -image $Info(Img,$icon) \
	      -highlightthickness 0 -bd 1 -relief $relief \
	      -command [namespace code [list _iconButton $p.f1.${op}button $icon]] \
	     ] -side left
   }
  }
 }
 }
 foreach icon [list beg play playall playloop pause stop end record \
		   print close] {
  set op $imOp($icon)
  pack [frame $p.f1.${op}] -side left
  pack [label $p.f1.${op}.label -image $Info(Img,$icon)]
  pack [checkbutton $p.f1.${op}.button \
	    -variable [namespace current]::Info(Prefs,t,$icon)]
 }

 pack [frame $p.f2] -anchor w -ipady 2
 label $p.f2.l -text [::util::mc "Popup-menu event:"] -anchor w -width $wid
 entry $p.f2.e -textvar [namespace current]::Info(Prefs,t,popupEvent) -wi 20
 pack $p.f2.l $p.f2.e -side left

# Does not belong here, move to application layer (with lots of the other)
 pack [frame $p.f3] -anchor w
 label $p.f3.l -text [::util::mc "Open new sound in"] -anchor w -width $wid
 tk_optionMenu $p.f3.om [namespace current]::Info(Prefs,t,createWidgets) \
     separate common
 label $p.f3.l2 -text "window" -anchor w
 pack $p.f3.l $p.f3.om $p.f3.l2 -side left

 pack [frame $p.f4] -anchor w -ipady 2
 label $p.f4.l -text [::util::mc "Max zoom-in:"] -anchor w -width $wid
 entry $p.f4.e \
     -textvar [namespace current]::Info(Prefs,t,maxPixelsPerSecond) -wi 8
 label $p.f4.l2 -text [::util::mc "pixels/second"] -anchor w -width $wid
 pack $p.f4.l $p.f4.e $p.f4.l2 -side left

 pack [frame $p.f5] -anchor w -ipady 2
 label $p.f5.l -text "Scroll type during playback:" -width 26 -anchor w
 tk_optionMenu $p.f5.om [namespace current]::Info(Prefs,t,autoScroll) \
     None Scroll Page
 pack $p.f5.l $p.f5.om -side left

# Does not belong here, move to application layer (with lots of the other)
 pack [frame $p.f6] -anchor w -ipady 2
 label $p.f6.l -text [::util::mc "Use configuration:"] -width 26 \
     -anchor w
 set tmp [list "Show dialog"]
 foreach conf [::wsurf::GetConfigurations] {
  lappend tmp [file rootname [file tail $conf]]
 }
 eval tk_optionMenu $p.f6.om \
     [namespace current]::Info(Prefs,t,defaultConfig) $tmp
 pack $p.f6.l $p.f6.om -side left


 pack [frame $p.f7] -anchor w -ipady 2
 label $p.f7.l -text [::util::mc "Time display format:"] -width 26 \
     -anchor w
 tk_optionMenu $p.f7.om [namespace current]::Info(Prefs,t,timeFormat) \
	 hms hms.d hms.dd hms.ddd hms.dddd hms.ddddd hms.dddddd samples seconds "10ms frames" "PAL frames" "NTSC frames"
 pack $p.f7.l $p.f7.om -side left

 pack [frame $p.f8] -anchor w -ipady 2
 label $p.f8.l -text [::util::mc "Y-axis width:"] -anchor w -width $wid
 entry $p.f8.e \
     -textvar [namespace current]::Info(Prefs,t,yaxisWidth) -wi 8
 label $p.f8.l2 -text [::util::mc "pixels"] -anchor w -width $wid
 pack $p.f8.l $p.f8.e $p.f8.l2 -side left


 pack [frame $p.f9] -anchor w -ipady 2
 if {$::useTile} {
  tk_checkbutton $p.f9.b -text [::util::mc "Save copy of preferences in configuration file"] \
      -anchor w  -variable [namespace current]::Info(Prefs,t,prefsWithConf)
 } else {
  checkbutton $p.f9.b -text [::util::mc "Save copy of preferences in configuration file"] \
      -anchor w  -variable [namespace current]::Info(Prefs,t,prefsWithConf)
 }
 pack $p.f9.b -side left

 if {$::useTile} {
  pack [frame $p.f10] -anchor w -ipady 2
  label $p.f10.l -text [::util::mc "Skin:"] -width $wid -anchor w
  eval tk_optionMenu $p.f10.om [namespace current]::Info(Prefs,t,theme) $Info(Themes)
  pack $p.f10.l $p.f10.om -side left
 }

}

proc wsurf::_soundPage {p} {
 variable Info

 foreach f [winfo children $p] {
  destroy $f	
 }

 foreach var [list inDev outDev PrintCmd PrintPVCmd linkFile tmpDir \
		  defRate defEncoding defChannels recordLimit showLevel] {
  set Info(Prefs,t,$var) $Info(Prefs,$var)
 }
 
 if {$Info(Prefs,linkFile)} {
  set Info(Prefs,t,storage) "keep on disk"
 } else {
  set Info(Prefs,t,storage) "load into memory"
 }

 set wid [::util::mcmax "Input device:" "Output device:" "Print command:" \
           "Preview command:" "Sound storage:" "Temporary directory:" \
	   "New sound default rate:" "New sound default encoding:" \
            "New sound default channels:" "Record time limit:"]

 pack [frame $p.f1] -anchor w -ipady 2
 label $p.f1.l -text [::util::mc "Input device:"] -width $wid -anchor w

 set inDevList [snack::audio inputDevices]
 if {$::useTile} {
  combobox $p.f1.cb -textvariable [namespace current]::Info(Prefs,t,inDev) -width 30 -values $inDevList
 } else {
  combobox::combobox $p.f1.cb -textvariable [namespace current]::Info(Prefs,t,inDev) -width 30 -editable 1
  eval $p.f1.cb list insert end $inDevList
 }
 pack $p.f1.l $p.f1.cb -side left

 pack [frame $p.f2] -anchor w -ipady 2
 label $p.f2.l -text [::util::mc "Output device:"] -width $wid -anchor w
 set outDevList [snack::audio outputDevices]
 if {$::useTile} {
  combobox $p.f2.cb -textvariable [namespace current]::Info(Prefs,t,outDev) -width 30 -values $outDevList
 } else {
  combobox::combobox $p.f2.cb -textvariable [namespace current]::Info(Prefs,t,outDev) -width 30 -editable 1
  eval $p.f2.cb list insert end $outDevList
 }
 pack $p.f2.l $p.f2.cb -side left

 pack [frame $p.f3] -anchor w -ipady 2
 label $p.f3.l -text [::util::mc "Print command:"] -anchor w -width $wid
 entry $p.f3.e -textvar [namespace current]::Info(Prefs,t,PrintCmd) -wi 40
 pack $p.f3.l $p.f3.e -side left

 pack [frame $p.f4] -anchor w -ipady 2
 label $p.f4.l -text [::util::mc "Preview command:"] -anchor w -width $wid
 entry $p.f4.e -textvar [namespace current]::Info(Prefs,t,PrintPVCmd) -wi 40
 pack $p.f4.l $p.f4.e -side left

 pack [frame $p.f5] -anchor w -ipady 2
 label $p.f5.l -text [::util::mc "Sound storage:"] -width $wid -anchor nw

 tk_optionMenu $p.f5.om [namespace current]::Info(Prefs,t,storage) \
	 "load into memory" "keep on disk"

 $p.f5.om.menu entryconfigure 0 \
   -command "set [namespace current]::Info(Prefs,t,linkFile) 0"
 $p.f5.om.menu entryconfigure 1 \
   -command "set [namespace current]::Info(Prefs,t,linkFile) 1"
 pack $p.f5.l $p.f5.om -side left -anchor nw

 pack [frame $p.f6] -anchor w -ipady 2
 label $p.f6.l -text [::util::mc "Temporary directory:"] -anchor w -width $wid
 entry $p.f6.e -textvar [namespace current]::Info(Prefs,t,tmpDir) -wi 40
 pack $p.f6.l $p.f6.e -side left

# stringPropItem $p.f41 "Temporary directory:" $wid 40 "" \
      [namespace current]::Info(Prefs,t,tmpDir)

 set rateList [snack::audio rates]
 if {$rateList == ""} {
  set rateList {11025 22050 44100}
 }
 pack [frame $p.f7] -anchor w -ipady 2
 label $p.f7.l -text [::util::mc "New sound default rate:"] -anchor w \
  -width $wid
 if {$::useTile} {
  combobox $p.f7.cb -textvariable [namespace current]::Info(Prefs,t,defRate) -width 7 -values $rateList
 } else {
  combobox::combobox $p.f7.cb -textvariable [namespace current]::Info(Prefs,t,defRate) -width 5 -editable 1
  eval $p.f7.cb list insert end $rateList
 }
 pack $p.f7.l $p.f7.cb -side left

 pack [frame $p.f71] -anchor w -ipady 2
 label $p.f71.l -text [::util::mc "New sound default encoding:"] -anchor w \
  -width $wid
 tk_optionMenu $p.f71.om [namespace current]::Info(Prefs,t,defEncoding) \
	 Lin16 Mulaw Alaw Lin8offset Lin8 Lin24 Lin24packed Lin32 Float
 pack $p.f71.l $p.f71.om -side left

 pack [frame $p.f72] -anchor w -ipady 2
 label $p.f72.l -text [::util::mc "New sound default channels:"] -anchor w \
  -width $wid
 entry $p.f72.e -textvar [namespace current]::Info(Prefs,t,defChannels) -wi 2
 pack $p.f72.l $p.f72.e -side left

 pack [frame $p.f8] -anchor w -ipady 2
 label $p.f8.l -text [::util::mc "Record time limit:"] -anchor w -width $wid
 entry $p.f8.e -textvar [namespace current]::Info(Prefs,t,recordLimit) -wi 6
 label $p.f8.l2 -text "s" -anchor w
 pack $p.f8.l $p.f8.e $p.f8.l2 -side left

 pack [frame $p.f9] -anchor w -ipady 2
 if {$::useTile} {
  tk_checkbutton $p.f9.b -text [::util::mc "Show level meter"] \
     -anchor w  -variable [namespace current]::Info(Prefs,t,showLevel)
 } else {
  checkbutton $p.f9.b -text [::util::mc "Show level meter"] \
     -anchor w  -variable [namespace current]::Info(Prefs,t,showLevel)
 }
 pack $p.f9.b -side left
}

proc wsurf::setTheme {theme} {
 variable Info
 
 if {$::useTile} {
  set i [lsearch -exact $Info(Themes) $theme]
  #  puts $Info(Prefs,theme),[lindex $Info(themes) $i]
  if {$i >= 0} {
      ttk::style theme use [lindex $Info(themes) $i]
  }
 }
}

proc wsurf::_rawFiles {p} {
 variable Info

 foreach f [winfo children $p] {
  destroy $f	
 }

 foreach var [list rawFormats] {
  set Info(Prefs,t,$var) $Info(Prefs,$var)
 }

 grid [label $p.l -text [::util::mc "Defined file extension types:"]] \
     -sticky nw
 grid [frame $p.f1] -sticky news
 listbox $p.f1.lb -width 60 -height 18 -selectmode single \
   -yscrollcommand [list $p.f1.sb set]
 scrollbar $p.f1.sb -orient vert -command [list $p.f1.lb yview]
 pack $p.f1.sb -side right -fill y
 pack $p.f1.lb -side right -expand 1 -fill both

 foreach {ext rate enc chan bo skip} $Info(Prefs,rawFormats) {
  $p.f1.lb insert end "$ext : $rate $enc $chan $bo $skip"
 }

 grid [frame $p.f2] -sticky we
 if {$::useTile} {
  pack [tk_button $p.f2.b -text [::util::mc Delete] -anchor w \
	    -command [namespace code [list _deleteRawFileDef $p]]] -padx 3 -pady 3
 } else {
  pack [button $p.f2.b -text [::util::mc Delete] -anchor w \
	    -command [namespace code [list _deleteRawFileDef $p]]] -padx 3 -pady 3
 }

 grid columnconfigure $p 0 -weight 1
}

proc wsurf::_iconButton {b name} {
 variable Info

 set index [lsearch $Info(Prefs,t,icons) $name] 
 if {$index == -1} {
  $b configure -relief sunken
  lappend Info(Prefs,t,icons) $name
 } else {
  $b configure -relief raised
  set Info(Prefs,t,icons) [lreplace $Info(Prefs,t,icons) $index $index]
 }
}

proc wsurf::_selectOutDevice {dummy dev} {
 variable Info
 # snack::audio selectOutput $dev
 if {[snack::audio outputDevices] == {}} { return }
 if {[lsearch [snack::audio outputDevices] $dev] != -1} {
 } else {
  set Info(Prefs,outDev) [lindex [snack::audio outputDevices] 0]
  set dev [lindex [snack::audio outputDevices] 0]
 }
 snack::audio selectOutput $dev
}

proc wsurf::_selectInDevice {dummy dev} {
 variable Info
 # snack::audio selectInput $dev
 if {[snack::audio inputDevices] == {}} { return }
 if {[lsearch [snack::audio inputDevices] $dev] != -1} {
 } else {
  set Info(Prefs,inDev) [lindex [snack::audio inputDevices] 0]
  set dev [lindex [snack::audio inputDevices] 0]
 }
  snack::audio selectInput $dev
}

# -----------------------------------------------------------------------------

proc wsurf::pluginsDialog {} {
 variable Info

 set p .plugins

 if [winfo exists $p] {
  foreach child [winfo children $p] {destroy $child}
 } else {
  toplevel $p
 }
 wm title $p "Plug-ins:"

 pack [frame $p.f] -expand true -fill both

 grid [label $p.f.l -text [::util::mc "Installed plug-ins:"]] -sticky nw ;#row 0
 grid [frame $p.f.f1] -sticky news                          ;#row 1
 listbox $p.f.f1.lb -height 5 -selectmode single \
   -yscrollcommand [list $p.f.f1.sb set]
 scrollbar $p.f.f1.sb -orient vert -command [list $p.f.f1.lb yview]
 pack $p.f.f1.sb -side right -fill y
 pack $p.f.f1.lb -side right -expand 1 -fill both

 grid [label $p.f.l2 -text [::util::mc "Plug-ins available for installation:"]] \
   -sticky nw;#row 0
 grid [frame $p.f.f2] -sticky news                          ;#row 1
 listbox $p.f.f2.lb -height 5 -selectmode single \
   -yscrollcommand [list $p.f.f2.sb set]
 scrollbar $p.f.f2.sb -orient vert -command [list $p.f.f2.lb yview]
 pack $p.f.f2.sb -side right -fill y
 pack $p.f.f2.lb -side right -expand 1 -fill both
 grid [frame $p.f.f22] -sticky news 
 grid [button $p.f.f22.b -text Install \
   -command [namespace code [list _install $p]]]

 grid [label $p.f.l3 -text [::util::mc "Description:"]] -sticky nw       ;#row 2
 grid [frame $p.f.f3] -sticky news                          ;#row 3
 text $p.f.f3.t -height 5 -yscrollcommand [list $p.f.f3.sb set] -wrap word \
   -font "helvetica 10"
 scrollbar $p.f.f3.sb -orient vert -command [list $p.f.f3.t yview]
 pack $p.f.f3.sb -side right -fill y
 pack $p.f.f3.t -side right -expand 1 -fill both
 grid [frame $p.f.f4] -sticky we                            ;#row 3
 pack [label $p.f.f4.l -text [::util::mc "URL:"]] -side left
 pack [button $p.f.f4.b -text "" -relief flat -anchor w \
   -font "helvetica 10 underline"] -side left -expand 1 -fill x
 grid [frame $p.f.f5] -sticky we                            ;#row 3
 pack [label $p.f.f5.l1 -text [::util::mc "Location:"]] -side left
 pack [label $p.f.f5.l2 -text "" -relief flat -anchor w \
   -font "helvetica 10"] -side left -expand 1 -fill x

 foreach plugin [lsort $Info(Plugins)] {
  $p.f.f1.lb insert end $plugin
 }
 bind $p.f.f1.lb <<ListboxSelect>> \
   [namespace code [list _pluginSelect $p $p.f.f1.lb]]
 
 bind $p.f.f1.lb <Double-Button-1> \
   [namespace code [list _pluginReload $p]]

 $p.f.f2.lb insert end \
   "Looking for plugins at http://www.speech.kth.se/wavesurfer/"
 package require http
 #::http::geturl http://www.speech.kth.se/wavesurfer/download_tcl -command [namespace code [list _showAvailablePlugins $p]]

 bind $p.f.f2.lb <<ListboxSelect>> \
   [namespace code [list _pluginSelect $p $p.f.f2.lb]]

 grid rowconfigure $p.f 1 -weight 1
 grid rowconfigure $p.f 3 -weight 1
 grid columnconfigure $p.f 0 -weight 1
}

proc wsurf::_showAvailablePlugins {p token} {
 variable Info
 
 if {[string match *200* [::http::code $token]]} {
  eval [::http::data $token]
 }
 $p.f.f2.lb delete 0 end
 foreach plugin [lsort $Info(Download,list)] {
  if {[lsearch [GetRegisteredPlugins] $plugin] != -1} {
   $p.f.f2.lb insert end "$plugin (installed)"
  } else {
   $p.f.f2.lb insert end $plugin
  }
 }
}

proc wsurf::_install {p} {
 variable Info

 set index [$p.f.f2.lb curselection]
 if {$index == ""} return
 set plug [$p.f.f2.lb get $index]
 if {[string match *installed* $plug]} {
  tk_messageBox -message "This plug-in is already installed."
  return
 }
 foreach fn $Info(Download,$plug) {
  if {[llength $fn]==2} {
   # we have two elements: destination and url
   foreach {dst url} $fn break
  } else {
   # only one element: url
   set dst plugins
   set url $fn
  }
  #<< downloading:
  #<< dst=$dst
  #<< url=$url
  switch $dst {
   plugins {
    set file [file join [lindex $Info(PluginDir) 0] [file tail $fn]]
   }
   configurations {
    set file [file join [lindex $Info(ConfigDir) 0] [file tail $fn]]
   }
   default {
    error "There was an error installing the plugin"
   }
  }
  #<< file=$file
  set token [::http::geturl $url -binary 1 \
    -progress [namespace code [list _httpProgress]]]
  if {[string match *200* [::http::code $token]] == 1} {
   set fd [open $file w]
   fconfigure $fd -translation binary -encoding binary
   puts -nonewline $fd [::http::data $token]
   close $fd
  }
  if {[string match *.plug $file]} {
   set plugfile $file ;# remember this filename so we can load the plugin
  }
 }

 if {[info exists plugfile]} {
  LoadPlugins [list $plugfile]
 }

 snack::addExtTypes [concat $::surf(extTypes)]
 snack::addLoadTypes $::surf(loadTypes) $::surf(loadKeys)
 snack::addSaveTypes $::surf(saveTypes) $::surf(saveKeys)
 pluginsDialog
 tk_messageBox -message "Done installing: $plug"
}

proc wsurf::_httpProgress {token total current} {
 update
 if {$current > 0} {
  snack::progressCallback "Downloading..." [expr $total/$current]
 }
}

proc wsurf::_pluginSelect {p lb} {
 variable Info

 set plug [$lb get [$lb curselection]]
 $p.f.f3.t delete 1.0 end
 if {[info exists Info(PluginData,$plug,description)]} {
  $p.f.f3.t insert end $Info(PluginData,$plug,description)
 }
 if {[info exists Info(PluginData,$plug,URL)]} {
  $p.f.f4.b configure -text $Info(PluginData,$plug,URL)
 } else {
  $p.f.f4.b configure -text ""
 }
 if {[info exists Info(PluginData,$plug,location)]} {
  set loc $Info(PluginData,$plug,location)
  set font [$p.f.f5.l2 cget -font]
  set wid [winfo width $p.f.f5.l2]
  if {[font measure $font $loc] > $wid} {
   set loc ...$loc
   while {[font measure $font $loc] > $wid} {
    set loc [string replace $loc 3 3]
   }
  }
  $p.f.f5.l2 configure -text $loc
  if {1 && $Info(PluginData,$plug,URL)!=""} {
   $p.f.f4.b configure -command [list util::showURL $Info(PluginData,$plug,URL)]
  } else {
   $p.f.f4.b configure -command ""
  }
 } else {
  $p.f.f5.l2 configure -text ""
 }
}

proc wsurf::_pluginReload {p} {
 variable Info

 set plug [$p.f.f1.lb get [$p.f.f1.lb curselection]]
 source $Info(PluginData,$plug,location)
}

proc wsurf::_reconfPlugins {} {
 variable Info

 foreach w $Info(widgets) {
  upvar [namespace current]::${w}::data d
  foreach plugin $Info(Plugins) {
   foreach pane [_getPanes $w] {
    deletePane $w $pane
   }
   set widget $w
   if {$d(configuration) != ""} {source $d(configuration)}
  }
 }
}

# -----------------------------------------------------------------------------

proc wsurf::play {w {start -1} {end -1}} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 if {$d(isPaused)} {
  if {[string compare $Info(ActiveSound) $d(sound)] == 0} {
   pause $w
   return
  }
 }
 if {[info commands $Info(ActiveSound)] != ""} {
  $Info(ActiveSound) stop
 }

 set s [$w cget -sound]
 set d(isPaused) 0
 if {$start == -1} {
  foreach {start end} [$w cget -selection] break
  if {$start == $end} { set end [$s length -unit seconds] }
  if {$start == $end} return
 }
 set rate [$s cget -rate]
 set d(playStartPos) [expr {round($rate*$start)}]
 if {$end == -1} {
  set end [$s length -unit seconds]
 }
 set d(playEndPos) [expr {round($rate*$end)}]
 if {$end-$start < 0.2} {
  set d(looping) 0
 }

 #<< "$s play -start $d(playStartPos) -end $d(playEndPos) -filter $d(mapFilter) -command [namespace code [list set Info(ActiveSound) ""]]"

 $s play -start $d(playStartPos) -end $d(playEndPos) -filter $d(mapFilter) \
	 -command [namespace code [list playDone $w]]

 set Info(ActiveSound) $s
 _callback $w playProc
 
 if {$end - $start > .5 || $d(looping) == 0} {
  after 0 [namespace code [list _updatePlayMarker $w]]
 }
 if {[lsearch $d(icons) play] != -1 && $::useTile == 0} {
  $wid(play,button) configure -relief sunken
 }
}

proc wsurf::playall {w} {
  play $w 0 -1
}

proc wsurf::playcont {w} {
  foreach {start end} [$w cget -selection] break
  play $w $start -1
}

proc wsurf::playvisib {w} {
  upvar [namespace current]::${w}::data d
  play $w $d(xviewT1) $d(xviewT2)
}

proc wsurf::playloop {w} {
  upvar [namespace current]::${w}::data d
  stop $w
  set d(looping) 1
  set d(loopStartPos) 0
  play $w
}

proc wsurf::playPopupMenu {w X Y} {
  upvar [namespace current]::${w}::widgets wid
  upvar [namespace current]::${w}::data d

  set m $w.popup
  if {[winfo exists $m]} {destroy $m}
  menu $m -tearoff 0
  
  $m add command -label "Play selection" \
      -command [namespace code [list play $w]]
  $m add command -label "Play all" \
      -command [namespace code [list playall $w]]
  $m add command -label "Play continue" \
      -command [namespace code [list playcont $w]]
  $m add command -label "Play visible" \
      -command [namespace code [list playvisib $w]]
  $m add command -label "Play loop" \
      -command [namespace code [list playloop $w]]
 
  if {[string match macintosh $::tcl_platform(platform)]} {
    tk_popup $w.popup $X $Y 0
  } else {
    tk_popup $w.popup $X $Y
  }
}

proc wsurf::playDone {w} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 if {[info exists d(looping)] && $d(looping)} {
  set s [$w cget -sound]
  set d(loopStartPos) [snack::audio elapsed]
  after 0 [namespace code [list play $w]]
#  update
  return
 }

 set Info(ActiveSound) ""
 if {[info exists d(icons)] && [lsearch $d(icons) play] != -1 && $::useTile == 0} {
  $wid(play,button) configure -relief flat
 }
}
# -----------------------------------------------------------------------------

proc wsurf::pause {w} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 if {$d(isRecording)} {
  $d(sound) pause
 } else {
  set s [$w cget -sound]
  set rate [$s cget -rate]
  if {$d(isPaused)} {
   foreach {start end} [$w cget -selection] break
   set start [expr {round($rate*$start)}]
   set end   [expr {round($rate*$end)}]

   if {$start == $end} { set end -1 }
   $d(sound) play -start $d(playStartPos) -filter $d(mapFilter) \
    -end $end -command [namespace code [list playDone $w]]
  } else {
   set d(playStartPos) [expr {int($d(playStartPos) + \
	   [snack::audio elapsedTime] * $rate)}]
   $d(sound) stop
  }
 }

 set d(isPaused) [expr {1 - $d(isPaused)}]
 _callback $w pauseProc
 if {$d(isRecording) || \
     [expr {[string compare $Info(ActiveSound) [$w cget -sound]] == 0}]} {
  if {$Info(Prefs,pause) && $::useTile == 0} {
   if {$d(isPaused)} {
    $wid(pause,button) configure -relief sunken
   } else {
    $wid(pause,button) configure -relief flat
   }
  }
 }
}

# -----------------------------------------------------------------------------

proc wsurf::record {w} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d
 variable Info

 if {[info commands $Info(ActiveSound)] != ""} {
  $Info(ActiveSound) stop
 }
 set s [$w cget -sound]
 set d(isRecording) 1
 if {$d(linkFile)} {
  set fn [file join $Info(Prefs,tmpDir) $w.[pid].wav]
  catch {file delete -force $fn}
  $wid(wavebar) configure -shapefile ""
  $s configure -file $fn
 }
 $wid(wavebar) configure -isrecording 1
 set Info(ActiveSound) $s
 $s record
 set d(isPaused) 0
 _callback $w recordProc
 after [expr {$Info(Prefs,recordLimit)*1000}] [list wsurf::stop $w]
 if {[lsearch $d(icons) record] != -1 && $::useTile == 0} {
  $wid(record,button) configure -relief sunken
 }
}

# -----------------------------------------------------------------------------

proc wsurf::stop {w} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d
 variable Info
 if {[winfo exists $w] == 0} return
 set d(isPaused) 0
 after cancel [list wsurf::stop $w]

 if {[info commands $Info(ActiveSound)] != ""} {
  if {[string compare $Info(ActiveSound) $d(sound)]} {
   return
  }
 }
 if {[lsearch $d(icons) play] != -1 && $::useTile == 0} {
  $wid(play,button) configure -relief flat
 }
 if {$Info(Prefs,pause) && $::useTile == 0} {
  $wid(pause,button) configure -relief flat
 }
 if {[lsearch $d(icons) record] != -1 && $::useTile == 0} {
  $wid(record,button) configure -relief flat
 }
 set Info(ActiveSound) ""
 if {[snack::audio active]} {
  $d(sound) stop
 }
 _callback $w stopProc
 set d(looping) 0
 set d(loopStartPos) 0
 if {!$d(isRecording)} {
  return
 }
 set d(isRecording) 0
 $wid(wavebar) configure -isrecording 0
 if {$d(linkFile)} {
  $wid(wavebar) configure -shapefile [_shapeFilename $w $d(fileName)]
 }
 set d(isPaused) 0
 _soundChanged $w New
 _redraw $w
}

proc wsurf::beg {w} {
 variable Info
 $w configure -selection [list 0.0 0.0]
 if {[info commands $Info(ActiveSound)] != ""} {
  play $w
 }
}

proc wsurf::end {w} {
 variable Info
 upvar [namespace current]::${w}::data d
 $w configure -selection [list $d(maxtime) $d(maxtime)]
 if {[info commands $Info(ActiveSound)] != ""} {
  stop $w
 }
}

proc wsurf::_updatePlayMarker {w} {
 variable Info
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d

 if {![winfo exists $w]} return
 after cancel [namespace code [list _updatePlayMarker $w]]
 set s [$w cget -sound]
 if {[$s length] == 0} return
 
 if {![snack::audio active]} {
  set flag break
 }
 if {[string compare $Info(ActiveSound) $s]} {
  if {$Info(ActiveSound) != ""} {
   if {[lsearch $d(icons) play] != -1 && $::useTile == 0} {
    $wid(play,button) configure -relief flat
   }
   if {$Info(Prefs,pause) && $::useTile == 0} {
    $wid(pause,button) configure -relief flat
   }
   if {[lsearch $d(icons) record] != -1 && $::useTile == 0} {
    $wid(record,button) configure -relief flat
   }
  }
  set flag break
 }
 
 if {$d(isPaused)} {
#  set left $d(playStartPos)
#  set d(playStartPos) [expr {double($d(playStartPos)) / [$s length]}]
#  if {$left == $d(playEndPos)} {
#   set d(playEndPos) $d(playStartPos)
#  }
  after 50 [namespace code [list _updatePlayMarker $w]]
  return
 }
 set startPos [expr {double($d(playStartPos)) / [$s cget -rate]}]
 set curpos [expr {$startPos+[snack::audio elapsed]-$d(loopStartPos)}]
 foreach pane [$w _getPanes] {
  $pane configure -cursorpos $curpos
 }

 $wid(wavebar) configure -cursorpos $curpos
 if {[info exists flag]} {
  foreach pane [$w _getPanes] {
   $pane configure -cursorpos ""
  }
  $wid(wavebar) configure -cursorpos -1
  if {$d(playpositionProc) != "" && $Info(Prefs,showLevel)} {
    if {!($d(linkFile) && [string match MP3 [lindex [$s info] 6]])} {
      $d(playpositionProc) Stop 0
    }
  }
  return
 }
 switch $Info(Prefs,autoScroll) {
  Scroll {
   xscroll $w moveto [t->frac $w [expr {$curpos-($d(xviewT2)-$d(xviewT1))/2}]]
  }
  Page {
   if {$curpos > $d(xviewT2) || $curpos < $d(xviewT1)} {
    xscroll $w moveto [t->frac $w $curpos]
   }
  }
 }
 if {$d(playpositionProc) != "" && $Info(Prefs,showLevel)} {
   if {!($d(linkFile) && [string match MP3 [lindex [$s info] 6]])} {
     $d(playpositionProc) Play $curpos
   }
 }
 after 50 [namespace code [list _updatePlayMarker $w]]
}

# -----------------------------------------------------------------------------

proc wsurf::printDialog {w} {
 upvar [namespace current]::${w}::data d
 variable Info

 set wi .print
 catch {destroy $wi}
 toplevel $wi
 set title [::util::mc "Print:"]
 append title " $d(title)"
 wm title $wi $title

 _updatePrintPages $w

 set maxWidth [::util::mcmax "Print command:" "Preview command:" \
		   "Save to PS-file:"]
 frame $wi.f1
 label $wi.f1.l1 -text [::util::mc "Pages:"]
 entry $wi.f1.e1 -textvar [namespace current]::Info(FirstPage) -width 3
 label $wi.f1.l2 -text [::util::mc "to"]
 entry $wi.f1.e2 -textvar [namespace current]::Info(LastPage) -width 3
 checkbutton $wi.f1.cb -text [::util::mc "Print selection only"] \
   -variable [namespace current]::Info(PrintSelection) \
   -command [namespace code [list _updatePrintPages $w]]
 pack $wi.f1.l1 $wi.f1.e1 $wi.f1.l2 $wi.f1.e2 $wi.f1.cb -side left

 frame $wi.f2
 label $wi.f2.l1 -text [::util::mc "Print command:"] -wi $maxWidth -anchor e
 entry $wi.f2.e1 -textvar [namespace current]::Info(Prefs,PrintCmd) -wi 40
 button $wi.f2.b1 -text [::util::mc Print] -command [namespace code [list print $w print]] -wi 8
 pack $wi.f2.l1 -side left -padx 3
 pack $wi.f2.e1 -side left -padx 3 -expand true -fill x
 pack $wi.f2.b1 -side left -padx 3
 bind $wi.f2.e1 <Key-Return> [namespace code [list print $w print]]

 frame $wi.f3
 label $wi.f3.l1 -text [::util::mc "Preview command:"] -wi $maxWidth -anchor e
 entry $wi.f3.e1 -textvar [namespace current]::Info(Prefs,PrintPVCmd) -wi 40
 button $wi.f3.b1 -text [::util::mc Preview] \
     -command [namespace code [list print $w preview]] \
	    -wi 8
 pack $wi.f3.l1 -side left -padx 3
 pack $wi.f3.e1 -side left -padx 3 -expand true -fill x
 pack $wi.f3.b1 -side left -padx 3
 bind $wi.f3.e1 <Key-Return> [namespace code [list print $w preview]]

 frame $wi.f4
 label $wi.f4.l1 -text [::util::mc "Save to PS-file:"] -wi $maxWidth -anchor e
 entry $wi.f4.e1 -textvar [namespace current]::Info(PrintFile) -wi 40
 button $wi.f4.b1 -text [::util::mc Save] \
     -command [namespace code [list print $w save]] -wi 8
 pack $wi.f4.l1 -side left -padx 3
 pack $wi.f4.e1 -side left -padx 3 -expand true -fill x
 pack $wi.f4.b1 -side left -padx 3
 bind $wi.f4.e1 <Key-Return> [namespace code [list print $w save]]

 frame $wi.f
 button $wi.f.exitB -text [::util::mc Close] -command [list destroy $wi]
 pack $wi.f.exitB
 pack $wi.f1 -side top -fill x -ipadx 10 -ipady 10
 pack $wi.f2 $wi.f3 $wi.f4 -side top -fill x
 pack $wi.f -side top -fill both -expand true -ipadx 10 -ipady 10
}

proc wsurf::_updatePrintPages {w} {
 upvar [namespace current]::${w}::data d
 variable Info

 set Info(FirstPage) 1

 if {$Info(PrintSelection)} {
  foreach {start end} [$w cget -selection] break
  if {$start == $end} {
   set Info(FirstPage) -1
   set pixWidth -1000
  } else {
   set pixWidth [expr {int(($end - $start) * [$w cget -pixelspersecond])}]
  }
 } else {
  set pixWidth [expr {int([$d(sound) length -unit seconds] * \
    [$w cget -pixelspersecond])}]
 }

 set Info(LastPage) [expr {int(($pixWidth + 949) / 950)}]
}

proc wsurf::print {w op} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d
 variable Info
 
 messageProc $w [::util::mc "Printing..."]
 update idletasks
 destroy .tempc
 canvas .tempc

 if {$Info(PrintSelection)} {
  foreach {start end} [$w cget -selection] break
  if {$start == $end} {
   return
  } else {
   set x [expr {int($start*[$w cget -pixelspersecond])}]
   set pixWidth [expr {int(($end - $start) * [$w cget -pixelspersecond])}]
  }
 } else {
  set x 0
  set pixWidth [expr {int([$d(sound) length -unit seconds] * \
    [$w cget -pixelspersecond])}]
 }

 if {![info exists Info(FirstPage)]} {
  set Info(FirstPage) 1
  set Info(LastPage) [expr {int(($pixWidth+949)/950)}]
 }

 set n 0
 set pageno 0
 set yw 0
 while {$pixWidth > 0} {
  set y 0
  incr pageno
  if {$pageno >= $Info(FirstPage)} {
   if {$pageno > $Info(LastPage)} break
   .tempc delete tmpPrint
    set time [clock format [clock seconds] -format "%a %b %d %T"]
   .tempc create text [expr {$x + 10}] $y -text "[::util::mc File:] $d(fileName)   [::util::mc Page:] $pageno [::util::mc of] $Info(LastPage)   [::util::mc Printed:] $time" -anchor nw -tags tmpPrint
   incr y 20

   # Draw each pane on the temporary canvas

   foreach pane [_getPanes $w] {
    _callback $w printProc $pane .tempc $x $y
    $pane print .tempc $x $y
    incr y [$pane cget -scrollheight]
    set yw [winfo width [$pane yaxis]]
   }
   if {$pixWidth < 950} {
    .tempc create rectangle [expr $x+$yw+$pixWidth] 20 \
	[expr $x+$yw+$pixWidth+950] $y -fill white -outline "" \
	-tags tmpPrint
   }

   # Generate postscript for the temporary canvas

   .tempc postscript -file $Info(Prefs,tmpDir)/_tmp$n.ps \
     -x $x -width 950 -height $y \
     -rotate true -pagewidth 26c
   regsub -all \\\\ $Info(Prefs,tmpDir)/_tmp$n.ps / psfile
   switch $op {
    print {
     regsub {\$FILE} $Info(Prefs,PrintCmd) $psfile cmd
     eval exec $cmd
    }
    preview {
     regsub {\$FILE} $Info(Prefs,PrintPVCmd) $psfile cmd
     #<< "print preview cmd:\n$cmd"
     eval exec $cmd
    }
    save {
     regsub -all {\$N} $Info(PrintFile) $n psfile
     file copy -force $Info(Prefs,tmpDir)/_tmp$n.ps $psfile
    }
   }
   catch {file delete $Info(Prefs,tmpDir)/_tmp$n.ps}
   incr n
  }
  incr x 900
  incr pixWidth -900
 }
 if {$n == 1} {
  messageProc $w "Printed $n page"
 } else {
  messageProc $w "Printed $n pages"
 }
 destroy .tempc
}

# -----------------------------------------------------------------------------

proc wsurf::needSave {w} {
 upvar [namespace current]::${w}::data d

 set doCheck $d(soundChanged)
 foreach pane [_getPanes $w] {
  foreach res [_callback $w needSaveProc $pane] {
   if {$res} { set doCheck 1 }
  }
 }
 set doCheck
}

proc wsurf::closeWidget {w} {
 variable Info
 upvar [namespace current]::${w}::data d

 if {[needSave $w]} {
  if {$d(showExitDialog)} {
   set d(showExitDialog) 0
   if {[string match no [tk_messageBox -message "[::util::mc "You have unsaved changes."]\n[::util::mc "Do you really want to close?"]" -type yesno -icon question]]} {
    set d(showExitDialog) 1
    return
   }
  } else {
   return
  }
 }
 destroy $w
}

# -----------------------------------------------------------------------------

proc wsurf::messageProc {w message {sender anonymous}} {
 upvar [namespace current]::${w}::data d

 if {$d(messageProc) == ""} return
 set d(msg,$sender) $message
 set msglist {}
 foreach key [lsort [array names d msg,*]] {
  if {$d($key) != ""} {
   lappend msglist $d($key)
  }
 }
 set message [join $msglist " | "]

 list {
  foreach {opt val} $args {
   if {[string match -lock $opt]} {
    if {$val} {
     $d(messageProc) $message
     set d(messageLocked) 1
    } else { 
     set d(messageLocked) 0
    }
    return
   } else {
    error "bad option \"$opt\""
   }
  }
 }

 if {$d(messageLocked)} return
 $d(messageProc) $message
}

# -----------------------------------------------------------------------------

proc wsurf::_shapeFilename {w fileName} {
 if {$fileName == ""} {
  return ""
 } else {

   # Check if there is a shape file in the same directory as the sound file

   if {[file exists [file rootname $fileName].shape]} {
     return [file rootname $fileName].shape
   }

   # Otherwise use the current directory

   return [file rootname [file tail $fileName]].shape
 }
}

# Note that args are ignored, earlier used to specify raw file properties

proc wsurf::openFile {w fileName args} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d
 variable Info
 set readByPlugin 0

 foreach res [_callback $w openFileProc $fileName] {
  if {$res == 1} { set readByPlugin 1 }
 }

 if {$readByPlugin} {
  configure $w -title [file tail $fileName]
  set d(fileName) $fileName
  return
 }

 set Info(guessRate) 16000
 set Info(guessEnc) lin16
 set Info(guessChan) 1
 set Info(guessByteOrder) little
 set Info(guessSkip) 0
 set fileformat ""

 # Check if there is a user defined format for this extension
 # Go ahead and load the file in that case
 set fnExt [file extension $fileName]
 set foundDef 0
 foreach {ext rate enc chan bo skip} $Info(Prefs,rawFormats) {
   if {[string compare $fnExt $ext] == 0 || \
       ($::tcl_version > 8.0 && [string compare -nocase $fnExt $ext] == 0)} {
     set Info(guessRate)      $rate
     set Info(guessEnc)       $enc
     set Info(guessChan)      $chan
     set Info(guessByteOrder) $bo
     set Info(guessSkip)      $skip
     set foundDef 1
     set fileformat RAW
     break
   }
 }
 
 # Take a peek at the sound to see if we recognize the file format
 if {$foundDef == 0} {
  set tmps [snack::sound -debug $::wsurf::Info(debug)]
  if {[catch {set fileformat [$tmps read $fileName -end 1 -guessproperties 1]} ret]} {
     error $ret
  }
  set Info(guessRate)      [$tmps cget -rate]
  set Info(guessEnc)       [$tmps cget -encoding]
  set Info(guessChan)      [$tmps cget -channels]
  set Info(guessByteOrder) [$tmps cget -byteorder]
  set Info(guessSkip) 0
  if {$fileformat == "RAW"} {
    # This file extension has no properties definition, let user decide      
    if {[InterpretRawDialog $fnExt] == "cancel"} {
      $tmps destroy
      return
    }
  }
 }


 set d(fileName) $fileName
 set s [$w cget -sound]

 if {$d(linkFile)} {
  $wid(wavebar) configure -sound ""
  $s configure -file $fileName -skip $Info(guessSkip) -rate $Info(guessRate) \
      -encoding $Info(guessEnc) -channels $Info(guessChan) \
      -byteorder $Info(guessByteOrder) -fileformat $fileformat
  snack::deleteInvalidShapeFile [file tail $fileName]

  update ;# don't want queued events here

  # -progress must be configured before -shapefile
  # because wavebar::configure handles option one at a time
  # and the shapefile would be computed before the progress callback was added
  $wid(wavebar) configure -sound $s -progress $d(progressProc) \
	  -shapefile [_shapeFilename $w $fileName]

  snack::makeShapeFileDeleteable [file tail $fileName]
 } else {
  if {[catch {set v(smpfmt) [$s read $fileName -progress $d(progressProc) \
    -skip $Info(guessSkip) -rate $Info(guessRate) -encoding $Info(guessEnc) \
    -channels $Info(guessChan) -byteorder $Info(guessByteOrder) \
    -fileformat $fileformat]} ret]} {
   if {$ret!=""} {
    messageProc $w "$ret"
   }
   return
  }
 }
 configure $w -title [file tail $fileName]
 set d(soundChanged) 0
}

# -----------------------------------------------------------------------------

proc wsurf::saveFile {w fileName} {
 variable Info
 upvar [namespace current]::${w}::data d
 set oldName $d(fileName)
 set d(fileName) $fileName
 set savedByPlugin 0
 foreach res [_callback $w saveFileProc $fileName] {
  if {$res} { set savedByPlugin 1 }
 }
 #<< "savedByPlugin = $savedByPlugin"

 if {$savedByPlugin == 0 && ([string compare $oldName $fileName] || \
   $d(soundChanged))} {
  set s [$w cget -sound]
  if {$d(linkFile)} {
   if {[catch {$s write $fileName -progress $d(progressProc)} ret]} {
    if {$ret!=""} {
     messageProc $w "$ret"
     set d(fileName) $oldName 
     return
    }
    $s configure -file $fileName
   }
  } else {
   if {[catch {$s write $fileName -progress $d(progressProc)} ret]} {
    if {$ret!=""} {
     messageProc $w "$ret"
     set d(fileName) $oldName 
     return
    }
   }
  }
 }
 set d(soundChanged) 0
 configure $w -title [file tail $fileName]
}

proc wsurf::new {w} {
 variable Info
 upvar [namespace current]::${w}::data d
 set s [$w cget -sound]
 $s flush
 set d(fileName) ""
 set d(soundChanged) 0
 configure $w -title ""
}

# -----------------------------------------------------------------------------

proc wsurf::undo {w} {
 variable Info

 if {$Info(undoCmd) != ""} {
  eval $Info(undoCmd)
 }
 foreach {Info(undoCmd) Info(redoCmd)} [list $Info(redoCmd) $Info(undoCmd)] \
     break
 _callback $w undoProc
 _redraw $w
}

proc wsurf::PrepareUndo {undoCmd redoCmd} {
 variable Info
 set Info(undoCmd) $undoCmd
 set Info(redoCmd) $redoCmd
}

# -----------------------------------------------------------------------------

proc wsurf::cut {w soundObj} {
 variable Info
 upvar [namespace current]::${w}::data d

 set s [$w cget -sound]
 set rate [$s cget -rate]
 foreach {left right} [$w cget -selection] break
 set start [expr {int($rate * $left+.5)}]
 set end   [expr {int($rate * $right+.5)}]

 if {$end >= [$s length]} { set end [expr {[$s length]-1}]}
 if {$start >= $end} return
 if {$left == $d(cutTime)} {
  set start $d(cutStart)
 }
 messageProc $w "Cutting range: $start $end"
 set s [$w cget -sound]
 $soundObj copy $s -start $start -end $end
 $s cut $start $end
 set Info(undoCmd) "$s insert $soundObj $start"
 set Info(redoCmd) "$s cut $start $end"
 set t0 [expr {double($start)/$rate}]
 set t1 [expr {double($end)/$rate}]
 _callback $w cutProc $t0 $t1
 $w configure -selection [list $t0 $t0]
 set d(cutTime)  $t0
 set d(cutStart) $start

}

# -----------------------------------------------------------------------------

proc wsurf::copy {w soundObj} {
 upvar [namespace current]::${w}::data d

 set s [$w cget -sound]
 set rate [$s cget -rate]
 foreach {left right} [$w cget -selection] break
 set start [expr {int($rate * $left+.5)}]
 set end   [expr {int($rate * $right+.5)}]
 clipboard clear
 $soundObj flush
 _callback $w copyProc [expr {double($start)/$rate}] \
   [expr {double($end)/$rate}]
 if {$start == $end} return
 messageProc $w "Copying range: $start $end"
 $soundObj copy $s -start $start -end $end
}

# -----------------------------------------------------------------------------

proc wsurf::paste {w soundObj} {
 variable Info
 upvar [namespace current]::${w}::data d


 set s [$w cget -sound]
 set rate [$s cget -rate]
 foreach {left right} [$w cget -selection] break
 set start [expr {int($rate * $left+.5)}]
 set flag [_callback $w pasteProc [expr {double($start)/$rate}] \
	       [$soundObj length -unit seconds]]
 
 if {[string match {*1*} $flag] == 0} {
  messageProc $w "Inserting at: $start"
  set s [$w cget -sound]
  $soundObj convert -rate $rate
  $soundObj convert -channels [$s cget -channels]
  $soundObj convert -encoding [$s cget -encoding]
  $s insert $soundObj $start
  
  set tmp [expr {$start + [$soundObj length] - 1}]
  set Info(undoCmd) "$s cut $start $tmp"
  set Info(redoCmd) "$s insert $soundObj $start"
  $w configure -selection [list [expr {double($start)/$rate}] \
    [expr {double($start+[$soundObj length]-1)/$rate}]]
 }
}

# -----------------------------------------------------------------------------

proc wsurf::getSound {w} {
 upvar [namespace current]::${w}::data d

 set d(sound)
}

# -----------------------------------------------------------------------------

proc wsurf::_soundChanged {w args} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d
 
 if {$args == "Destroyed"} return

 if {$d(isRecording)} return 

 updateBounds $w dummy

 set d(soundChanged) 1
 _callback $w soundChangedProc $args
 $wid(wavebar) soundChanged
}

# -----------------------------------------------------------------------------

proc wsurf::findPane {w path} {
 upvar [namespace current]::${w}::data d
 if {[info exists d(panePath,$path)]} {
  set d(panePath,$path)
 } else {
  set path
 }
}

# -----------------------------------------------------------------------------

proc wsurf::getInfo {w property} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d
 variable Info

 switch $property {
  workspace {
   return $wid(workspace)
  }
  fileName {
   return $d(fileName)
  }
  isLinked2File {
   return $d(linkFile)
  }
  isRecording {
   return $d(isRecording)
  }
  isPaused {
   return $d(isPaused)
  }
  isPlaying {
   return [expr {[string compare $Info(ActiveSound) [$w cget -sound]] == 0}]
  }
  hasPanes {
   return [expr {[llength $d(panes)] > 0}]
  }
  isUntouched {
   set s [$w cget -sound]
   #   if {[$s length] == 0 && $d(paneCount) == 0} 
   if {[$s length] == 0} {
    return 1
   } else {
    return 0
   }
  }
  default {
   error "no such property"
  }
 }
}

# -----------------------------------------------------------------------------

# dump 
# - print variables in widget namespace (for debugging)
#   pattern is the unqualified variable name, e.g. widgets or data

proc wsurf::dump {w {pattern *} {subpattern *}} {

 set ns [namespace current]::${w}
 foreach var [uplevel #0 [list info var ${ns}::$pattern]] {
  variable $var
  puts ""
  if {[array exists $var]} {parray $var $subpattern} else {puts "$var = [set $var]"}
 }
}

# -----------------------------------------------------------------------------

proc wsurf::exampleCmd {w args} {
 upvar [namespace current]::${w}::widgets wid
 upvar [namespace current]::${w}::data d
}
