TCLSH          = tclsh8.4
PREFIX	       = /usr/local
TMP            = /tmp/__wavesurfer_build
ROOT           = $(shell pwd)
RUNTIME_win    = $(ROOT)/build/kit/tclkit-8.5.8-win32.upx.exe
RUNTIME_linux  = $(ROOT)/build/kit/tclkit-linux-x86
RUNTIME_linux64  = $(ROOT)/build/kit/tclkit-8.5b1-linux-x86_64

# for 32-bit OSX builds, uncomment these

#OSXBIN	       = osx-i386
#WISHAPP_osx    = $(ROOT)/build/osx-app-kit/Wish-8.5.9-decarbon.app.tgz
#WISHAPP_osx    = $(ROOT)/build/osx-app-kit/Wish-8.6b2.app.tgz

# for 64-bit OSX builds, uncomment these

OSXBIN	       = osx-x86_64
WISHAPP_osx    = $(ROOT)/build/osx-app-kit/Wish-8.5.9-decarbon-x86_64.app.tgz

LOCAL_BINARIES = $(HOME)/Dropbox/wavesurfer

# NOTE: On mountain lion built-in sed gives an error, so let's use own-built GNU sed instead:
SED = /usr/local/bin/sed

ifeq ($(shell uname),Darwin)
	TCLKIT = build/kit/tclkit-darwin-x86-aqua
endif
ifeq ($(shell uname),Linux)
	TCLKIT = build/kit/tclkit-linux-x86
endif

PKGFILES = \
	src/wsurf/wsurf.tcl \
	src/wsurf/surfutil.tcl \
	src/wsurf/resizer.tcl \
	src/wsurf/vtcanvas.tcl \
	src/wsurf/wavebar.tcl \
	src/wsurf/messagebar.tcl \
	src/wsurf/cmdline.tcl \
	src/wsurf/tkcon.tcl \
	src/wsurf/pkgIndex.tcl \
	src/wsurf/htmllib.tcl \
	src/wsurf/wibble.tcl

APPWSFILES = \
	src/app-wavesurfer/pkgIndex.tcl \
	src/app-wavesurfer/wavesurfer.tcl

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

READMEFILES = README.txt demos/README-Python.txt demos/README.txt msgs/README.txt src/plugins/README.txt LICENSE.txt

PACKAGEVER    = $(shell grep "package provide wsurf" src/wsurf.tcl | cut -f 4 -d " ")
BUILD         = $(shell echo puts [clock format [clock seconds] -format %y%m%d%H%M] | $(TCLSH))
BUNDLEEXTENSIONS    = $(shell echo puts "\'<string>[join {wav au aif aiff smp sd snd nsp raw mp3 ogg} </string><string>]</string>\'" | $(TCLSH))

VER_A	= 1
VER_B 	= 8
VER_C   = 8
PATCHLEVEL = p5

MAJORVERSION  = $(VER_A).$(VER_B)
RELEASE       = $(VER_A).$(VER_B).$(VER_C)
WINRELEASE    = $(VER_A)$(VER_B)$(VER_C)
MANVERSION    = $(VER_A)$(VER_B)
RELEASETAG    = release_$(VER_A)_$(VER_B)_$(VER_C)_$(PATCHLEVEL)

SNACKMAJORV   = 2.2
SNACKARCH     =
WSURF         = wsurf$(PACKAGEVER)
INSTDIR       = $(PREFIX)/lib/$(WSURF)
STYLESHEET    = /wavesurfer/wsstyle.css

COPYRIGHT     = Copyright (c) 2000-2013 Jonas Beskow and Kare Sjolander

ABOUTWAVESURFER = WaveSurfer $(RELEASE)$(PATCHLEVEL)-$(BUILD)\\\n$(COPYRIGHT)

release: src-release win-release linux-release osx-release

upload:
	rm -rf $(TMP)/$(RELEASE)$(PATCHLEVEL)
	mkdir -p $(TMP)/$(RELEASE)$(PATCHLEVEL)
	cp  release/$(RELEASE).txt $(TMP)/$(RELEASE)$(PATCHLEVEL)/README.txt
	cp  release/wavesurfer-$(RELEASE)$(PATCHLEVEL)*.* $(TMP)/$(RELEASE)$(PATCHLEVEL)
	scp -r $(TMP)/$(RELEASE)$(PATCHLEVEL) $(USER),wavesurfer@frs.sourceforge.net:/home/frs/project/w/wa/wavesurfer/wavesurfer/


