#!/bin/sh
# the next line restarts using wish \
exec wish8.5 "$0" "$@"

package require -exact snack 2.2
# Try to load optional file format handlers
catch { package require snacksphere }
catch { package require snackogg }
package require http

set debug 0
snack::debug $debug
snack::sound snd -debug $debug
snack::sound cbs -debug $debug

set tcl_precision 7
set f(prog) [info script]
set f(labfile) ""
set f(sndfile) ""
set f(lpath)   ""
set f(header)  ""
set mexhome "~/snack/"
catch {source $mexhome/ipa_tmh.tcl}
set f(ipapath) $mexhome/ipa_xbm
set local 0
if $local {
    set v(labfmt) TIMIT
    set v(smpfmt) WAV
    set v(ashost) ior.speech.kth.se
} else {
    set v(labfmt) TIMIT
    set v(smpfmt) WAV
    set v(ashost) localhost
}
set labels {}
set undo {}
set v(labchanged) 0
set v(smpchanged) 0
set v(width) 600
set v(toth) 286
set v(msg) "Press right mouse button for menu"
set v(timeh) 20
set v(yaxisw) 40
set v(labelh) 20
set v(psfilet) {tmp$N.ps}
set v(psfile)  ""
set v(vchan)   -1
#set v(offset) 0
#set v(zerolabs) 0
set v(startsmp) 0
set v(lastmoved) -1
set v(p_version) 2.2
set v(s_version) 2.2
set v(plugins) {}
set v(scroll) 1
set v(rate) 16000
set v(sfmt) Lin16
set v(chan) 1
set v(topfr) 8000
set v(rp_sock) ""
#set v(propflag) 0
set v(pause) 0
set v(recording) 1
set v(activerec) 0
set v(cmap) grey
set v(grey) " "
#set v(color1) {#000 #006 #00B #00F #03F #07F #0BF #0FF #0FB #0F7 \
	      #0F0 #3F0 #7F0 #BF0 #FF0 #FB0 #F70 #F30 #F00}
