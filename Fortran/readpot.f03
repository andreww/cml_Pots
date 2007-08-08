program readpots

 use cml_pot

 implicit none 
 character(len=80) :: filename

 call get_command_argument(1, filename)

 print*, 'READPOT: init of potential_list'
 call potential_list_init()

 print*, 'READPOT: about to read from file: ', trim(filename)
 call cml_read_pots(trim(filename))
 print*, 'READPOT: all done for file: ', trim(filename)

 call reportpot()

 print*, 'READPOT: exit of potential_list'
 call potential_list_exit()

contains 

subroutine reportpot()

 character(len=20) :: atom1, atom2, potid
 character(len=100), dimension(3) :: parameter_name
 real, dimension(3) :: parameters
 real :: roh

 print*, "There are ", number_of_pots, " potentials loaded"

 do 
     if (.not.next_potential()) exit
     print*, "Get potname returned: " ,get_potname()
     if (trim(get_potname()).eq.'mypotentialDict:buckingham') then
        if (find_parameter('gulp:buckingham.roh')) then
            roh = get_parameter('gulp:buckingham.roh')
            print*, 'roh is: ',  roh
        else 
            print*, 'roh not found'
        endif 
    else
        print*, 'Do not understand this potential form'
    endif

 enddo

end subroutine reportpot

end program readpots

