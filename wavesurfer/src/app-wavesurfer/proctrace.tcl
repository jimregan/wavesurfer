# proctrace.tcl - debugging utility for tcl scripts
# Jonas Beskow 2000
#
# What does proctrace do?
#
# Proctrace redefines tcl's proc-command to aid debugging of tcl programs.
# It has a trace facility, that prints the name and arguments of each procedure
# as it is invoked. It also includes a facility for general debugging 
# printouts, using "debug comments" (see below)
# tracing and debugging printouts can be switched off and on on a per procedure
# basis, by setting the element ::proctrace::p($proc) to 0 or 1 respectively
#
# How is proctrace used?
#
# At the top of your main program, source the file proctrace.tcl
# All procs defined after this point will be "traceable" by default.
# At any point in your code, you can add "debug comments". Debug comments use 
# the following syntax: 
# #<< string-to-be-printed 
# they are internally converted by proctrace to printout statements 
# that are subject to the same per-procedure on/off switching as the traces.
#
# You can bring up a GUI that allows you to select at runtime what 
# procedures you want to trace, by calling proctrace::showTraceGUI

package provide proctrace 1.0

namespace eval ::proctrace {
 variable p
 variable lbindex
 variable match
 variable prefsfile
 set prefsfile $::env(HOME)/.proctrace
 set match ""
}

rename proc ::proctrace::_proc

::proctrace::_proc ::proc {name arglist body} {
 set ss "\[string repeat { } \[expr \[info level\]-1\]\]"
 set ss2 "if \{\[info exists ::proctrace::p($name)\]"
 set cmd "if \{\$::proctrace::p($name)\} \{puts $ss\[info level 0\]\}"
# set cmd "::proctrace::print \"\[info level 0\]\""
 regsub -all #<< $body "::proctrace::print $name" body
 if {![info exists ::proctrace::p($name)]} {
  set ::proctrace::p($name) 0
 }
 uplevel [list ::proctrace::_proc $name $arglist \n$cmd\n$body]
}

proc proctrace::addMenuEntries {m} {
 $m add command -label "Trace procedure calls" -command [namespace code showTraceGUI]
}

proc proctrace::showTraceGUI {} {
 variable p
 variable lbindex
 set w .proctrace
 if {![winfo exists $w]} {
  toplevel $w
  pack [frame $w.f2] -side bottom
  pack [entry $w.f2.e -textvariable ::proctrace::match] -side left
  pack [button $w.f2.b -text Match -command \
    [namespace code [list match $w.f1.lb]]] -side left
  pack [frame $w.f1]
  listbox $w.f1.lb -yscrollcommand [list $w.f1.sb set] -selectmode extended -height 30 -width 30 -exportselection 0 ;#-font "courier 9"
  scrollbar $w.f1.sb -orient vertical -command [list $w.f1.lb yview]
  pack $w.f1.sb -side right -expand 1 -fill y
  pack $w.f1.lb -side right -expand 1 -fill both
 }

 readPrefs
 set i 0
 $w.f1.lb delete 0 end
 foreach proc [lsort [array names p]] {
  $w.f1.lb insert end $proc
  set lbindex($i) $proc
  if {$p($proc)} {
   $w.f1.lb selection set $i
  }
  incr i
 }
 bind $w.f1.lb <<ListboxSelect>> [namespace code [list updateArray $w.f1.lb]]
}

proc proctrace::match {lb} {
 variable p
 $lb selection clear 0 end
 for {set i 0} {$i < [$lb size]} {incr i} {
  if {[string match $::proctrace::match [$lb get $i]]} {
   $lb selection set $i
  }
 }
 updateArray $lb
}

proc proctrace::updateArray {lb} {
 variable p
 variable lbindex
 
 foreach i [array names lbindex] {
  set p($lbindex($i)) [$lb selection includes $i]
 }
 writePrefs
}

proc proctrace::readPrefs {} {
 variable p
 variable prefsfile

 if {[file exists $prefsfile]} {
  source $prefsfile
 }
}

proc proctrace::writePrefs {} {

 variable p
 variable prefsfile
 set f [open $prefsfile w]
 foreach proc [lsort [array names p]] {
  if {$p($proc)} {
   puts $f "set p($proc) 1"
  }
 }
 close $f
}

proc proctrace::print {proc msg} {
 variable p
 if {$p($proc)} {
  puts [string repeat " " [info level]]$msg
 }
}

proc proctrace::configureSnackDebug {} {
  foreach widget $::wsurf::Info(widgets) {
    [$widget cget -sound] configure -debug $::wsurf::Info(debug)
  }
}
