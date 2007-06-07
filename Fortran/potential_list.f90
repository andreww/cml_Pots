module potential_list

 implicit none

 private 
! public :: number_of_pots


type two_body_pot
     character :: name
     character(len=20), dimension(2) :: atoms
     real, pointer, dimension(:) :: parameters
     character(len=100), pointer, dimension(:) :: parameter_name
     character(len=20) :: potid 
     type(two_body_pot), pointer :: next_pot => null()
 end type two_body_pot

 type(two_body_pot), pointer :: first_pot
 type(two_body_pot), pointer :: read_pointer
 type(two_body_pot), pointer :: write_pointer

contains 

 subroutine potential_list_init()
     allocate (first_pot)
     read_pointer => first_pot
     write_pointer => write_pointer

 end subroutine potential_list_init

 subroutine  potential_list_exit()

  if (associated first_pot%next_pot) then
     ! Remove this pot, point first_pot at next_pot and try again
     
     deallocate(first_pot)
  else
     ! Just remove this pot and clean up globals 
  end if 

 end subroutine potential_list_exit


 subroutine add_potential (atom1, atom2, parameters, parameter_name, potid)

     character(len=*), intent(in) :: atom1, atom2
     real, pointer, dimension(:), intent(in) :: parameters
     character(len=*), pointer, dimension(:), intent(in) :: parameter_name
     character(len=*), intent(in) :: potid

     

 end subroutine add_potential

 subroutine read_next_potential(atom1, atom2, parameters, parameter_name, potid)

     character(len=*), intent(out) :: atom1, atom2
     real, pointer, dimension(:), intent(out) :: parameters
     character(len=*), pointer, dimension(:), intent(out) :: parameter_name
     character(len=*), intent(out) :: potid

 end subroutine read_next_potential
 

end module potential_list
