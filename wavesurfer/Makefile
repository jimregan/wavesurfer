TCLSH   = tclsh8.4
PREFIX	= /usr/local
TMP     = /tmp
ROOT          = $(shell pwd)
RUNTIME_osx   = $(ROOT)/build/kit/tclkit-darwin-univ-aqua
RUNTIME_win32 = $(ROOT)/build/kit/tclkit-win32.upx.exe
RUNTIME_linux = $(ROOT)/build/kit/tclkit-linux-x86

ifeq ($(shell uname),Darwin)
	TCLKIT = build/kit/tclkit-darwin-x86-aqua
endif

PKGFILES = \
	src/wsurf/wsurf.tcl \
	src/wsurf/surfutil.tcl \
	src/wsurf/resizer.tcl \
	src/wsurf/vtcanvas.tcl \
	src/wsurf/notebook.tcl \
	src/wsurf/wavebar.tcl \
	src/wsurf/messagebar.tcl \
	src/wsurf/cmdline.tcl \
	src/wsurf/combobox.tcl \
	src/wsurf/tkcon.tcl \
	src/wsurf/pkgIndex.tcl \
	src/wsurf/htmllib.tcl

APPWSFILES = src/app-wavesurfer/pkgIndex.tcl

PLUGINFILES = \
	src/plugins/timeaxis.plug \
	src/plugins/dataplot.plug \
	src/plugins/transcription.plug \
	src/plugins/analysis.plug \
        src/plugins/transcription_format_htk.plug \
	src/plugins/transcription_format_timit.plug \
	src/plugins/transcription_format_phondat.plug \
	src/plugins/transcription_format_isis.plug \
	src/plugins/transcription_format_ws.plug \
	src/plugins/transcription_format_waves.plug \
	src/plugins/example1.plug \
	src/plugins/example2.plug

CONFIGURATIONS = \
	"src/configurations/HTK transcription.conf" \
	"src/configurations/IPA transcription.conf" \
	src/configurations/n-waveforms.conf \
	src/configurations/Spectrogram.conf \
	src/configurations/Demonstration.conf \
	"src/configurations/Speech analysis.conf" \
	"src/configurations/TIMIT transcription.conf" \
	"src/configurations/TIMIT phones-words.conf" \
	src/configurations/Transcription.conf \
	src/configurations/Waveform.conf

ICONS =	icons/icon48.xpm

DEMOS = demos/wsapp?.tcl demos/embed.tcl demos/speecon.tcl demos/Wsurf.py demos/wsapp?.py demos/wsplugapp.py demos/WsurfPlugin.py

