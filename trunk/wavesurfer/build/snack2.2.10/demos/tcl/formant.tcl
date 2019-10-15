#!/bin/sh
# the next line restarts using wish \
exec wish8.3 "$0" "$@"

package require -exact snack 2.2

# there is no way (?) to find out from Tk if we can display UNICODE IPA
# but it seems to be standard on windows installations
if {[string match windows $tcl_platform(platform)]} {set UNICODE_IPA 1}

switch $tcl_platform(platform) {
 windows {
  proc milliseconds { } {clock clicks}
 }
 unix {
  proc milliseconds { } {expr {[clock clicks]/1000}}
 }
}


set vowels(sw) {
 O: u      300 600 2350 3250
 O  \u028a 350 700 2600 3200
