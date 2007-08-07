module potential_list

 implicit none



type two_body_pot
     character :: name
     character(len=20), dimension(2) :: atoms
     real, pointer, dimension(:) :: parameters
     character(len=100), pointer, dimension(:) :: parameter_name
     character(len=20) :: potid 
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

     print*, "In add_potential"
     print*, "Called with atom1:", atom1
     print*, "atom2:", atom2
     print*, "parameters", parameters
     print*, parameter_name
     print*, potid

     allocate(new_pot)
     print*, "Done allocation"
     write_pointer%next_pot => new_pot
     write_pointer => write_pointer%next_pot
     print*, "pointers_moved"
     write_pointer%atoms(1) = atom1
     write_pointer%atoms(2) = atom2
     allocate(write_pointer%parameters(size(parameters)))
     allocate(write_pointer%parameter_name(size(parameter_name)))
     write_pointer%parameters(:) = parameters(:)
     write_pointer%parameter_name(:) = parameter_name(:)
     write_pointer%potid = potid

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
