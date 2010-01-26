#!/bin/sh
# the next line restarts using wish \
exec tclsh "$0" "$@"

foreach s $argv {
    set f [open $s]
    set t [read $f]
    close $f
    
    if {[regexp -line {(package provide)(\s+)(\S+)(\s+)(\S+)} $t m0 m1 m2 pkg m4 ver]} {
	    puts stderr "$s: $pkg $ver"
	    lappend x($pkg,$ver) -source [file tail $s]
	} else {
	    puts stderr "$s: (no package)"
	}
}

puts "# Automatically generated package index file"
puts "# date   : [clock format [clock seconds]]"
puts "# cmdline: $argv0 $argv"
foreach key [array names x] {
 foreach {pkg ver} [split $key ,] break
 puts [eval pkg::create -name $pkg -version $ver $x($key)]
}

