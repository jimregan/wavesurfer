"""Python API to WaveSurfer plugins.

(c) 2003 Geoffrey WILFART
geoffrey.wilfart@tcts.fpms.ac.be
"""
import Tkinter
import Wsurf
import types

class WsurfPlugin:
    def __init__(self):
        """Build a dummy WaveSurfer plugin.
        
        Provide the interface for WaveSurfer plugins.
        Real plugins should override this class and define necessary methods.
        """
        self.name = "dummy"
        # the master should be the Wsurf widget this plugin instance
        # is attached to. First set to None, its actual value is given at
        # registration time (call to register function)
        self.master = None
        # description is a string explaining what the plugin is for
        self.description = ""
        # url is the url where this plugin can be found
        self.url = "http://tcts.fpms.ac.be"
        # dependencies is the list of the plugin dependencies (other plugins)
        self.dependencies = []
        
    def register(self, wsurf):
        """Register the plugin into a WaveSurfer instance.

        This method provides a way to automatically export all members
        and methods matching the current WaveSurfer plugin API.
        This allows one plugin to be usable no matter which version of
        WaveSufer is used.
        Subclasses may override this method to register only some methods
        of the API.
        """
        # For some strange reason, [eval list $l] returns an error when
        # l is like:
        # % set l {
        #    -elem1  elem1
        #    -elem2  elem2
        # }
        # % eval list $l
        # invalid command name "-elem2"
        #
        # We need to fallback to Tcl interpreter handling of lists
        # as a workaround
        self.master = wsurf
        self.tk = wsurf.tk
        wsurf.tk.eval('set wsurfPluginOptions [list]')
        wsurf.tk.eval('foreach {opt name} $wsurf::Info(ValidPluginOptions) ' +
        '{lappend wsurfPluginOptions $opt $name}')
        tmp_opts = wsurf.tk.eval('eval list $wsurfPluginOptions').split()
        options = {}
        for i in range(len(tmp_opts)/2):
            options[tmp_opts[2*i]] = tmp_opts[2*i+1]
        reg_string = ''
        # Declare namespace
        wsurf.tk.eval('namespace eval wsurf::%s {}' % self.name)
        for (opt, name) in options.items():
            try:
                # Try to get the corresponding attribute
                val = getattr(self, name)
                if callable(val):
                    val = wsurf._register(val)
                    # Give a nicer name to functions and make them
                    # available to Tcl
                    wsurf.tk.eval('set wsurf::%s::%s [list %s]' % \
                                       (self.name, name, val))
                    reg_string += ' %s $wsurf::%s::%s' % (opt, self.name, name)
                else:
                    reg_string += ' %s %s' % (opt, name)
            except AttributeError:
                # The option is not defined for this plugin
                pass
        # Now we just need to register
        for cmd in 'RegisterPlugin', 'ExecuteRegisterPlugin':
            wsurf.tk.eval('wsurf::%s %s %s' % (cmd, self.name, reg_string))


class TkObject:
    def __init__(self, master, name):
        """Init a TkObject.

        The TkObject is a Python wrapper around a real object already known by
        the Tcl/Tk interpreter.
        The object is specified by its (Tcl) name.
        """
        self.master = master
        # Take the str of name, since new version of Tkinter defines names as
        # unhashable class instances - and I need to hash.
        self.name = str(name) 
    def __getattr__(self, attr):
        """Get attributes.

        This method is provided to convert automatically calls of the form
        self.method() into a string that can be evaluated by the
        Tcl/Tk interpreter.
        """
        if attr[:2] == '__':
            raise AttributeError
        return lambda *args, **kws: \
               str(self.master.tk.call((self.name, attr) + \
               self.convert((args, kws))))
    
    def convert(self, obj):
        """Convert object.

        As in the Tkinter module, dictionaries are converted into -key value
        strings - used for configuration.
        Other sequence types are expanded and themselves converted.
        TkObject instances are replaced by their names,
        functions (callable objects) are registered, and all other objects
        are replaced by their string representation.
        """
        if type(obj) == types.DictType:
            d = {}
            for key in obj.keys():
                d.update({key: self.convert(obj[key])})
            res = d
        elif type(obj) in (types.ListType, types.TupleType):
            c = ()
            for item in obj:
                if type(item) == types.DictType:
                    c += self.master._options(self.convert(item))
                elif type(item) in (types.ListType, types.TupleType):
                    c += self.convert(item)
                else:
                    c += (self.convert(item),)
            res = c
        elif isinstance(obj, TkObject):
            res = obj.name
        elif callable(obj):
            res = self.master._register(obj)
        else:
            res = str(obj)
        return res
    

