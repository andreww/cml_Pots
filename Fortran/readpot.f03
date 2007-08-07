program readpots

 use cml_read_pot
 use potential_list

 implicit none 
 character(len=80) :: filename

 call get_command_argument(1, filename)

 print*, 'READPOT: init of potential_list'
 call potential_list_init()

 print*, 'READPOT: about to read from file: ', trim(filename)
 call cml_read_pots(trim(filename))
 print*, 'READPOT: all done for file: ', trim(filename)

 print*, 'READPOT: exit of potential_list'
 call potential_list_exit()

end program readpots
