
g95  -c cml_read_pot.f90 `./FoX/FoX-config --fcflags --sax`
g95  -c readpot.f90
g95  readpot.o cml_read_pot.o `./FoX/FoX-config --libs --sax` -o readpot
