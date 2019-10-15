(cd snack2.2.10/unix && ./configure --with-tcl=../../build/tcl/Tcl.framework --with-tk=../../build/tk/Tk.framework --enable-portaudio && make clean && make CC="gcc -mmacosx-version-min=10.6" -j8)
mkdir -p binpkg/macos/snack2.2/
cp snack2.2.10/unix/*.dylib snack2.2.10/unix/snack.tcl snack2.2.10/unix/pkgIndex.tcl binpkg/macos/snack2.2/
