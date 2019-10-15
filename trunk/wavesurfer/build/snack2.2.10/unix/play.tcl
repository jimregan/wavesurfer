load libsnack.dylib
sound s
# -channels 2 -encoding float -rate 16000
#s length 32000
s read long.wav
s read ../demos/tcl/ex1.wav
puts [s info]
s play
vwait xx

