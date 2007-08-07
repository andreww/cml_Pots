cd FoX
./config/configure FC=g95
make
cd ..
g95  -Wall -g  -Wunused-vars -Wuninitialized -fbounds-check -ftrace=full -c cml_read_pot.f90 `./FoX/FoX-config --fcflags --sax`
g95 -Wall  -g  -Wunused-vars -Wuninitialized -fbounds-check -ftrace=full -c potential_list.f90
g95  -Wall -g  -Wunused-vars -Wuninitialized -fbounds-check -ftrace=full -c readpot.f03
g95  readpot.o cml_read_pot.o potential_list.o `./FoX/FoX-config --libs --sax` -g -o readpot
