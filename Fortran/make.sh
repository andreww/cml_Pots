cd FoX
./config/configure FC=g95
make
cd ..
g95  -Wall -g  -Wunused-vars -Wuninitialized -fbounds-check -ftrace=full -c cml_read_pot_data.f90
g95  -Wall -g  -Wunused-vars -Wuninitialized -fbounds-check -ftrace=full -c cml_read_pot_sax.f90 `./FoX/FoX-config --fcflags --sax`
g95  -Wall -g  -Wunused-vars -Wuninitialized -fbounds-check -ftrace=full -c cml_read_pot_interface.f90 
g95  -Wall -g  -Wunused-vars -Wuninitialized -fbounds-check -ftrace=full -c readpot.f03
g95  *.o `./FoX/FoX-config --libs --sax` -g -o readpot
