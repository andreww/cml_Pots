program readpots

 use cml_read_pot

 implicit none 
 character(len=80) :: filename

 call get_command_argument(1, filename)
 
 print*, 'READPOT: about to read from file: ', trim(filename)
 call cml_read_pots(trim(filename))
 print*, 'READPOT: all done for file: ', trim(filename)

end program readpots
