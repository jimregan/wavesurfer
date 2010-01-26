
if {[string first "-psn" [lindex $argv 0]] == 0} { set argv [lrange $argv 1 end]}

if [catch {source [file join [file dirname [info script]] app-wavesurfer/wavesurfer.tcl]}] { puts $errorInfo}

