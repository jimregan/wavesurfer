load libsnack.dylib
sound s

pack [ttk::button .r -text "rec" -command "s rec"]
pack [ttk::button .s -text "stop" -command {s stop;puts [s info]}]
pack [ttk::button .p -text "play" -command "s play"]
