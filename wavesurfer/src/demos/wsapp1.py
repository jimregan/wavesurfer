"""
Minimal example of a python application using the wsurf widget.
"""

from Tkinter import *
from Wsurf import *

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

ws=Wsurf(root,title='ABC',configuration='')
ws.pack(expand='yes',fill='both')


# Create minimal user interface

f0 = Frame(root)
f0.pack(pady=5)
Button(f0, image='snackOpen', command=load).pack(side='left')
Button(f0, text='Foo', command=stuff).pack(side='left')

root.mainloop()