class SamplePlugin(WsurfPlugin):
    def __init__(self):
        """Build a sample plugin.
        
        This sample plugin basically does something similar to
        (but simpler than) analysis.plug.
        It is provided as an example of a real Python plugin for WaveSurfer,
        and illustrates how to handle parameters in the functions and
        how to manipulate those parameters from Python.
        """
        self.name = "sample_plugin"
        self.Info = {}
        self.vars = {}

    def addMenuEntriesProc(self, w, pane, m, hook, x, y):
        """Add menu entries"""
        # self.master is known at registration time
        if hook == 'create':
            menu = TkObject(self.master, '%s.%s' % (m, hook)) 
            menu.add('command', label="Waveform (sample)",
            command=lambda self=self, w=w, pane=pane: \
                     self.createWaveform(w,pane))

    def paneCreatedProc(self, w, pane):
        self.vars[pane] = {'drawWaveform': 0, 'channel': 'all'}
        self.Info['debug'] = self.tk.eval('eval list $::wsurf::Info(debug)')

    def paneDeletedProc(self, w, pane):
        del self.vars[pane]
        
    def createWaveform(self, w, pane):
        _w = TkObject(self.master, w)
        _pane = TkObject(self.master, \
                _w.addPane(before=pane, height=200, scrolled=0, \
                scrollheight=200, unit=""))
        self.addWaveform(_w, _pane)

    def addWaveform(self, w, pane, **kws):
        # Use a dictionary for args.
        a = {'channel': 'all', 'fill': 'black', 'limit': '-1', 'predraw': '0',
        'sectfftlength': '512', 'sectwintype': 'Hamming',
        'sectanalysistype': 'FFT', 'sectlpcorder': '20',
        'sectpreemphasis': '0.0', 'sectreference': '-110.0',
        'sectrange': '110.0', 'sectdoall': '0', 'sectexportheader': '0',
        'subsample': '1', 'trimstart': '1', 'scrollspeed': '250'}
        a.update(kws)

        v = self.vars[pane.name]
        v['channel']   = a['channel']
        v['wavecolor'] = a['fill']
        v['limit']     = a['limit']
        v['preDraw']   = a['predraw']
        v['sfftlen']   = a['sectfftlength']
        v['swintype']  = a['sectwintype']
        v['satype']    = a['sectanalysistype']
        v['slpcorder'] = a['sectlpcorder']
        v['spreemph']  = a['sectpreemphasis']
        v['sref']      = a['sectreference']
        v['srange']    = a['sectrange']
        v['sall']      = a['sectdoall']
        v['sexphead']  = a['sectexportheader']
        v['subsample'] = a['subsample']
        v['trimstart'] = a['trimstart']
        v['rtpps']     = a['scrollspeed']
        c = TkObject(self.master, pane.canvas())
        s = TkObject(self.master, w.cget('-sound'))
        v['topfr']     = float(s.cget('-rate'))/2
        try:
            if (int(a['channel']) in range(10) and \
               int(a['channel']) > int(s.cget('-channels'))):
                chan = 'all'
            else:
                chan = a['channel']
        except:
            chan = a['channel']
        if (int(w.getInfo('isLinked2File'))):
            filename = w.getInfo('filename')
            c.create('waveform', 0, 0, anchor='w', sound=s, channel=chan,
            tags='[list waveform analysis]', fill=a['fill'], end=0,
            limit=v['limit'], trimstart=v['trimstart'],
            shapefile=w._shapeFilename(filename), debug=self.Info['debug'])
        else:
            c.create('waveform', 0, 0, anchor='w', sound=s, channel=chan,
            tags='[list waveform analysis]', fill=a['fill'], end=0,
            limit=v['limit'], trimstart=v['trimstart'],
            debug=self.Info['debug'])
        if (int(s.cget('-channels')) > 1):
            v['max'] = s.max(channel=v['channel'])
            v['min'] = s.min(channel=v['channel'])
        else:
            v['max'] = s.max()
            v['min'] = s.min()

        v['drawWaveform'] = 1

    def redrawProc(self, w, pane):
        wsurf = TkObject(self.master, w)
        if wsurf.getInfo('isRecording') == '1':
            return
        _pane = TkObject(self.master, pane)
        c = TkObject(self.master, _pane.canvas())
        s = TkObject(self.master, wsurf.getSound())
        v = self.vars[pane]
        try:
            if (int(v['channel']) in range(10) and \
               int(v['channel']) >= int(s.cget('channels'))):
                chan = 'all'
            else:
                chan = v['channel']
        except:
            chan = v['channel']
        if (int(v['drawWaveform'])):
            wh = int(_pane.cget('-scrollheight'))
            mid = float(wh)/2
            maxtime = float(_pane.cget('-maxtime'))
            rate = float(s.cget('-rate'))
            pps = float(_pane.cget('-pixelspersecond'))
            cvx = float(c.canvasx(0.0))
            if int(v['preDraw']) == 0:
                (fracLeft, fracRight) = map(lambda x: float(x),
                c.xview().split())

                start = int(fracLeft * maxtime * rate + 1)
                end = int(fracRight * maxtime * rate + 1)
                len = end-start
                if (int(v['subsample']) and len > 1000000):
                    sub = 30
                elif (int(v['subsample']) and len > 100000):
                    sub = 10
                else:
                    sub = 1
                fi = cvx/pps * rate
                corr = (fi - int(fi))*pps / rate
                xpos = cvx-corr
                c.coords('waveform', xpos, mid)
                c.itemconfig('waveform', fill=v['wavecolor'], channel=chan,
                height=wh, pixelspersecond=pps, limit=v['limit'],
                trimstart=v['trimstart'], subsample=v['subsample'],
                start=start, end=end)
            else:
                c.coords('waveform', 0, mid)
                c.itemconfig('waveform', fill=v['wavecolor'], channel=chan,
                height=wh, pixelspersecond=pps, limit=v['limit'],
                start=0, end=-1)
            yc = TkObject(self.master, _pane.yaxis())
            yc.delete('axis')
            yc.create('text', 0, 0, text=v['max'],
            font=_pane.cget('-yaxisfont'), anchor='nw', tags='[list axis max]',
            fill=_pane.cget('-yaxiscolor'))
            yc.create('text', 0, _pane.cget('-height'), text=v['min'],
            font=_pane.cget('-yaxisfont'), anchor='sw', tags='[list axis min]',
            fill=_pane.cget('-yaxiscolor'))
    
    def getBoundsProc(self, w, pane):
        _w = TkObject(self.master, w)
        _pane = TkObject(self.master, pane)
        v = self.vars[pane]
        s = TkObject(self.master, _w.cget('-sound'))
        if (int(v['drawWaveform'])):
            _max = max(int(s.max()), -int(s.min()))
            _min = min(int(s.min()), -int(s.max()))
            return 'list 0 %d %s %d' % (_min, s.length(units='seconds'), _max)
        else:
            return 'list'

    def scrollProc(self, w, pane, frac1, frac2):
        _w = TkObject(self.master, w)
        _pane = TkObject(self.master, pane)
        s = TkObject(self.master, _w.cget('-sound'))
        c = TkObject(self.master, _pane.canvas())
        v = self.vars[pane]
        if (int(v['drawWaveform'])):
            wh = int(_pane.cget('-scrollheight'))
            mid = float(wh)/2
            maxtime = float(_pane.cget('-maxtime'))
            rate = float(s.cget('-rate'))
            pps = float(_pane.cget('-pixelspersecond'))
            cvx = float(c.canvasx(0.0))
            if int(v['preDraw']) == 0:
                start = int(float(frac1)*maxtime*rate+1)
                end = int(float(frac2)*maxtime*rate+1)
                len = end-start
                if (int(v['subsample']) and len > 1000000):
                    sub = 30
                elif (int(v['subsample']) and len > 100000):
                    sub = 10
                else:
                    sub = 1
                fi = cvx/pps * rate
                corr = (fi - int(fi))*pps / rate
                xpos = cvx-corr
                c.coords('waveform', xpos, mid)
                c.itemconfig('waveform', subsample=v['subsample'],
                start=start, end=end)
        
            
