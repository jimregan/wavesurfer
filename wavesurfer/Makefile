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
VER_A	= $(shell head -1 release.txt)
VER_B 	= $(shell head -2 release.txt|tail -1)
VER_C   = $(shell head -3 release.txt|tail -1)

MAJORVERSION  = $(VER_A).$(VER_B)
RELEASE       = $(VER_A).$(VER_B).$(VER_C)
WINRELEASE    = $(VER_A)$(VER_B)$(VER_C)
MACRELEASE    = $(RELEASE)
MANVERSION    = $(VER_A)$(VER_B)
RELEASETAG    = release_$(VER_A)_$(VER_B)_$(VER_C)

SNACKMAJORV   = 2.2
WSURF         = wsurf$(PACKAGEVER)
INSTDIR       = $(PREFIX)/lib/$(WSURF)
STYLESHEET    = /wavesurfer/wsstyle.css

pkgIndex:
	build/mkPkgIndex.tcl $(PKGFILES) > src/wsurf/pkgIndex.tcl
	build/mkPkgIndex.tcl src/app-wavesurfer/wavesurfer.tcl > src/app-wavesurfer/pkgIndex.tcl


dist: pkgIndex
	tar cvf $(TMP)/wsdist.tar $(PKGFILES) $(APPWSFILES) $(PLUGINFILES) $(CONFIGURATIONS) $(ICONS) $(DEMOS) $(MSGS) $(TOOLS)
	cd $(TMP);rm -rf wsdist; mkdir wsdist; cd wsdist; tar xvf ../wsdist.tar
	sed -e s/"@RELEASE@"/$(RELEASE)/ -e s/"@BUILD@"/$(BUILD)/< src/app-wavesurfer/wavesurfer.tcl > $(TMP)/wsdist/src/app-wavesurfer/wavesurfer.tcl
	cp src/app-wavesurfer/proctrace.tcl $(TMP)/wsdist/src/app-wavesurfer/_proctrace.tcl

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
	tar cvfz $(TMP)/wavesurfer-$(RELEASE)-src.tgz $(TMP)/wavesurfer-$(RELEASE)