set v(color1) {#000 #004 #006 #00A #00F \
 	       #02F #04F #06F #08F #0AF #0CF #0FF #0FE \
	       #0FC #0FA #0F8 #0F6 #0F4 #0F2 #0F0 #2F0 \
	       #4F0 #6F0 #8F0 #AF0 #CF0 #FE0 #FC0 #FA0 \
	       #F80 #F60 #F40 #F20 #F00}
set v(color2) {#FFF #BBF #77F #33F #00F #07F #0BF #0FF #0FB #0F7 \
	      #0F0 #3F0 #7F0 #BF0 #FF0 #FB0 #F70 #F30 #F00}
set v(contrast) 0
set v(brightness) 0
set v(showspeg) 0
set v(remspegh) 200
set v(remote) 0
set v(asport) 23654
set v(handle) ""
set v(s0) 0

set z(zoomwinh) 200
set z(zoomwinw) 600
set z(zoomwinx) 200
set z(zoomwiny) 200
set z(zoomwavh) 0
set z(zoomwavw) 0
set z(f) 1

set s(sectwinh) 400
set s(sectwinw) 400
set s(sectwinx) 200
set s(sectwiny) 200
set s(secth) 400
set s(sectw) 400
set s(rx) -1

proc SetDefaultVars {} {
    global f v s local

    set v(waveh) 50
    set v(spegh) 0
    set v(scrw) 32767
    set v(pps) 400
    set v(opps) 400
    set v(fftlen) 256
    set v(winlen) 128
    set v(anabw) 125
    set v(preemph) 0.97
    set v(ipa) 0
    set v(autoload) 0
    set v(ch) 0
    set v(slink) 0
    set v(mlink) 0
    if {$::tcl_platform(platform) == "unix"} {
	set v(printcmd)  {lpr $FILE}
	set v(gvcmd)     {ghostview $FILE}
	set v(psfilecmd) {cp -f _xspr$n.ps $v(psfile)}
	if $local {
	    set v(pluginfiles) {~/snack/xsplug/dataplot.plg ~/snack/xsplug/generator.plg ~/snack/xsplug/transcribe.plg ~/snack/xsplug/cutter.plg ~/snack/xsplug/pitch.plg}
	} else {
	    set v(pluginfiles) [glob -nocomplain *.plg]
	}
#	set v(browser) "netscape"
	if {$::tcl_platform(os) == "HP-UX"} {
	    option add *font {Helvetica 10 bold}
	} else {
	    option add *font {Helvetica 12 bold}
	}
    } else {
	set v(printcmd)  {C:/gs/gs6.50/bin/gswin32 "-IC:\gs\gs6.50;C:\gs\gs6.50\fonts" -sDEVICE=laserjet -dNOPAUSE $FILE -c quit}
	set v(gvcmd)     {C:/ghostgum/gsview/gsview32 $FILE}
	set v(psfilecmd) {command.com /c copy _xspr$n.ps $v(psfile)}
	if $local {
#	    set v(pluginfiles) {H:/tcl/mexd/dataplot.plg H:/tcl/mexd/generator.plg H:/tcl/mexd/pitch.plg}
            set v(pluginfiles) {}
	} else {
	    set v(pluginfiles) [glob -nocomplain *.plg]
	}
#	set v(browser) "c:/program files/netscape/communicator/program/netscape.exe"
    }
    set v(ipafmt) TMH
    set v(labalign) w
    set v(fg) black
    set v(bg) [. cget -bg]
    if {[string match macintosh $::tcl_platform(platform)] || \
	    [string match Darwin $::tcl_platform(os)]} {
	set v(fillmark) 0
    } else {
	set v(fillmark) 1
    }
    set v(font)  {Courier 10}
    if {[string match unix $::tcl_platform(platform)] } {
     set v(sfont) {Helvetica 10 bold}
    } else {
     set v(sfont) {Helvetica 8 bold}
    }
    set v(gridfspacing) 0
    set v(gridtspacing) 0
    set v(gridcolor) red
    set v(cmap) grey
    set v(showspeg) 0
    set v(remspegh) 200
    set v(linkfile) 0
    set f(skip) 0
    set f(byteOrder) ""
    set f(ipath) ""
    set f(ihttp) "http://www.speech.kth.se/~kare/ex1.wav"
    #"http://www.speech.kth.se/cgi-bin/TransAll?this_is_an_example+am"

    set s(fftlen) 512
    set s(anabw)  31.25
    set s(ref)    -110.0
    set s(range)  110.0
    set s(wintype) Hamming
    set s(atype) FFT
    set s(lpcorder) 20

    if {[info exists snack::snackogg]} {
      set ::ogg(nombr) 128000
      set ::ogg(maxbr) -1
      set ::ogg(minbr) -1
      set ::ogg(com)   ""
      set ::ogg(query) 1
    }
}

SetDefaultVars
catch { source [file join ~ .xsrc] }
catch { source [file join ~ .xsrf] }

snd config -rate $v(rate)
snd config -encoding $v(sfmt)
snd config -channels $v(chan)

set filt(f) [snack::filter map 0.0]

set echo(f) [snack::filter echo 0.6 0.6 30 0.4]
set echo(n) 1
set echo(drain) 1
set echo(iGain) 60
set echo(oGain) 60

set mix(f) [snack::filter map 0.0]

set amplify(f) [snack::filter map 1.0]
set amplify(v) 100.0
set amplify(db) 0

set normalize(f) [snack::filter map 1.0]
set normalize(v) 100.0
set normalize(db) 0
set normalize(allEqual) 1

set remdc(f) [snack::filter iir -numerator "0.99 -0.99" -denominator "1 -0.99"]

set f(spath) $f(ipath)
set f(http) $f(ihttp)
set f(urlToken) ""

if {$v(p_version) != $v(s_version)} {
     set v(msg) "Warning, you have saved settings from an older version of xs!"
    SetDefaultVars
}

# Put custom settings between the lines below
# Custom settings start here
# Custom settings end here

snack::menuInit
snack::menuPane File
snack::menuCommand File {Open...} GetOpenFileName
snack::menuBind . o File {Open...}
snack::menuCommand File {Get URL...} OpenGetURLWindow
snack::menuCommand File Save Save
snack::menuBind . s File Save
snack::menuCommand File {Save As...} SaveAs
snack::menuCommand File Close Close
snack::menuSeparator File
snack::menuCommand File Print... {Print .cf.fc.c -1}
snack::menuCommand File Info {set v(msg) [InfoStr nopath]}
snack::menuSeparator File
if [info exists recentFiles] {
    foreach e $recentFiles {
	snack::menuCommand File $e [list OpenFiles $e]
    }
    snack::menuSeparator File
}
snack::menuCommand File Exit Exit

snack::menuPane Edit 0 ConfigEditMenu
snack::menuCommand Edit Undo Undo
snack::menuEntryOff Edit Undo
snack::menuSeparator Edit
snack::menuCommand Edit Cut Cut
snack::menuBind . x Edit Cut
snack::menuCommand Edit Copy Copy
snack::menuBind . c Edit Copy
snack::menuCommand Edit Paste Paste
snack::menuBind . v Edit Paste
snack::menuCommand Edit Crop Crop
snack::menuCommand Edit {Mark All} MarkAll
snack::menuCommand Edit {Zero Cross Adjust} ZeroXAdjust

set n [snack::menuPane Audio]
bind $n <<MenuSelect>> { snack::mixer update }
snack::menuCommand Audio {Play range} PlayMark
snack::menuCommand Audio {Play All} PlayAll
snack::menuBind . p Audio {Play All}
snack::menuCommand Audio {Stop Play} StopPlay
#snack::menuCommand Audio {Gain Control...} {snack::gainBox rp}
snack::menuCommand Audio Mixer... snack::mixerDialog
#if {[snack::mixer inputs] != ""} {
#    snack::menuCascade Audio Input
#    foreach jack [snack::mixer inputs] {
#	snack::mixer input $jack v(in$jack)
#	snack::menuCheck Input $jack v(in$jack)
#    }
#}
#if {[snack::mixer outputs] != ""} {
#    snack::menuCascade Audio Output
#    foreach jack [snack::mixer outputs] {
#	snack::mixer output $jack v(out$jack)
#	snack::menuCheck Output $jack v(out$jack)
#    }
#}
snack::menuCascade Audio {Audio Settings}
snack::menuCascade {Audio Settings} {Set Sample Rate}
set rateList [snack::audio rates]
if {$rateList == ""} {
    set rateList {11025 22050 44100}
}
foreach fr $rateList {
    snack::menuRadio {Set Sample Rate} $fr v(rate) $fr SetRaw
}
snack::menuCascade {Audio Settings} {Set Encoding}
foreach fo [snack::audio encodings] {
    snack::menuRadio {Set Encoding} $fo v(sfmt) $fo SetRaw
}
snack::menuCascade {Audio Settings} {Set Channels}
snack::menuRadio {Set Channels} Mono   v(chan) 1 SetRaw
snack::menuRadio {Set Channels} Stereo v(chan) 2 SetRaw

snack::menuPane Transform 0 ConfigTransformMenu
snack::menuCascade Transform Conversions
snack::menuCascade Conversions {Convert Sample Rate}
foreach fr $rateList {
    snack::menuCommand {Convert Sample Rate} $fr "Convert {} $fr {}"
}
snack::menuCascade Conversions {Convert Encoding}
foreach fo [snack::audio encodings] {
    snack::menuCommand {Convert Encoding} $fo "Convert $fo {} {}"
}
snack::menuCascade Conversions {Convert Channels}
snack::menuCommand {Convert Channels} Mono   "Convert {} {} Mono"
snack::menuCommand {Convert Channels} Stereo "Convert {} {} Stereo"
snack::menuCommand Transform Amplify... Amplify
snack::menuCommand Transform Normalize... Normalize
#snack::menuCommand Transform Normalize... Normalize
snack::menuCommand Transform Echo... Echo
snack::menuCommand Transform {Mix Channels...} MixChan
snack::menuCommand Transform Invert Invert
snack::menuCommand Transform Reverse Reverse
snack::menuCommand Transform Silence Silence
snack::menuCommand Transform {Remove DC} RemoveDC

snack::menuPane Tools

snack::menuPane Options 0 ConfigOptionsMenu
snack::menuCommand Options Settings... Settings
if {[info exists snack::snackogg]} {
  snack::menuCommand Options "Ogg Vorbis..." [list OggSettings Close]
}
snack::menuCommand Options Plug-ins... Plugins
snack::menuCascade Options {Label File Format}
snack::menuRadio {Label File Format} TIMIT v(labfmt) TIMIT {Redraw quick}
snack::menuRadio {Label File Format} HTK v(labfmt) HTK {Redraw quick}
snack::menuRadio {Label File Format} WAVES v(labfmt) WAVES {Redraw quick}
snack::menuRadio {Label File Format} MIX v(labfmt) MIX {Redraw quick}
if $local {
    snack::menuCascade Options {IPA Translation}
    snack::menuRadio {IPA Translation} TMH v(ipafmt) TMH {source $mexhome/ipa_tmh.tcl;Redraw quick}
    snack::menuRadio {IPA Translation} CMU v(ipafmt) CMU {source $mexhome/ipa_cmu.tcl;Redraw quick}
}
snack::menuCascade Options {Label Alignment}
snack::menuRadio {Label Alignment} left v(labalign)   w {Redraw quick}
snack::menuRadio {Label Alignment} center v(labalign) c {Redraw quick}
snack::menuRadio {Label Alignment} right v(labalign)  e {Redraw quick}
snack::menuCascade Options {View Channel}
snack::menuRadio {View Channel} both v(vchan) -1 { Redraw;DrawZoom 1;DrawSect }
snack::menuRadio {View Channel} left v(vchan) 0  { Redraw;DrawZoom 1;DrawSect }
snack::menuRadio {View Channel} right v(vchan) 1 { Redraw;DrawZoom 1;DrawSect }
snack::menuSeparator Options
if $local {
    snack::menuCheck Options {IPA Transcription} v(ipa) {Redraw quick}
}
snack::menuCheck Options {Record Button} v(recording) ToggleRecording
snack::menuCheck Options {Show Spectrogram} v(showspeg) ToggleSpeg
snack::menuCheck Options {Auto Load} v(autoload)
snack::menuCheck Options {Cross Hairs} v(ch) DrawCrossHairs
snack::menuCheck Options {Fill Between Marks} v(fillmark) {$c coords mfill -1 -1 -1 -1 ; Redraw quick}
snack::menuCheck Options {Link to Disk File} v(linkfile) Link2File
if {$tcl_platform(platform) == "unix"} {
    snack::menuCheck Options {Link Scroll} v(slink)
    snack::menuCheck Options {Link Marks} v(mlink)
}
#snack::menuCheck Options {Align x-axis/first label} v(offset) {Redraw quick}
#snack::menuCheck Options {Show zero length labels} v(zerolabs) {Redraw quick}
snack::menuSeparator Options
snack::menuCommand Options {Set default options} {SetDefaultVars ; Redraw}
snack::menuCommand Options {Save options} SaveSettings

snack::menuPane Window
snack::menuCommand Window {New Window} NewWin
snack::menuBind . n Window {New Window}
snack::menuCommand Window Refresh Redraw
snack::menuBind . r Window Refresh
snack::menuCommand Window {Waveform Zoom} OpenZoomWindow
snack::menuCommand Window {Spectrum Section} OpenSectWindow
#snack::menuCommand Window {WaveSurfer} WS

snack::menuPane Help
snack::menuCommand Help Version Version
snack::menuCommand Help Manual  {Help http://www.speech.kth.se/snack/xs.html}

# Put custom menus between the lines below
# Custom menus start here
# Custom menus end here

#bind Menu <<MenuSelect>> {
#    global v
#    if {[catch {%W entrycget active -label} label]} {
#	set label ""
#    }
#    set v(msg) $label
#    update idletasks
#}

if {$tcl_platform(platform) == "windows"} {
    set border 1
} else {
    set border 0
}

snack::createIcons
pack [frame .tb -highlightthickness 1] -anchor w
pack [button .tb.open -command GetOpenFileName -image snackOpen -highlightthickness 0 -border $border] -side left

pack [button .tb.save -command Save -image snackSave -highlightthickness 0 -border $border] -side left
pack [button .tb.print -command {Print .cf.fc.c -1} -image snackPrint -highlightthickness 0 -border $border] -side left

pack [frame .tb.f1 -width 1 -height 20 -highlightth 1] -side left -padx 5
pack [button .tb.cut -command Cut -image snackCut -highlightthickness 0 -border $border] -side left
pack [button .tb.copy -command Copy -image snackCopy -highlightthickness 0 -border $border] -side left
pack [button .tb.paste -command Paste -image snackPaste -highlightthickness 0 -border $border] -side left

pack [frame .tb.f2 -width 1 -height 20 -highlightth 1] -side left -padx 5
pack [button .tb.undo -command Undo -image snackUndo -highlightthickness 0 -border $border -state disabled] -side left

pack [frame .tb.f3 -width 1 -height 20 -highlightth 1] -side left -padx 5
pack [button .tb.play -command PlayMark -bitmap snackPlay -fg blue3 -highlightthickness 0 -border $border] -side left
bind .tb.play <Enter> {SetMsg "Play mark"}
pack [button .tb.pause -command PausePlay -bitmap snackPause -fg blue3 -highlightthickness 0 -border $border] -side left
bind .tb.pause <Enter> {SetMsg "Pause"}
pack [button .tb.stop -command StopPlay -bitmap snackStop -fg blue3 -highlightthickness 0 -border $border] -side left
bind .tb.stop <Enter> {SetMsg "Stop"}
pack [button .tb.rec -command Record -bitmap snackRecord -fg red -highlightthickness 0 -border $border] -side left
bind .tb.rec <Enter> {SetMsg "Record"}
#pack [button .tb.gain -command {snack::gainBox rp} -image snackGain -highlightthickness 0 -border $border] -side left
pack [button .tb.gain -command snack::mixerDialog -image snackGain -highlightthickness 0 -border $border] -side left
bind .tb.gain <Enter> {SetMsg "Open gain control panel"}

pack [frame .tb.f4 -width 1 -height 20 -highlightth 1] -side left -padx 5
pack [button .tb.zoom -command OpenZoomWindow -image snackZoom -highlightthickness 0 -border $border] -side left
bind .tb.zoom <Enter> {SetMsg "Open zoom window"}

frame .of
pack [canvas .of.c -width $v(width) -height 30 -bg $v(bg)] -fill x -expand true
pack [scrollbar .of.xscroll -orient horizontal -command ScrollCmd] -fill x -expand true
bind .of.xscroll <ButtonPress-1> { set v(scroll) 1 }
bind .of.xscroll <ButtonRelease-1> RePos
bind .of.c <1> {OverPlay %x}

pack [ frame .bf] -side bottom -fill x
entry .bf.lab -textvar v(msg) -width 1 -relief sunken -bd 1 -state disabled
pack .bf.lab -side left -expand yes -fill x

set v(toth) [expr $v(waveh) + $v(spegh) + $v(timeh)+ $v(labelh)]
pack [ frame .cf] -fill both -expand true
pack [ frame .cf.fyc] -side left -anchor n
canvas .cf.fyc.yc2 -height 0 -width $v(yaxisw) -highlightthickness 0
pack [ canvas .cf.fyc.yc -width $v(yaxisw) -height $v(toth) -highlightthickness 0 -bg $v(bg)]

pack [ frame .cf.fc] -side left -fill both -expand true
set c [canvas .cf.fc.c -width $v(width) -height $v(toth) -xscrollcommand [list .cf.fc.xscroll set] -yscrollcommand [list .cf.fc.yscroll set] -closeenough 5 -highlightthickness 0 -bg $v(bg)]
scrollbar .cf.fc.xscroll -orient horizontal -command [list $c xview]
scrollbar .cf.fc.yscroll -orient vertical -command yScroll
#pack .cf.fc.xscroll -side bottom -fill x
#pack .cf.fc.yscroll -side right -fill y
pack $c -side left -fill both -expand true

proc yScroll {args} {
    global c

    eval .cf.fyc.yc yview $args
    eval $c yview $args
}

$c create rect -1 -1 -1 -1 -tags mfill -fill yellow -stipple gray25
$c create line -1 0 -1 $v(toth) -width 1 -tags [list mark [expr 0 * $v(rate)/$v(pps)] m1] -fill $v(fg)
$c create line -1 0 -1 $v(toth) -width 1 -tags [list mark [expr 0 * $v(rate)/$v(pps)] m2] -fill $v(fg)

bind all <Control-l> {
    set n 0
    if {$labels == {}} return
    while {[lindex [$c coords lab$n] 0] < [expr $v(width) * [lindex [$c xview] 0]]} { incr n }

    $c focus lab$n
    focus $c
    $c icursor lab$n 0
    set i 0
    SetMsg [lindex $labels $i] $i
    SetUndo $labels
}

$c bind text <Control-p> {
    set __x [lindex [%W coords [%W focus]] 0]
    set __y [lindex [%W coords [%W focus]] 1]
    set __n [lindex [$c gettags [$c find closest $__x $__y]] 0]
    PlayNthLab $__n
    break
}

$c bind text <Button-1> {
    %W focus current
    %W icursor current @[$c canvasx %x],[$c canvasy %y]
    set i [lindex [$c gettags [%W focus]] 0]
    SetMsg [lindex $labels $i] $i
    SetUndo $labels
}

event add <<Delete>> <Delete>
catch {event add <<Delete>> <hpDeleteChar>}

$c bind text <<Delete>> {
    if {[%W focus] != {}} {
	%W dchars [%W focus] insert
	SetLabelText [lindex [$c gettags [%W focus]] 0] [$c itemcget [%W focus] -text]
	set i [lindex [$c gettags [%W focus]] 0]
	SetMsg [lindex $labels $i] $i
    }
}

$c bind text <BackSpace> {
    if {[%W focus] != {}} {
	set _tmp [%W focus]
	set _ind [expr [%W index $_tmp insert]-1]
	if {$_ind >= 0} {
	    %W icursor $_tmp $_ind
	    %W dchars $_tmp insert
	    SetLabelText [lindex [$c gettags [%W focus]] 0] [$c itemcget [%W focus] -text]
	    set i [lindex [$c gettags [%W focus]] 0]
	    SetMsg [lindex $labels $i] $i
	}
	unset _tmp _ind
    }
}

$c bind text <Return> {
    %W insert current insert ""
    %W focus {}
}

$c bind text <Enter> {
    %W insert current insert ""
    %W focus {}
}

$c bind text <Control-Any-Key> { break }

$c bind text <Any-Key> {
    if {[%W focus] != {}} {
	%W insert [%W focus] insert %A
	SetLabelText [lindex [$c gettags [%W focus]] 0] [$c itemcget [%W focus] -text]
	set i [lindex [$c gettags [%W focus]] 0]
	SetMsg [lindex $labels $i] $i
    }
    set v(labchanged) 1
}

$c bind text <space> {
    if {[%W focus] != {}} {
	%W insert [%W focus] insert _
	SetLabelText [lindex [$c gettags [%W focus]] 0] [$c itemcget [%W focus] -text]
	set i [lindex [$c gettags [%W focus]] 0]
	SetMsg [lindex $labels $i] $i
    }
}

$c bind text <Key-Right> {
    if {[%W focus] != {}} {
	set __index [%W index [%W focus] insert]
	%W icursor [%W focus] [expr $__index + 1]
	if {$__index == [%W index [%W focus] insert]} {
            set __focus [expr [lindex [$c gettags [%W focus]] 0] + 1]
	    %W focus lab$__focus
	    %W icursor lab$__focus 0
	    set i [lindex [$c gettags [%W focus]] 0]
	    SetMsg [lindex $labels $i] $i
	    while {[expr $v(width) * [lindex [$c xview] 1] -10] < [lindex [%W coords [%W focus]] 0] && [lindex [$c xview] 1] < 1} {
		$c xview scroll 1 unit
	    }
	}
    }
}

$c bind text <Key-Left> {
    if {[%W focus] != {}} {
	set __index [%W index [%W focus] insert]
	%W icursor [%W focus] [expr [%W index [%W focus] insert] - 1]
	if {$__index == [%W index [%W focus] insert]} {
            set __focus [expr [lindex [$c gettags [%W focus]] 0] - 1]
	    %W focus lab$__focus
	    %W icursor lab$__focus end
	    set i [lindex [$c gettags [%W focus]] 0]
	    SetMsg [lindex $labels $i] $i
	    while {[expr $v(width) * [lindex [$c xview] 0] +10] > [lindex [%W coords [%W focus]] 0] && [lindex [$c xview] 0] > 0} {
		$c xview scroll -1 unit
	    }
	}
    }
}

set _mx 1
set _mb 0
#$c bind bound  <B1-Motion> { MoveBoundary %x }
$c bind bound  <ButtonRelease-1> { set _mb 0 ; Redraw quick }
$c bind m1     <B1-Motion> { PutMarker m1 %x %y 1 }
$c bind m2     <B1-Motion> { PutMarker m2 %x %y 1 }
$c bind m1     <ButtonPress-1>   { set _mx 0 }
$c bind m2     <ButtonPress-1>   { set _mx 0 }
$c bind obj    <ButtonPress-1> { PutMarker m1 %x %y 1 }
$c bind obj    <B1-Motion>     { PutMarker m2 %x %y 1 }
$c bind m1     <ButtonRelease-1> { SendPutMarker m1 %x ; set _mx 0 }
$c bind m2     <ButtonRelease-1> { SendPutMarker m2 %x ; set _mx 0 }
$c bind bound  <Any-Enter> { BoundaryEnter %x }
$c bind mark   <Any-Enter> { MarkerEnter %x }
$c bind bound  <Any-Leave> { BoundaryLeave %x }
$c bind mark   <Any-Leave> { MarkerLeave %x }

bind $c <ButtonPress-1>   {
    if {%y > [expr $v(waveh)+$v(spegh)+$v(timeh)]} {
    } else {
	PutMarker m1 %x %y 1
	SendPutMarker m1 %x
	set _mx 1
    }
}

bind $c <ButtonRelease-1> {
    set _mb 0
    if {%y > [expr $v(waveh)+$v(spegh)+$v(timeh)]} {
	focus %W
	if {[%W find overlapping [expr [$c canvasx %x]-2] [expr [$c canvasy %y]-2] [expr [$c canvasx %x]+2] [expr [$c canvasy %y]+2]] == {}} {
	    %W focus {}
	}
    } else {
	PutMarker m2 %x %y 1
	SendPutMarker m2 %x
	set _mx 1
    }
}
bind $c <Delete> Cut
bind $c <Motion> { PutCrossHairs %x %y }
bind $c <Leave>  {
    $c coords ch1 -1 -1 -1 -1
    $c coords ch2 -1 -1 -1 -1
}

if {[string match macintosh $::tcl_platform(platform)] || \
	[string match Darwin $::tcl_platform(os)]} {
 bind $c <Control-1> { PopUpMenu %X %Y %x %y }
} else {
 bind $c <3> { PopUpMenu %X %Y %x %y }
}

bind .cf.fc.xscroll <ButtonRelease-1> SendXScroll
bind .bf.lab <Any-KeyRelease> { InputFromMsgLine %K }
bind all <Control-c> Exit
wm protocol . WM_DELETE_WINDOW Exit
bind .cf.fc.c <Configure> { if {"%W" == ".cf.fc.c"} Reconf }
bind $c <F1> { PlayToCursor %x }
bind $c <2>  { PlayToCursor %x }
focus $c

proc RecentFile fn {
    global recentFiles

    if {$fn == ""} return
    if [info exists recentFiles] {
	foreach e $recentFiles {
	    snack::menuDelete File $e
	}
	snack::menuDeleteByIndex File 10
    } else {
	set recentFiles {}
    }
    snack::menuDelete File Exit
    set index [lsearch -exact $recentFiles $fn]
    if {$index != -1} {
	set recentFiles [lreplace $recentFiles $index $index]
    }
    set recentFiles [linsert $recentFiles 0 $fn]
    if {[llength $recentFiles] > 6} {
	set recentFiles [lreplace $recentFiles 6 end]
    }
    foreach e $recentFiles {
	snack::menuCommand File $e [list OpenFiles $e]
    }
    snack::menuSeparator File
    snack::menuCommand File Exit Exit
    if [catch {open [file join ~ .xsrf] w} out] {
    } else {
	puts $out "set recentFiles \[list $recentFiles\]"
	close $out
    }
}

set extTypes  [list {TIMIT .phn} {MIX .smp.mix} {HTK .lab} {WAVES .lab}]
set loadTypes [list {{MIX Files} {.mix}} {{HTK Label Files} {.lab}} {{TIMIT Label Files} {.phn}} {{TIMIT Label Files} {.wrd}} {{Waves Label Files} {.lab}}]
set loadKeys [list MIX HTK TIMIT WAVES]
set saveTypes {}
set saveKeys  {}

if {[info exists snack::snacksphere]} {
    lappend extTypes {SPHERE .sph} {SPHERE .wav}
    lappend loadTypes {{SPHERE Files} {.sph}} {{SPHERE Files} {.wav}}
    lappend loadKeys SPHERE SPHERE
}
if {[info exists snack::snackogg]} {
  lappend extTypes  {OGG .ogg}
  lappend loadTypes {{Ogg Vorbis Files} {.ogg}}
  lappend loadKeys  OGG
  lappend saveTypes {{Ogg Vorbis Files} {.ogg}}
  lappend saveKeys  OGG
  
  proc OggSettings {text} {
    set w .ogg
    catch {destroy $w}
    toplevel $w
    wm title $w "Ogg Vorbis Settings"

    pack [frame $w.f1] -anchor w
    pack [label $w.f1.l -text "Nominal bitrate:" -widt 16 -anchor w] -side left
    pack [entry $w.f1.e -textvar ::ogg(nombr) -wi 7] -side left

    pack [frame $w.f2] -anchor w
    pack [label $w.f2.l -text "Max bitrate:" -width 16 -anchor w] -side left
    pack [entry $w.f2.e -textvar ::ogg(maxbr) -wi 7] -side left

    pack [frame $w.f3] -anchor w
    pack [label $w.f3.l -text "Min bitrate:" -width 16 -anchor w] -side left
    pack [entry $w.f3.e -textvar ::ogg(minbr) -wi 7] -side left
    
    pack [frame $w.f4] -anchor w
    pack [label $w.f4.l -text "Comment:" -width 16 -anchor w] -side left
    pack [entry $w.f4.e -textvar ::ogg(com) -wi 40] -side left

    pack [frame $w.f5] -anchor w
    pack [checkbutton $w.f5.b -text "Query settings before saving" \
	-variable ::ogg(query) -anchor w] -side left

    pack [frame $w.fb] -side bottom -fill x
    pack [button $w.fb.cb -text $text -command "destroy $w"] -side top
  }
}

snack::addExtTypes $extTypes
snack::addLoadTypes $loadTypes $loadKeys

proc GetOpenFileName {} {
    global f v

    if {$v(smpchanged) || $v(labchanged)} {
	if {[tk_messageBox -message "You have unsaved changes.\n Do you \
		really want to close?" -type yesno \
		-icon question] == "no"} return
    }

    set gotfn [snack::getOpenFile -initialdir $f(spath) \
	    -initialfile $f(sndfile) -format $v(smpfmt)]

    # Ugly hack for Tk8.0
    if {$gotfn != ""} {
	set tmp [file split $gotfn]
	if {[lindex $tmp 0] == [lindex $tmp 1]} {
	    set tmp [lreplace $tmp 0 0]
	    set gotfn [eval file join $tmp]
	}
    }
    update
    if [string compare $gotfn ""] {
	OpenFiles $gotfn
    }
}

proc GetSaveFileName {title} {
    global f v labels

    if {$labels != {} && [string compare $title "Save sample file"] != 0} {  
	switch $v(labfmt) {
	    MIX {
	      lappend ::saveTypes {{MIX Files} {.mix}}
	      lappend ::saveKeys  MIX
	    }
	    HTK {
	      lappend ::saveTypes {{HTK Label Files} {.lab}}
	      lappend ::saveKeys  HTK
	    }
	    TIMIT {
	      lappend ::saveTypes {{TIMIT Label Files} {.phn}} {{TIMIT Label Files} {.wrd}}
	      lappend ::saveKeys  TIMIT
	    }
	    WAVES {
	      lappend ::saveTypes {{Waves Label Files} {.lab}}
	      lappend ::saveKeys  WAVES
	    }
	    default
	}
	snack::addSaveTypes $::saveTypes $::saveKeys

	set gotfn [snack::getSaveFile -initialdir $f(lpath) -initialfile $f(labfile) -format $v(labfmt) -title $title]
 } else {
	snack::addSaveTypes $::saveTypes $::saveKeys

	set gotfn [snack::getSaveFile -initialdir $f(spath) -initialfile $f(sndfile) -format $v(smpfmt) -title $title]
    }
#    set tmp [string trimright $f(lpath) /].
#    if {[regexp $tmp $gotfn] == 1 && $tmp != "."} {
#	return ""
#    }
    update
    return $gotfn
}

proc SaveAs {} {
    set gotfn [GetSaveFileName ""]
    if {[string compare $gotfn ""] != 0} {
	SaveFile $gotfn
    }
}

proc Save {} {
    global f v

    set fn $f(spath)$f(sndfile)
    if {[string compare $f(spath)$f(sndfile) ""] == 0} {
	set fn [GetSaveFileName "Save sample file"]
    }
    if {$fn != "" && $v(smpchanged)} {
	SaveFile $fn
    }
    if $v(labchanged) {
	set fn $f(lpath)$f(labfile)
	if {[string compare $f(lpath)$f(labfile) ""] == 0} {
	    set fn [GetSaveFileName "Save label file"]
	}
	if {$fn != ""} {
	    SaveFile $fn
	}
    }
}

proc SaveFile {{fn ""}} {
  global f v labels

  SetCursor watch
  set strip_fn [lindex [file split [file rootname $fn]] end]
  set ext  [file extension $fn]
  if [string match macintosh $::tcl_platform(platform)] {
    set path [file dirname $fn]:
  } else {
    set path [file dirname $fn]/
  }
  if {$path == "./"} { set path ""}
  if {![IsLabelFile $fn]} {
    if {[info exists snack::snackogg]} {
      if {$::ogg(query) && [string match -nocase .ogg $ext]} {
	OggSettings Continue
	tkwait window .ogg
      }
      if [catch {snd write $fn -progress snack::progressCallback \
	  -nominalbitrate $::ogg(nombr) -maxbitrate $::ogg(maxbr) \
	  -minbitrate $::ogg(minbr) -comment $::ogg(com)} msg] {
	SetMsg "Save cancelled: $msg"
      }
    } else {
      if [catch {snd write $fn -progress snack::progressCallback} msg] {
	SetMsg "Save cancelled: $msg"
      }
    }
    if {$v(linkfile)} {
	snd configure -file $fn
    }
    set v(smpchanged) 0
    wm title . "xs: $fn"
    set f(spath) $path
    set f(sndfile) $strip_fn$ext
  } elseif {$labels != {}} {
    SaveLabelFile $labels $fn
    set v(labchanged) 0
    wm title . "xs: $f(spath)$f(sndfile) - $fn"
    set f(lpath) $path
    set f(labfile) $strip_fn$ext
  }
  SetCursor ""
}

proc IsLabelFile {fn} {
    set ext [file extension $fn]
    if {$ext == ".lab"} { return 1 }
    if {$ext == ".mix"} { return 1 }
    if {$ext == ".phn"} { return 1 }
    if {$ext == ".wrd"} { return 1 }
    return 0
}

proc OpenFiles {fn} {
    global c labels v f


    if {![file readable $fn]} {
	tk_messageBox -icon warning -type ok -message "No such file: $fn"
	return
    }
    SetCursor watch
    set strip_fn [lindex [file split [file rootname $fn]] end]
    set ext  [file extension $fn]
    if [string match macintosh $::tcl_platform(platform)] {
	set path [file dirname $fn]:
    } else {
	set path [file dirname $fn]/
    }
    if {$path == "./"} { set path ""}

    if [IsLabelFile $fn] {
	set type "lab"
	set f(lpath) $path
    } else {
	set type "smp"
	set f(spath) $path
    }

    switch $ext {
	.mix {
	    set f(labfile) "$strip_fn.mix"
	    set v(labfmt) MIX
	    if $v(autoload) {
		set f(sndfile) "$strip_fn"
		if {$f(spath) == ""} { set f(spath) $f(lpath) }
		if {[file exists $f(spath)$f(sndfile)] == 0} {
		    set f(sndfile) "$strip_fn.smp"
		}
	    }
	}
	.lab {
	    set f(labfile) "$strip_fn.lab"
	    if {$v(smpfmt) == "SD"} {
		set v(labfmt) WAVES
		set v(labalign) e
		if $v(autoload) {
		    set f(sndfile) "$strip_fn.sd"
		    if {$f(spath) == ""} { set f(spath) $f(lpath) }
		}
	    } else {
		set v(labfmt) HTK
		if $v(autoload) {
		    set f(sndfile) "$strip_fn.smp"
		    if {$f(spath) == ""} { set f(spath) $f(lpath) }
		}
	    }
	}
	.phn {
	    set f(labfile) "$strip_fn.phn"
	    set v(labfmt) TIMIT
	    if $v(autoload) {
		set f(sndfile) "$strip_fn.wav"
		if {$f(spath) == ""} { set f(spath) $f(lpath) }
	    }
	}
	.wrd {
	    set f(labfile) "$strip_fn.wrd"
	    set v(labfmt) TIMIT
	    if $v(autoload) {
		set f(sndfile) "$strip_fn.wav"
		if {$f(spath) == ""} { set f(spath) $f(lpath) }
	    }
	}
	.smp {
	    set f(sndfile) "$strip_fn.smp"
	    set v(labfmt) MIX
	    if $v(autoload) {
		set f(labfile) "$strip_fn.smp.mix"
		if {$f(lpath) == ""} { set f(lpath) $f(spath) }
		if {[file exists $f(lpath)$f(labfile)] == 0} {
		    set f(labfile) "$strip_fn.mix"
		}
	    }
	}
	.wav {
	    set f(sndfile) "$strip_fn.wav"
	    set v(labfmt) TIMIT
	    if $v(autoload) {
		set f(labfile) "$strip_fn.phn"
		if {$f(lpath) == ""} { set f(lpath) $f(spath) }
	    }
	}
	.sd {
	    set f(sndfile) "$strip_fn.sd"
	    set v(labfmt) WAVES
	    if $v(autoload) {
		set f(labfile) "$strip_fn.lab"
		if {$f(lpath) == ""} { set f(lpath) $f(spath) }
	    }
	}
	.bin {
	    set f(sndfile) "$strip_fn.bin"
	    set v(labfmt) HTK
	    if $v(autoload) {
		set f(labfile) "$strip_fn.lab"
		if {$f(lpath) == ""} { set f(lpath) $f(spath) }
	    }
	}
	default {
	    if {$type == "smp"} {
		set f(sndfile) "$strip_fn$ext"
		if $v(autoload) {
		    set f(labfile) "$strip_fn$ext.mix"
		    set v(labfmt) MIX
		    if {$f(lpath) == ""} { set f(lpath) $f(spath) }
		}
	    } else {
		set f(labfile) "$strip_fn$ext"
		if $v(autoload) {
		    set f(sndfile) "$strip_fn.smp"
		    if {$f(spath) == ""} { set f(spath) $f(lpath) }
		}
	    }
	}
    }

    if {($v(autoload) == 1) || ($type == "smp")} {
	$c delete wave speg
	.of.c delete overwave
	catch {.sect.c delete sect}
	StopPlay

	set f(byteOrder) [snd cget -byteorder]
	set tmps [snack::sound -debug $::debug]
	set ffmt [$tmps read $f(spath)$f(sndfile) -end 1 -guessproperties 1]
	if {$ffmt == "RAW"} {
	    set v(rate)      [$tmps cget -rate]
	    set v(sfmt)      [$tmps cget -encoding]
	    set v(chan)      [$tmps cget -channels]
	    set f(byteOrder) [$tmps cget -byteorder]
	    if {[InterpretRawDialog] == "cancel"} {
		$tmps destroy
		SetCursor ""
		return
	    }
	}
	$tmps destroy
	if {$v(linkfile)} {
	    if [catch {snd configure -file $f(spath)$f(sndfile) \
		    -skip $f(skip) -byteorder $f(byteOrder) \
		    -rate $v(rate) -encoding $v(sfmt) -channels $v(chan) \
	    	     } ret] {
		 SetMsg "$ret"
		 return
	     }
	     set v(smpfmt) [lindex [snd info] 6]
	} else {
	    if [catch {set v(smpfmt) [snd read $f(spath)$f(sndfile) \
		    -skip $f(skip) -byteorder $f(byteOrder) \
		    -rate $v(rate) -encoding $v(sfmt) -channels $v(chan) \
		    -progress snack::progressCallback]} ret] {
		SetMsg "$ret"
		return
	    }
	}
	set v(rate) [snd cget -rate]
	set v(sfmt) [snd cget -encoding]
	set v(chan) [snd cget -channels]
	set v(startsmp) 0
	if {[snd cget -channels] == 1} {
	    set v(vchan) -1
	}
	set v(smpchanged) 0
	.tb.undo config -state disabled
	if {![regexp $v(rate) [snack::audio rates]]} {
	    tk_messageBox -icon warning -type ok -message "You need to \
		    convert this sound\nif you want to play it"
	}
    }
    if {($v(autoload) == 1) || ($type == "lab")} {
	set labels [OpenLabelFile $f(lpath)$f(labfile)]
	if {$labels == {}} { set f(labfile) "" }
    }
    if {$labels == {}} {
	wm title . "xs: $f(spath)$f(sndfile)"
    } else {
	wm title . "xs: $f(spath)$f(sndfile) - $f(lpath)$f(labfile)"
    }

    if {[snd length -unit seconds] > 50 && $v(pps) > 100} {
	set v(pps) [expr $v(pps)/10]
    }
    if {[snd length -unit seconds] < 50 && $v(pps) < 100} {
	set v(pps) [expr $v(pps)*10]
    }
    wm geometry . {}
    Redraw
    event generate .cf.fc.c <Configure>
    SetMsg [InfoStr nopath]
#    MarkAll
    RecentFile $f(spath)$f(sndfile)
}

proc InterpretRawDialog {} {
    global f v

    set w .rawDialog
    toplevel $w -class Dialog
    frame $w.q
    pack $w.q -expand 1 -fill both -side top
    pack [frame $w.q.f1] -side left -anchor nw -padx 3m -pady 2m
    pack [frame $w.q.f2] -side left -anchor nw -padx 3m -pady 2m
    pack [frame $w.q.f3] -side left -anchor nw -padx 3m -pady 2m
    pack [frame $w.q.f4] -side left -anchor nw -padx 3m -pady 2m
    pack [label $w.q.f1.l -text "Sample Rate"]
    foreach e [snack::audio rates] {
	pack [radiobutton $w.q.f1.r$e -text $e -val $e -var ::v(rate)]\
		-anchor w
    }
    pack [label $w.q.f2.l -text "Sample Encoding"]
    foreach e [snack::audio encodings] {
	pack [radiobutton $w.q.f2.r$e -text $e -val $e -var ::v(sfmt)]\
		-anchor w
    }
    pack [label $w.q.f3.l -text Channels]
    pack [radiobutton $w.q.f3.r1 -text Mono -val 1 -var ::v(chan)] -anchor w
    pack [radiobutton $w.q.f3.r2 -text Stereo -val 2 -var ::v(chan)] -anchor w
    pack [radiobutton $w.q.f3.r4 -text 4 -val 4 -var ::v(chan)] -anchor w
    pack [entry $w.q.f3.e -textvariable ::v(chan) -width 3] -anchor w
    pack [label $w.q.f4.l -text "Byte Order"]
    pack [radiobutton $w.q.f4.ri -text "Little Endian\n(Intel)" \
	    -value littleEndian -var ::f(byteOrder)] -anchor w
    pack [radiobutton $w.q.f4.rm -text "Big Endian\n(Motorola)" \
	    -value bigEndian -var ::f(byteOrder)] -anchor w
    pack [label $w.q.f4.l2 -text "\nRead Offset (bytes)"]
    pack [entry $w.q.f4.e -textvar f(skip) -wi 6]
    snack::makeDialogBox $w -title "Interpret Raw File As" -type okcancel \
	-default ok
}

proc Link2File {} {
    global f v

    StopPlay
    if {$v(smpchanged)} {
	if {[tk_messageBox -message "You have unsaved changes.\n Do you \
		really want to loose them?" -type yesno \
		-icon question] == "no"} return
    }
    set v(smpchanged) 0
    if {$v(linkfile)} {
	.of.c delete overwave
	catch {.sect.c delete sect}
	if {$f(sndfile) == ""} {
	    snd configure -file _xs[pid].wav
	} else {
	    snd configure -file $f(spath)$f(sndfile)
	}
	cbs configure -file ""
    } else {
	if {$f(sndfile) == ""} {
	    snd config -load ""
	} else {
	    snd config -load $f(spath)$f(sndfile)
	}
	cbs config -load ""
    }
}

proc ConfigEditMenu {} {
    global v

    if {$v(linkfile)} {
	snack::menuEntryOff Edit Cut
	snack::menuEntryOff Edit Copy
	snack::menuEntryOff Edit Paste
	snack::menuEntryOff Edit Crop
    } else {
	snack::menuEntryOn Edit Cut
	snack::menuEntryOn Edit Copy
	snack::menuEntryOn Edit Paste
	snack::menuEntryOn Edit Crop
    }
    if {$v(smpchanged)} {
	snack::menuEntryOn Edit Undo
    } else {
	snack::menuEntryOff Edit Undo
    }
}

proc ConfigTransformMenu {} {
    global v

    if {$v(linkfile)} {
	snack::menuEntryOff Transform Conversions
	snack::menuEntryOff Transform Amplify...
	snack::menuEntryOff Transform Normalize...
	snack::menuEntryOff Transform Echo...
	snack::menuEntryOff Transform {Mix Channels...}
	snack::menuEntryOff Transform Invert
	snack::menuEntryOff Transform Reverse
	snack::menuEntryOff Transform Silence
	snack::menuEntryOff Transform {Remove DC}
    } else {
	snack::menuEntryOn Transform Conversions
	snack::menuEntryOn Transform Amplify...
	snack::menuEntryOn Transform Normalize...
	snack::menuEntryOn Transform Echo...
	snack::menuEntryOn Transform {Mix Channels...}
	snack::menuEntryOn Transform Invert
	snack::menuEntryOn Transform Reverse
	snack::menuEntryOn Transform Silence
	snack::menuEntryOn Transform {Remove DC}
    }
    if {[snd cget -channels] == 1} {
	snack::menuEntryOff Transform {Mix Channels...}
    }
}

proc ConfigOptionsMenu {} {
    global v
    
    if {[snd cget -channels] == 1} {
	snack::menuEntryOff Options {View Channel}
    } else {
	snack::menuEntryOn Options {View Channel}
    }
}

proc OpenLabelFile {fn} {
    global f v undo

    if [catch {open $fn} in] {
	SetMsg $in
	return {}
    } else {
	if [catch {set labelfile [read $in]}] { return {} }
	set l {}
	set undo {}
	set v(labchanged) 0
	.tb.undo config -state disabled
	close $in
	switch $v(labfmt) {
	    TIMIT -
	    HTK {
		foreach row [split $labelfile \n] {
		    set rest ""
