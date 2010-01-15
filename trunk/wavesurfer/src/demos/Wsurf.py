"""
A Python wrapper for WaveSurfer
Author: Kazuaki Maeda

Updated 8/18/2004
"""

from Tkinter import *

class BaseWsurf:
    """a mixin class for Wsurf"""
    def SetDefaultPrefs(self):
        self.tk.call('wsurf::SetDefaultPrefs')
    def SetPreference(self, pref, val):
        self.tk.call('wsurf::SetPreference', pref, val)
    def GetPreference(self, pref):
        return self.tk.call('wsurf::GetPreference', pref)
    def AddEvent(self, name, binding):
        self.tk.call('wsurf::AddEvent', name, binding)
    def GetStandardConfigurations(self):
        return self.tk.call('wsurf::GetStandardConfigurations')
    def GetLocalConfigurations(self):
        return self.tk.call('wsurf::GetLocalConfigurations')
    def GetConfigurations(self):
        return self.tk.call('wsurf::GetConfigurations')
    def ChooseConfigurationDialog(self):
        return self.tk.call('wsurf::ChooseConfigurationDialog')
    def CreateUniqueTitle(self, title):
        return self.tk.call('wsurf::CreateUniqueTitle', title)
    def GetWidgetPath(self, name):
        return self.tk.call('wsurf::GetWidgetPath', name)
    def GetCurrent(self):
        return self.tk.call('wsurf::GetCurrent')
    def MakeCurrent(self):
        return self.tk.call('wsurf::MakeCurrent', self._w)
    def NeedSave(self):
        return self.tk.call('wsurf::NeedSave')
    def GetPreferences(self):
        return self.tk.call('wsurf::GetPreferences')
    def GetPreferencePages(self):
        return self.tk.call('wsurf::PreferencePages')
    def AddPreferencePage(self, title, pageProc, applyProc, getProc, defProc):
        return self.tk.call('wsurf::AddPreferencePage',
                            title, pageProc, applyProc, getProc, defProc)
    def PrepareUndo(self, undoCmd, redoCmd):
        return self.tk.call('wsurf::PrepareUndo', undoCmd, redoCmd)
    def Initialize(self, *args):
        apply(self.tk.call, ('::wsurf::Initialize',)+args)


