"""
Minimal example of a python application using the wsurf widget
and wsurf plugins.
The code is copied from wsapp1.py, with just the additional sample plugin
"""

from Tkinter import *
from Wsurf import *
from WsurfPlugin import SamplePlugin

root=Tk()
root.tk.eval('package require -exact wsurf 1.8')


def load():
    file = root.tk.eval('snack::getOpenFile')
    ws.openFile(file)

# Some random commands
def stuff():
    ws.xscroll('moveto',0.01)
    ws.configure(selection='1.00 3.00')
    ws.configure(title='Test')
    ws.play(1.00,3.00)
    print ws.cget('selection')


# Pack a wsurf widget

#ws=Wsurf(root,title='ABC',configuration='/tmp/wavesurfer-1.0.3/wsurf1.0/configurations/Waveform.conf')

ws=Wsurf(root,title='ABC',configuration='')
ws.pack(expand='yes',fill='both')

# Instantiate a plugin and register it.
plugin=SamplePlugin()
plugin.register(ws)

# Create minimal user interface

f0 = Frame(root)
f0.pack(pady=5)
Button(f0, image='snackOpen', command=load).pack(side='left')
Button(f0, text='Foo', command=stuff).pack(side='left')

root.mainloop()