src-release: pkgIndex
	rm -rf $(TMP)
	mkdir -p $(TMP)
	mkdir $(TMP)/wavesurfer-$(RELEASE)$(PATCHLEVEL)

	tar cvfz $(TMP)/1.tgz $(PKGFILES) $(APPWSFILES) $(PLUGINFILES) $(CONFIGURATIONS) $(DEMOS) $(MSGS) $(TOOLS) $(READMEFILES)
	cd $(TMP)/wavesurfer-$(RELEASE)$(PATCHLEVEL);tar xvfz ../1.tgz
	echo s/@ABOUTWAVESURFER@/"$(ABOUTWAVESURFER)"/g > $(TMP)/replacements.sed
	echo s/@MAJORVERSION@/$(MAJORVERSION)/g >> $(TMP)/replacements.sed
	echo s/@SNACKMAJORV@/$(SNACKMAJORV)/g >> $(TMP)/replacements.sed
	echo s/@RELEASE@/$(RELEASE)$(PATCHLEVEL)/g >> $(TMP)/replacements.sed
	echo s/@COPYRIGHT@/"$(COPYRIGHT)"/g >> $(TMP)/replacements.sed

	find $(TMP)/wavesurfer-$(RELEASE)$(PATCHLEVEL) -type f -exec $(SED) -i -f $(TMP)/replacements.sed {} \;

	mkdir $(TMP)/wavesurfer-$(RELEASE)$(PATCHLEVEL)/icons; cp -r $(ICONS) $(TMP)/wavesurfer-$(RELEASE)$(PATCHLEVEL)/icons

	mkdir $(TMP)//wavesurfer-$(RELEASE)$(PATCHLEVEL)/doc
	for podfile in $(PODFILES); do \
		base=`basename $${podfile} .pod`; \
		echo $${podfile},$(TMP)/wavesurfer-$(RELEASE)$(PATCHLEVEL)/doc/$${base}.html;\
		pod2html $${podfile} > $(TMP)/wavesurfer-$(RELEASE)$(PATCHLEVEL)/doc/$${base}.html;\
	done

	cd $(TMP); tar cfz $(ROOT)/release/wavesurfer-$(RELEASE)$(PATCHLEVEL)-src.tgz wavesurfer-$(RELEASE)$(PATCHLEVEL)
	cp $(TMP)/wavesurfer-$(RELEASE)$(PATCHLEVEL)/doc/*.html $(ROOT)/release/


linux-release:
	$(MAKE) _wrap TARGET=linux SNACKMAJORV=2.2 SNACKARCH=-alsa
	chmod a+x $(TMP)/wavesurfer

	cd $(TMP); tar cfz $(ROOT)/release/wavesurfer-$(RELEASE)$(PATCHLEVEL)-linux-i386.tgz wavesurfer
	cp $(TMP)/wavesurfer $(LOCAL_BINARIES)/wavesurfer-linux-i386 

linux64-release:
	$(MAKE) _wrap TARGET=linux64 SNACKMAJORV=2.2 SNACKARCH=-alsa
	chmod a+x $(TMP)/wavesurfer

	cd $(TMP); tar cfz $(ROOT)/release/wavesurfer-$(RELEASE)$(PATCHLEVEL)-linux-i386.tgz wavesurfer
	cp $(TMP)/wavesurfer $(LOCAL_BINARIES)/wavesurfer-linux-64

win-release:
	$(MAKE) _wrap TARGET=win

	cd $(TMP); mv wavesurfer wavesurfer.exe; zip $(ROOT)/release/wavesurfer-$(RELEASE)$(PATCHLEVEL)-win-i386.zip wavesurfer.exe
	cp $(TMP)/wavesurfer.exe $(LOCAL_BINARIES)/wavesurfer-win-i386.exe

osx-release: macbundle
	rm -rf $(TMP)/wavesurfer-$(RELEASE)$(PATCHLEVEL)
	mkdir $(TMP)/wavesurfer-$(RELEASE)$(PATCHLEVEL)
	cd $(TMP)/wavesurfer-$(RELEASE)$(PATCHLEVEL); tar xfz $(ROOT)/build/osx-app-kit/mac-alias-to-Applications.tgz
	cp -pr $(TMP)/WaveSurfer.app $(TMP)/wavesurfer-$(RELEASE)$(PATCHLEVEL)
	rm -f release/wavesurfer-$(RELEASE)$(PATCHLEVEL)-$(OSXBIN).dmg
	hdiutil create -srcfolder $(TMP)/wavesurfer-$(RELEASE)$(PATCHLEVEL) release/wavesurfer-$(RELEASE)$(PATCHLEVEL)-$(OSXBIN).dmg

macbundle: src-release
	rm -rf $(TMP)/WaveSurfer.app
	cd $(TMP); tar xfz $(WISHAPP_osx)
	mv $(TMP)/Wish.app $(TMP)/WaveSurfer.app
	chmod -R a+w $(TMP)/WaveSurfer.app
	mkdir $(TMP)/WaveSurfer.app/Contents/Resources/Scripts/ 
	mkdir $(TMP)/WaveSurfer.app/Contents/Resources/icons
	mkdir $(TMP)/WaveSurfer.app/Contents/lib
	cp build/osx-app-kit/AppMain.tcl $(TMP)/WaveSurfer.app/Contents/Resources/Scripts/
	cp icons/ws10.icns icons/ws10h.gif $(TMP)/WaveSurfer.app/Contents/Resources/icons 
	cd $(TMP)/WaveSurfer.app/Contents/Resources; ln -sf icons/ws10.icns Wish.icns
	cat build/osx-app-kit/Info.plist.in | \
		sed s/@BUNDLENAME@/WaveSurfer/g |\
		sed s/@BUNDLEVERSION@/$(RELEASE)$(PATCHLEVEL)/g | \
		sed s/@BUNDLEGETINFOSTRING@/"$(COPYRIGHT)"/g |\
		sed s%@BUNDLETYPEEXTENSIONS@%$(BUNDLEEXTENSIONS)%g |\
		sed s/@BUNDLEIDENTIFIER@/se.kth.speech.wavesurfer/g \
		> $(TMP)/WaveSurfer.app/Contents/Info.plist
	cp -r $(TMP)/wavesurfer-$(RELEASE)$(PATCHLEVEL)/src/* $(TMP)/WaveSurfer.app/Contents/Resources/Scripts/
	cp build/snack-fix/*.tcl build/binpkg/$(OSXBIN)/snack$(SNACKMAJORV)
	cp -r build/binpkg/$(OSXBIN)/snack$(SNACKMAJORV) $(TMP)/WaveSurfer.app/Contents/lib
	rm $(TMP)/WaveSurfer.app/Contents/lib/snack$(SNACKMAJORV)/libsound.dylib
	cp -a build/binpkg/osx/libportaudio*.dylib $(TMP)/WaveSurfer.app/Contents/Frameworks
	cd $(TMP)/WaveSurfer.app/Contents/Frameworks; ln -s libportaudio.2.0.0.dylib libportaudio.2.dylib
	cd $(TMP)/WaveSurfer.app/Contents/Frameworks; ln -s libportaudio.2.0.0.dylib libportaudio.dylib
	cp -r build/binpkg/$(OSXBIN)/tkdnd2.2 $(TMP)/WaveSurfer.app/Contents/lib

	install_name_tool -id @executable_path/../Frameworks/libportaudio.dylib	\
		$(TMP)/WaveSurfer.app/Contents/Frameworks/libportaudio.dylib
	install_name_tool -change /usr/local/lib/libportaudio.2.dylib @executable_path/../Frameworks/libportaudio.2.dylib $(TMP)/WaveSurfer.app/Contents/lib/snack$(SNACKMAJORV)/libsnack.dylib
	touch $(TMP)/WaveSurfer.app
	rm -rf $(LOCAL_BINARIES)/WaveSurfer-$(OSXBIN).app
	cp -r $(TMP)/WaveSurfer.app $(LOCAL_BINARIES)/WaveSurfer-$(OSXBIN).app

_wrap: src-release
	cd $(TMP); tar xvfz  $(ROOT)/release/wavesurfer-$(RELEASE)$(PATCHLEVEL)-src.tgz
	rm -rf $(TMP)/wavesurfer.vfs
	mkdir -p $(TMP)/wavesurfer.vfs/lib
	cp -r $(TMP)/wavesurfer-$(RELEASE)$(PATCHLEVEL)/src/* $(TMP)/wavesurfer.vfs/lib
	cp -r tclxml3.3 $(TMP)/wavesurfer.vfs/lib
	rm $(TMP)/wavesurfer-$(RELEASE)$(PATCHLEVEL)/src/plugins/example*.plug
	cp build/kit/main.tcl $(TMP)/wavesurfer.vfs
	cp -f $(TCLKIT) $(TMP)/tclkit
	cp build/snack-fix/*.tcl build/binpkg/$(TARGET)/snack$(SNACKMAJORV)$(SNACKARCH)
	cp -r build/binpkg/$(TARGET)/snack$(SNACKMAJORV)$(SNACKARCH) $(TMP)/wavesurfer.vfs/lib/snack$(SNACKMAJORV)
	-cp -r build/binpkg/$(TARGET)/tkdnd* $(TMP)/wavesurfer.vfs/lib
	mkdir -p $(TMP)/wavesurfer.vfs/icons
	cp icons/ws10h.gif $(TMP)/wavesurfer.vfs/icons 
	cp icons/ws10-tkformat.ico $(TMP)/wavesurfer.vfs/tclkit.ico
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

