program readpots

 use cml_pot

 implicit none 
 character(len=80) :: filename
 integer :: i

 print*, 'READPOT: init of potential_list'
 call potential_list_init()

 do i = 1, command_argument_count()

     call get_command_argument(i, filename)

     print*, 'READPOT: about to read from file: ', trim(filename)
     call cml_read_pots(trim(filename))
     print*, 'READPOT: all done for file: ', trim(filename)

 enddo

 print*, "READPOT: There are ", number_of_pots, " potentials loaded"

 do 
     if (.not.next_potential()) exit
     if (trim(get_potname()).eq.'mypotentialDict:buckingham') then
        print*, 'READPOT: A buckingham potential'
        if (find_parameter('gulp:buckingham.a').and.find_parameter('gulp:buckingham.roh') &
	       & .and.find_parameter('gulp:buckingham.c')) then
            print*, 'READPOT: a is: ',  get_parameter('gulp:buckingham.a')
            print*, 'READPOT: roh is: ',  get_parameter('gulp:buckingham.roh')
            print*, 'READPOT: c is: ',  get_parameter('gulp:buckingham.c')
        else 
            print*, 'READPOT: Parameters missing - malformed document?'
        endif 
    else
        print*, 'READPOT: Do not understand this potential form'
    endif

 enddo

 call potential_list_exit()
 print*, 'READPOT: exit of potential_list'


end program readpots

