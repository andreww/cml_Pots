cd FoX
./config/configure FC=g95
make
cd ..
g95  -Wall -c cml_read_pot.f90 `./FoX/FoX-config --fcflags --sax`
g95  -Wall -c readpot.f03
g95  readpot.o cml_read_pot.o `./FoX/FoX-config --libs --sax` -o readpot
