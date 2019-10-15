#wget https://prdownloads.sourceforge.net/tcl/tcl8.6.9-src.tar.gz
#wget https://prdownloads.sourceforge.net/tcl/tk8.6.9.1-src.tar.gz
rm -rf build tcl8.6.9 tk8.6.9
tar xvfz tcl*.gz
tar xvfz tk*.gz

# build & install regular tcl/tk - this is needed for snack compilation 
#(export CFLAGS = -mmacosx-version-min=10.6; cd tcl8.6.9/macosx; ./configure; make install -j8)
#(export CFLAGS = -mmacosx-version-min=10.6; cd tk8.6.9/macosx; ./configure; make install-j8)
(cd tcl8.6.9/macosx && ./configure && make CC="gcc -mmacosx-version-min=10.6" install -j8)
(cd tk8.6.9/macosx && ./configure && make CC="gcc -mmacosx-version-min=10.6" install -j8)

# build embedded - this is needed for wavesurfer
(cd tcl8.6.9/macosx && ./configure && make CC="gcc -mmacosx-version-min=10.6" embedded -j8)
(cd tk8.6.9/macosx && ./configure && make CC="gcc -mmacosx-version-min=10.6" embedded -j8)

(cd build/tk/Deployment/Library/Frameworks; tar cvfz /tmp/Wish-8.6.9.app.tgz Wish.app)
cp /tmp/Wish-8.6.9.app.tgz osx-app-kit/