MSGS = msgs/*.msg

TOOLS = tools/*.tcl

PODFILES = doc/plugin-api.pod doc/widget.pod doc/wsurf.pod

HTMLFILES = web/man$(MANVERSION).html web/wsguileft.gif web/wsguiright.gif

WRAPFILES     = $(WAVESURFER_REL) $(PKGFILES) $(CONFIGURATIONS) $(PLUGINFILES)
PACKAGEVER    = $(shell grep "package provide wsurf" src/wsurf.tcl | cut -f 4 -d " ")
BUILD         = $(shell echo puts [clock format [clock seconds] -format %y%m%d%H%M] | $(TCLSH))
BUNDLEEXTENSIONS    = $(shell echo puts "\'<string>[join {wav au aif aiff smp sd snd nsp raw mp3 ogg} </string><string>]</string>\'" | $(TCLSH))

VER_A	= $(shell head -1 release.txt)
VER_B 	= $(shell head -2 release.txt|tail -1)
VER_C   = $(shell head -3 release.txt|tail -1)

MAJORVERSION  = $(VER_A).$(VER_B)
RELEASE       = $(VER_A).$(VER_B).$(VER_C)
WINRELEASE    = $(VER_A)$(VER_B)$(VER_C)
MANVERSION    = $(VER_A)$(VER_B)
RELEASETAG    = release_$(VER_A)_$(VER_B)_$(VER_C)

SNACKMAJORV   = 2.2
WSURF         = wsurf$(PACKAGEVER)
INSTDIR       = $(PREFIX)/lib/$(WSURF)
STYLESHEET    = /wavesurfer/wsstyle.css

COPYRIGHT     = Copyright © 2000-2010 Jonas Beskow and Kare Sjolander
#ABOUTWAVESURFER = "WaveSurfer $(RELEASE)-$(BUILD) $(COPYRIGHT)"
ABOUTWAVESURFER = "WaveSurfer $(RELEASE)-$(BUILD)\\\n$(COPYRIGHT)"


all: src-release osx-release win32-release linux-release

src-release: pkgIndex
	tar cf $(TMP)/wsdist.tar $(PKGFILES) $(APPWSFILES) $(PLUGINFILES) $(CONFIGURATIONS) $(ICONS) $(DEMOS) $(MSGS) $(TOOLS)
	cd $(TMP);rm -rf wsdist; mkdir wsdist; cd wsdist; tar xf ../wsdist.tar
	cat src/app-wavesurfer/wavesurfer.tcl | sed -e s/@ABOUTWAVESURFER@/$(ABOUTWAVESURFER)/g | sed -e s/@RELEASE@/$(RELEASE)/g > $(TMP)/wsdist/src/app-wavesurfer/wavesurfer.tcl
	cp src/app-wavesurfer/proctrace.tcl $(TMP)/wsdist/src/app-wavesurfer/_proctrace.tcl
#	cp src/app-wavesurfer/proctrace.tcl $(TMP)/wsdist/src/app-wavesurfer/proctrace.tcl

	mkdir $(TMP)/wsdist/doc
	for podfile in $(PODFILES); do \
		base=`basename $${podfile} .pod`; \
		pod2html $${podfile} > $(TMP)/wsdist/doc/$${base}.html; \
	done

	sed -e s/"<VERSION>"/$(RELEASE)/ -e s/"<SNACKMAJORV>"/$(SNACKMAJORV)/\
	< README.txt > $(TMP)/wsdist/README.txt
	sed s/"<MAJORVERSION>"/$(MAJORVERSION)/g < README2.txt > \
	$(TMP)/wsdist/src/plugins/README.txt
	sed -e s/"<MAJORVERSION>"/$(MAJORVERSION)/ \
	-e s/"<VERSION>"/$(RELEASE)/  -e s/"<SNACKMAJORV>"/$(SNACKMAJORV)/ \
	< README3.txt > $(TMP)/wsdist/demos/README.txt
	sed s/"<MAJORVERSION>"/$(MAJORVERSION)/ < README4.txt \
	 > $(TMP)/wsdist/msgs/README.txt
	sed s/"<MAJORVERSION>"/$(MAJORVERSION)/ < README5.txt \
	 > $(TMP)/wsdist/demos/README-Python.txt
	rm -rf $(TMP)/wavesurfer-$(RELEASE)
	cp -r $(TMP)/wsdist $(TMP)/wavesurfer-$(RELEASE)
	tar cfz $(TMP)/wavesurfer-$(RELEASE)-src.tgz $(TMP)/wavesurfer-$(RELEASE)

linux-release:
	mkdir -p bin
	$(MAKE) _wrap TARGET=linux
	cd $(TMP); tar cfz $(ROOT)/bin/wavesurfer-$(RELEASE)-linux.tgz wavesurfer

win32-release:
	mkdir -p bin
	$(MAKE) _wrap TARGET=win32
	cd $(TMP); mv wavesurfer wavesurfer.exe; zip $(ROOT)/bin/wavesurfer-$(RELEASE)-win32.zip wavesurfer.exe

osx-release: macbundle
	rm -rf $(TMP)/wavesurfer-$(RELEASE)
	mkdir $(TMP)/wavesurfer-$(RELEASE)
	cd $(TMP)/wavesurfer-$(RELEASE); tar xfz $(ROOT)/build/mac-alias-to-Applications.tgz
	cp -pr bin/WaveSurfer.app $(TMP)/wavesurfer-$(RELEASE)
	rm -f bin/wavesurfer-$(RELEASE)-osx.dmg
	hdiutil create -srcfolder $(TMP)/wavesurfer-$(RELEASE) bin/wavesurfer-$(RELEASE)-osx.dmg

macbundle: src-release
	mkdir -p bin
	rm -rf bin/WaveSurfer.app
	cd bin; tar xfz ../build/Wish.app.tgz
	mv bin/Wish.app bin/WaveSurfer.app
	chmod -R a+w bin/WaveSurfer.app
	mkdir bin/WaveSurfer.app/Contents/Resources/Scripts/ 
	mkdir bin/WaveSurfer.app/Contents/Resources/icons
	mkdir bin/WaveSurfer.app/Contents/lib
	cp build/AppMain.tcl bin/WaveSurfer.app/Contents/Resources/Scripts/
	cp icons/ws10.icns icons/ws10h.gif bin/WaveSurfer.app/Contents/Resources/icons 
	cd bin/WaveSurfer.app/Contents/Resources; ln -sf icons/ws10.icns Wish.icns
	cat build/Info.plist.in | \
		sed s/@BUNDLENAME@/WaveSurfer/g |\
		sed s/@BUNDLEVERSION@/$(RELEASE)/g | \
		sed s/@BUNDLEGETINFOSTRING@/"$(COPYRIGHT)"/g |\
		sed s%@BUNDLETYPEEXTENSIONS@%$(BUNDLEEXTENSIONS)%g |\
		sed s/@BUNDLEIDENTIFIER@/se.kth.speech.wavesurfer/g \
		> bin/WaveSurfer.app/Contents/Info.plist
	cp -r $(TMP)/wavesurfer-$(RELEASE)/src/* bin/WaveSurfer.app/Contents/Resources/Scripts/
	cp -r build/binpkg/osx/snack$(SNACKMAJORV) bin/WaveSurfer.app/Contents/lib
	rm bin/WaveSurfer.app/Contents/lib/snack$(SNACKMAJORV)/libsound.dylib
	cp -a build/binpkg/osx/libportaudio*.dylib bin/WaveSurfer.app/Contents/Frameworks
	install_name_tool -id @executable_path/../Frameworks/libportaudio.dylib	\
		bin/WaveSurfer.app/Contents/Frameworks/libportaudio.dylib
	install_name_tool -change /usr/local/lib/libportaudio.2.dylib @executable_path/../Frameworks/libportaudio.2.dylib bin/WaveSurfer.app/Contents/lib/snack$(SNACKMAJORV)/libsnack.dylib

_wrap: src-release
	rm -rf $(TMP)/wavesurfer.vfs
	mkdir -p $(TMP)/wavesurfer.vfs/lib
	cp -r $(TMP)/wavesurfer-$(RELEASE)/src/* $(TMP)/wavesurfer.vfs/lib
	rm $(TMP)/wavesurfer-$(RELEASE)/src/plugins/example*.plug
	cp build/main.tcl $(TMP)/wavesurfer.vfs
	cp -f $(TCLKIT) $(TMP)/tclkit
	cp -r build/binpkg/$(TARGET)/snack$(SNACKMAJORV) $(TMP)/wavesurfer.vfs/lib
	mkdir -p $(TMP)/wavesurfer.vfs/icons
	cp icons/ws10h.gif $(TMP)/wavesurfer.vfs/icons 
	cd $(TMP); \
	./tclkit $(ROOT)/build/kit/sdx.kit wrap wavesurfer -runtime $(RUNTIME_$(TARGET)) ;\
	chmod a+x wavesurfer

pkgIndex:
	build/mkPkgIndex.tcl $(PKGFILES) > src/wsurf/pkgIndex.tcl
	build/mkPkgIndex.tcl src/app-wavesurfer/wavesurfer.tcl > src/app-wavesurfer/pkgIndex.tcl


psphere:
	tar cf sphere.tar sphere/libsnacksphere.dll sphere/libsnacksphere.so sphere/sphere.plug sphere/sphere.txt ; gzip -f sphere.tar
	zip sphere.zip sphere/libsnacksphere.dll sphere/libsnacksphere.so sphere/sphere.plug sphere/sphere.txt

pogg:
	tar cf ogg.tar ogg/ogg.plug ogg/libsnackogg.so ogg/license.txt ogg/libsnackogg.dll ogg/ogg.txt ; gzip -f ogg.tar
	zip ogg.zip ogg/ogg.plug ogg/libsnackogg.so ogg/license.txt ogg/libsnackogg.dll ogg/ogg.txt

