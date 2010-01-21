#!/bin/sh
# the next line restarts using wish \
exec tclsh8.3 "$0" "$@"

# Utility that computes shape files for a whole directory tree.
# This makes it possible to do this in advance, thus saving
# computation time and providing instant first time access.
# 
# Usage createshapes.tcl [path]
#

package require -exact snack 2.2
# Try to load optional file format handlers
catch { package require snacksphere }
catch { package require snackogg }

snack::sound s
snack::sound t -encoding lin8

# Computes shape files for all files matching *.wav in the specified
# directory and its subdirectories

proc ComputeAllShapesInDir {path} {
  foreach file [lsort [glob -nocomplain [file join $path *.wav]]] {
    if {[file exists [file root $file].shape] == 0} {
      puts "Creating [file root $file].shape"
      s configure -file $file
      s shape t -encoding lin8
      t write [file root $file].shape -fileformat aiff
      t flush
    } else {
      puts "Found [file root $file].shape"
    }
  }
  foreach dir [lsort [glob -nocomplain [file join $path *]]] {
    if {[file isdirectory $dir]} {
      ComputeAllShapesInDir $dir
    }
  }
}

ComputeAllShapesInDir [lindex $argv 0]