install: pkgIndex
	rm -rf $(INSTDIR)
	mkdir -p $(INSTDIR)
	cp $(PKGFILES) $(INSTDIR)
	mkdir -p $(INSTDIR)/configurations
	cp -ar configurations/*.conf $(INSTDIR)/configurations
	mkdir -p $(INSTDIR)/plugins
	cp -ar plugins/*.plug plugins/*.tcl $(INSTDIR)/plugins
	cp vlab.tcl $(PREFIX)/bin/wavesurfer
	chmod a+rx $(PREFIX)/bin/wavesurfer

winwrap: dist strip
	./kit/wrap.tcl windows $(WAVESURFER_REL)
	mv -f wavesurfer-RELEASE.exe wavesurfer.exe
	zip wavesurfer-$(WINRELEASE)-win.zip wavesurfer.exe

linwrap: dist strip
	./kit/wrap.tcl linux $(WAVESURFER_REL)
	mv -f wavesurfer-RELEASE wavesurfer
	tar cf wavesurfer-$(RELEASE)-linux-i386 wavesurfer
	gzip -S .tgz -f wavesurfer-$(RELEASE)-linux-i386

pre-wrap: dist
	rm -rf $(TMP)/wavesurfer.vfs
	mkdir -p $(TMP)/wavesurfer.vfs/lib
	cp -r $(TMP)/wavesurfer-$(RELEASE)/src/* $(TMP)/wavesurfer.vfs/lib
	rm $(TMP)/wavesurfer-$(RELEASE)/src/plugins/example*.plug
	cp build/main.tcl $(TMP)/wavesurfer.vfs
	cp -f $(TCLKIT) $(TMP)/tclkit

_wrap: pre-wrap
	cp -r build/binpkg/$(TARGET)/snack2.2 $(TMP)/wavesurfer.vfs/lib
	cd $(TMP); \
	./tclkit $(ROOT)/build/kit/sdx.kit wrap wavesurfer -runtime $(RUNTIME_$(TARGET)) ;\
	chmod a+x wavesurfer

linux-wrap:
	$(MAKE) _wrap TARGET=linux
	cd $(TMP); tar cvfz wavesurfer-$(MACRELEASE)-linux.tgz wavesurfer

win32-wrap:
	$(MAKE) _wrap TARGET=win32
	cd $(TMP); mv wavesurfer wavesurfer.exe; zip wavesurfer-$(RELEASE)-win32.zip wavesurfer.exe

osx-app: dist
	rm -rf WaveSurfer.app
	cp -r build/Wish.app WaveSurfer.app
	chmod -R a+w WaveSurfer.app
	mkdir WaveSurfer.app/Contents/Resources/Scripts/
	cp build/AppMain.tcl WaveSurfer.app/Contents/Resources/Scripts/
	cp build/Info.plist WaveSurfer.app/Contents/
	cp -r $(TMP)/wavesurfer-$(RELEASE)/src/* WaveSurfer.app/Contents/Resources/Scripts/
	cp -r build/binpkg/osx/snack2.2 WaveSurfer.app/Contents/Resources/Scripts/
	tar cvfz wavesurfer-$(MACRELEASE)-osx.tgz WaveSurfer.app



macwrap-2: dist strip
	cp -r $(WISHKIT) WaveSurfer.app
	cp -r $(TMP)/wavesurfer-$(MACRELEASE)/wsurf$(PACKAGEVER) WaveSurfer.app
	cp $(TMP)/wavesurfer-$(MACRELEASE)/wavesurfer.tcl WaveSurfer.app/Contents/Resources/Scripts/
	cp -r crosswrap/bin/macosx/pkg/snack2.2/ WaveSurfer.app/Contents/lib/
	mv WaveSurfer.app/Contents/Resources/Scripts/wavesurfer.tcl $(WISHKIT)/Contents/Resources/Scripts/AppMain.tcl
	tar cvfz wavesurfer-$(MACRELEASE)-osx.tar.gz WaveSurfer.app

macwrap-manual:
	# do the rest by hand on the Mac
	@echo "***************************************************"
	@echo "ssh pfstar01 -l sysadmin"
	@echo "cd $(shell pwd)"
	@echo "klog $(USER)"
	@echo "tar cf wavesurfer-$(MACRELEASE)-osx.tar WaveSurfer-$(MACRELEASE)"
	@echo "rm -rf WaveSurfer-$(MACRELEASE)"
	@echo "gzip -f wavesurfer-$(MACRELEASE)-osx.tar"
#	tar cf wavesurfer-$(MACRELEASE)-osx.tar WaveSurfer-$(MACRELEASE)
#	rm -r WaveSurfer-$(MACRELEASE)
#	gzip -f wavesurfer-$(MACRELEASE)-osx.tar

crosswrap: winwrap linwrap macwrap


# The download page is automatically updated with w.r.t. versions, dates and sizes
# using SSI-macros. It relies on the files current-release.txt and 
# current-winrelease.txt being present in the web catalog, as well as symbolic
# links wavesurfer-latest.tar.gz, wavesurfer-latest-linux-i386 and 
# wavesurfer-latest-win.exe pointing to the latest files.
# This is managed by the avail target.

avail: dist
	echo -n $(RELEASE) > $(WEBHOME)/current-release.txt
	echo -n $(WINRELEASE) > $(WEBHOME)/current-winrelease.txt
	echo -n $(MACRELEASE) > $(WEBHOME)/current-macrelease.txt
	chmod -R ug+rw wavesurfer-$(RELEASE)-linux-i386.tgz
	chmod -R ug+rw wavesurfer-$(WINRELEASE)-win.zip
	cp -f $(TMP)/wavesurfer-$(RELEASE).tar.gz    $(WEBHOME)
	cp -f wavesurfer-$(RELEASE)-linux-i386.tgz $(WEBHOME)
	cp -f wavesurfer-$(MACRELEASE)-osx.tar.gz  $(WEBHOME)
	cp -f wavesurfer-$(WINRELEASE)-win.zip     $(WEBHOME)
	cd $(WEBHOME);\
	ln -sf wavesurfer-$(RELEASE).tar.gz wavesurfer-latest.tar.gz
	cd $(WEBHOME);\
	ln -sf wavesurfer-$(RELEASE)-linux-i386.tgz wavesurfer-latest-linux-i386.tgz
	cd $(WEBHOME);\
	ln -sf wavesurfer-$(MACRELEASE)-osx.tar.gz wavesurfer-latest-osx.tar.gz
	cd $(WEBHOME);\
	ln -sf wavesurfer-$(WINRELEASE)-win.zip wavesurfer-latest-win.zip
	cp -f sphere.tar.gz $(WEBHOME)
	cp -f ogg.tar.gz    $(WEBHOME)
	cp -f sphere.zip    $(WEBHOME)
	cp -f ogg.zip       $(WEBHOME)
	cp -f src/download_tcl        $(WEBHOME)
	cp -f ogg/ogg.plug            $(WEBHOME)/ogg
	cp -f ogg/libsnackogg.*       $(WEBHOME)/ogg
	cp -f sphere/sphere.plug      $(WEBHOME)/sphere
	cp -f sphere/libsnacksphere.* $(WEBHOME)/sphere
	cp -f src/plugins/transdiff.plug   $(WEBHOME)/miscplugs
	cp -f src/plugins/hum.plug $(WEBHOME)/miscplugs
	cp -f src/plugins/pmview.plug    $(WEBHOME)/miscplugs

	mkdir -p $(TMHINST)/os/bin
	cp -f wavesurfer $(TMHINST)/os/bin/wavesurfer
	mkdir -p $(TMHINST)/plugin
	cp -f sphere/libsnacksphere.so $(TMHINST)/plugin/
	cp -f sphere/sphere.plug $(TMHINST)/plugin/
	cp -f ogg/libsnackogg.so $(TMHINST)/plugin/
	cp -f ogg/ogg.plug $(TMHINST)/plugin/
	cp $(TMHMODULES)/1.4 $(TMHMODULES)/$(RELEASE)
	echo '#%Module1.0'                        > $(TMHMODULES)/.version
	echo 'set ModulesVersion "$(RELEASE)"' >> $(TMHMODULES)/.version

cpweb: html
	cp -f doc/*.html $(WEBHOME)
	cp -f web/*.html $(WEBHOME)
	cp -f web/*.css $(WEBHOME)
	cp -f icons/b16-256.ico $(WEBHOME)
	echo '<!--#include file="man$(MANVERSION).html"-->' > $(WEBHOME)/man.html
	cp -f web/*.gif $(WEBHOME)

psphere:
	tar cf sphere.tar sphere/libsnacksphere.dll sphere/libsnacksphere.so sphere/sphere.plug sphere/sphere.txt ; gzip -f sphere.tar
	zip sphere.zip sphere/libsnacksphere.dll sphere/libsnacksphere.so sphere/sphere.plug sphere/sphere.txt

pogg:
	tar cf ogg.tar ogg/ogg.plug ogg/libsnackogg.so ogg/license.txt ogg/libsnackogg.dll ogg/ogg.txt ; gzip -f ogg.tar
	zip ogg.zip ogg/ogg.plug ogg/libsnackogg.so ogg/license.txt ogg/libsnackogg.dll ogg/ogg.txt

video_html:
	pod2html --css $(STYLESHEET) < video/video.pod > video/video.html

pvideo: video_html
	zip video.zip video/video.plug video/QuickTimeTcl.dll video/QuickTimeTcl.dylib video/Video.conf video/video.html

video_avail: pvideo
	cp -f video.zip $(WEBHOME)
	mkdir -p $(WEBHOME)/video
	cp -f video/video.plug       $(WEBHOME)/video
	cp -f video/Video.conf       $(WEBHOME)/video
	cp -f video/QuickTimeTcl.dll $(WEBHOME)/video
	cp -f video/QuickTimeTcl.dylib $(WEBHOME)/video
	cp -f video/video.html       $(WEBHOME)/video
	cp -f src/download_tcl       $(WEBHOME)

releasetag:
	cvs commit
	cvs -q tag $(CVSRELEASETAG)

all:	html dist crosswrap avail video_avail cpweb releasetag

