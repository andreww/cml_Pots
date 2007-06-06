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
 end type two_body_pot

contains 

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