class Wsurf(Widget, BaseWsurf):
    """ Class definition for Wsurf widget """
    
    def __init__(self, master=None, cnf={}, **kw):
	"""Construct a Wsurf widget.

	Valid resource names: state, icons, messageproc,
	progressproc, slaves, isslave, collapser, sound,
	configuration, playmapfilter, title
	"""
	Widget.__init__(self, master, 'wsurf', cnf, kw)
    def xzoom(self, frac1, frac2):
	self.tk.call(self._w, 'xzoom', frac1, frac2)
    def zoomToSelection(self):
	self.tk.call(self._w, 'zoomToSelection');
    def create(self,*args):
	apply(self.tk.call, (self._w, 'create')+args)
    def xscroll(self,*args): 
	apply(self.tk.call, (self._w, 'xscroll')+args)
    def xscroll_moveto(self, *args):
    	apply(self.tk.call, (self._w, 'xscroll', 'moveto')+args)
    def updateBounds(self):
	self.tk.call(self._w, 'updateBounds')
    def formatTime(self,t):
	return self.tk.call(self._w, 'formatTime', t)
    def popupMenu(self,X,Y,x,y,pane=''):
	self.tk.call(self._w, 'popupMenu', X, Y, x, y, pane)
    def loadConfiguration(self,configFile):
	self.tk.call(self._w, 'loadConfiguration', configFile)
    def addPane(self, cnf={}, **kw):
        return Pane(self, cnf, kw)
    def deletePane(self, pane):
	self.tk.call(self._w, 'deletePane', pane)
    def loadConfiguration(self):
	self.tk.call(self._w, 'loadConfiguration')
    def saveConfiguration(self):
	self.tk.call(self._w, 'saveConfiguration')
    def applyConfiguration(self,conf):
	self.tk.call(self._w, 'applyConfiguration', conf)
    def play(self, start=-1, end=-1):
	self.tk.call(self._w, 'play', start, end)
    def playall(self):
	self.tk.call(self._w, 'playall')
    def playcont(self): 
	self.tk.call(self._w, 'playcont')
    def playvisib(self): 
	self.tk.call(self._w, 'playvisib')
    def playPopupMenu(self,X,Y):
	self.tk.call(self._w, 'playPopupMenu', X, Y)
    def playDone(self):
	self.tk.call(self._w, 'playDone')
    def pause(self):
	self.tk.call(self._w, 'pause')
    def record(self):
	self.tk.call(self._w, 'record')
    def stop(self):
	self.tk.call(self._w, 'stop')
    def printDialog(self):
	self.tk.call(self._w, 'printDialog')
    def print_print(self):
	self.tk.call(self._w, 'print', 'print')
    def print_preview(self):
	self.tk.call(self._w, 'print', 'preview')
    def print_save(self):
	self.tk.call(self._w, 'print', 'save')
    def needSave(self):
	self.tk.call(self._w, 'needSave')
    def closeWidget(self):
	self.tk.call(self._w, 'closeWidget')
    def messageProc(self, message, sender='anonymous'): 
	self.tk.call(self._w, 'messageProc', message, sender)
    def openFile(self, fileName, guessRate=16000, guessEnc="lin16",
		 guessChan=1, guessByteOrder='little', guessSkip=0,
		 fileformat=""):
	self.tk.call(self._w, 'openFile', fileName, guessRate,
		     guessEnc, guessChan, guessByteOrder,
		     guessSkip, fileformat)
    def saveFile(self, fileName):
	self.tk.call(self._w, 'saveFile', fileName)
    def new(self):
        self.tk.call(self._w, 'new')
    def undo(self):
	self.tk.call(self._w, 'undo')
    def cut(self, soundObj):
	self.tk.call(self._w, 'cut', soundObj)
    def copy(self,soundObj):
	self.tk.call(self._w, 'copy', soundObj)
    def paste(self,soundObj):
	self.tk.call(self._w, 'paste', soundObj)
    def getSound(self):
	return self.tk.call(self._w, 'getSound')
    def findPane(self,path):
	return self.tk.call(self._w, 'findPane', path)
    def getInfo(self,property):
	return self.tk.call(self._w, 'getInfo', property)
    def dump(self, pattern='*', subpattern='*'):
	self.tk.call(self._w, 'dump', pattern, subpattern)

    ## a few convenience methods
    def analysis_addWaveform(self, pane, cnf={}, **kw):
        return self.tk.call((self._w, 'analysis::addWaveform', pane)
                            + self._options(cnf, kw))

    def timeaxis_addTimeAxis(self, pane, cnf={}, **kw):
        return self.tk.call((self._w, 'timeaxis::addTimeAxis', pane)
                            + self._options(cnf, kw))

    def analysis_widgetCreated(self, pane):
        return self.tk.call(self._w, 'analysis::widgetCreated', pane)
    def analysis_widgetDeleted(self, pane):
        return self.tk.call(self._w, 'analysis::widgetDeleted', pane)
    def analysis_createSpectrogram(self, pane):
        return self.tk.call(self._w, 'analysis::createSpecrogram', pane)
    def analysis_createWaveform(self, pane):
        return self.tk.call(self._w, 'analysis::createWavefrom', pane)
    def analysis_createPitch(self, pane):
        return self.tk.call(self._w, 'analysis::createPitch', pane)
    def _getPanes(self):
        return self.tk.splitlist(self.tk.call(self._w, '_getPanes'))
    getPanes = _getPanes

class Pane(BaseWidget):
    """Class definition for panes used in Wsurf """
    
    def __init__(self, masterWsurf, cnf={}, kw={}):
        pane = masterWsurf.tk.call((masterWsurf._w, 'addPane')
                                   + self._options(cnf, kw))
        self._w = pane
        self.widgetName = 'Pane'
        self.master = masterWsurf
        self.tk = masterWsurf.tk
        name = None
        if cnf.has_key('name'):
            name = cnf['name']
            del cnf['name']
        if not name:
            name = `id(self)`
        self._name = name
        self.children = {}
        if self.master.children.has_key(self._name):
            self.master.children[self._name].destroy()
        self.master.children[self._name] = self

    def __del__(self):
        self.master.deletePane(self)

    def destroy(self):
        self.master.deletePane(self)

