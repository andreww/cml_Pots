module potential_list

 implicit none

integer:: number_of_pots 

integer, parameter :: PARAMETER_NAME_LENGTH = 100
integer, parameter :: POTID_LENGTH = 20
integer, parameter :: ATOM_NAME_LENGTH = 20

type two_body_pot
     character :: name
     character(len=ATOM_NAME_LENGTH), dimension(2) :: atoms
     real, pointer, dimension(:) :: parameters
     character(len=PARAMETER_NAME_LENGTH), pointer, dimension(:) :: parameter_name
     character(len=POTID_LENGTH) :: potid 
     type(two_body_pot), pointer :: next_pot => null()
 end type two_body_pot

 type(two_body_pot), pointer :: root_pot
 type(two_body_pot), pointer :: read_pointer
 type(two_body_pot), pointer :: write_pointer

contains 

 subroutine potential_list_init()
     print*, "In potential_list_init"
     allocate (root_pot)
     read_pointer => root_pot
     write_pointer => root_pot
     number_of_pots = 0

 end subroutine potential_list_init

 subroutine  potential_list_exit()
     print*, "In potential_list_exit"

     if (associated(root_pot%next_pot)) then
     ! Remove this pot, point first_pot at next_pot and try again
         call remove_pots(root_pot%next_pot)
     endif
!  deallocate(read_pointer)
!  deallocate(write_pointer)
     deallocate(root_pot)
     number_of_pots = 0

 end subroutine potential_list_exit

 recursive subroutine remove_pots (this_pot)

     type(two_body_pot), pointer :: this_pot

     print*, "In remove_pots"

     if (associated(this_pot%next_pot)) then
         call remove_pots(this_pot%next_pot)
     endif
     deallocate(this_pot%parameters)
     deallocate(this_pot%parameter_name)
     deallocate(this_pot)

 end subroutine remove_pots


 subroutine add_potential (atom1, atom2, parameters, parameter_name, potid)

     character(len=*), intent(in) :: atom1, atom2
     real, dimension(:), intent(in) :: parameters
     character(len=*), dimension(:), intent(in) :: parameter_name
     character(len=*), intent(in) :: potid

     type(two_body_pot), pointer :: new_pot


     allocate(new_pot)
     allocate(new_pot%parameters(size(parameters)))
     allocate(new_pot%parameter_name(size(parameter_name)))

     write_pointer%next_pot => new_pot
     write_pointer => new_pot%next_pot

     new_pot%atoms(1) = atom1
     new_pot%atoms(2) = atom2
     new_pot%parameters(:) = parameters(:)
     new_pot%parameter_name(:) = parameter_name(:)
     new_pot%potid = potid

     number_of_pots = number_of_pots + 1

 end subroutine add_potential

 subroutine read_next_potential(atom1, atom2, parameters, parameter_name, potid)

     character(len=*), intent(out) :: atom1, atom2
     real, dimension(:), intent(out) :: parameters
     character(len=*), dimension(:), intent(out) :: parameter_name
     character(len=*), intent(out) :: potid

     print*, "In read_next_potential"

     if (associated(read_pointer%next_pot)) then
         read_pointer => read_pointer%next_pot
         atom1 = read_pointer%atoms(1)
         atom2 = read_pointer%atoms(2)
         parameters(:) = read_pointer%parameters(:)
         parameter_name(:) = read_pointer%parameter_name(:)
         potid = read_pointer%potid
     else
         stop "Cannot read from unwritten potential"
     endif

 end subroutine read_next_potential
 

end module potential_list
