set insttype system

if {$insttype=="system" && ![file writable /usr/share/applications/]} {
    puts "no permission for system installation, doing user installation instead"
    set insttype user
}

switch $insttype {
    user {
	set desktopfile $::env(HOME)/.gnome2/vfolders/applications/wavesurfer.desktop
	set iconfile $::env(HOME)/.icons/gnome/64x64/apps/wavesurfer.png
	set execpath $::env(HOME)/bin/wavesurfer
    }
    system {
	set desktopfile /usr/share/applications/wavesurfer.desktop 
	set iconfile  /usr/share/pixmaps/wavesurfer.png
	set execpath /usr/local/bin/wavesurfer
    }
    default {error "what?";exit}
}

set top [file normalize [file dirname [info script]]/..]

puts "installing executable..."
exec cp /tmp/wavesurfer-linux-i386 $execpath
exec chmod a+x $execpath

puts "creating menu entires..."

set desktopdata "\[Desktop Entry\]
Name=WaveSurfer
Comment=WaveSurfer is an open source tool for sound visualization and manipulation.
Exec=$execpath %F
Icon=wavesurfer
Type=Application
Categories=Application;AudioVideo;Audio;"

exec mkdir -p [file dirname $desktopfile]
set f [open $desktopfile w]
puts $f $desktopdata
close $f

puts "installing icon..."
exec mkdir -p [file dirname $iconfile]
exec cp icons/ws10-64.png $iconfile
