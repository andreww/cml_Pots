module cml_pot_data


 implicit none


 private 
 public :: number_of_pots, potential_list_init, potential_list_exit, &
      &    read_potential, add_potential, next_potential, &
      &    add_potential_parameter, add_potential_parameter_name, &
      &    add_potential_atom, get_parameter, find_parameter, &
      &    two_body_pot, PARAMETER_NAME_LENGTH, POTID_LENGTH, &
      &    ATOM_NAME_LENGTH

 integer:: number_of_pots 


  integer, parameter :: PARAMETER_NAME_LENGTH = 100
  integer, parameter :: POTID_LENGTH = 20
  integer, parameter :: ATOM_NAME_LENGTH = 20

  type two_body_pot
      character :: name
      character(len=ATOM_NAME_LENGTH), pointer, dimension(:) :: atoms
      real, pointer, dimension(:) :: parameters
      character(len=PARAMETER_NAME_LENGTH), pointer, dimension(:) :: parameter_name
      character(len=POTID_LENGTH) :: potid 
      type(two_body_pot), pointer :: next_pot => null()
  end type two_body_pot


 type(two_body_pot), pointer :: root_pot
 type(two_body_pot), pointer :: read_pointer
 type(two_body_pot), pointer :: write_pointer

contains 

!===============================================================================!
!                                                                               !
!                                   == PUBLIC SUBS ==                           !
!                                                                               !
!===============================================================================!

 subroutine potential_list_init()

     allocate (root_pot)
     read_pointer => root_pot
     write_pointer => root_pot
     number_of_pots = 0

 end subroutine potential_list_init

 subroutine  potential_list_exit()

     if (associated(root_pot%next_pot)) then
     ! Remove this pot, point first_pot at next_pot and try again
         call remove_pots(root_pot%next_pot)
     endif
!  deallocate(read_pointer)
!  deallocate(write_pointer)
     deallocate(root_pot)
     number_of_pots = 0

 end subroutine potential_list_exit


 subroutine add_potential (potid)

     character(len=*), intent(in) :: potid

     type(two_body_pot), pointer :: new_pot

     allocate(new_pot)

     write_pointer%next_pot => new_pot
     write_pointer => new_pot

     new_pot%potid = potid

     number_of_pots = number_of_pots + 1

 end subroutine add_potential

 subroutine add_potential_atom(atom_name)
    character(len=*), intent(in) :: atom_name

    character(len=ATOM_NAME_LENGTH), dimension(:), allocatable :: tmp_atoms
    integer :: atoms_size

    if (associated(write_pointer%atoms)) then
        atoms_size = size(write_pointer%atoms)
        allocate(tmp_atoms(atoms_size))
        tmp_atoms = write_pointer%atoms
        deallocate(write_pointer%atoms)
        allocate(write_pointer%atoms(atoms_size+1))
        write_pointer%atoms(1:atoms_size) = tmp_atoms(:)
        write_pointer%atoms(atoms_size+1) = atom_name
        deallocate(tmp_atoms)
    else
        allocate(write_pointer%atoms(1))
        write_pointer%atoms(1) = atom_name
    endif
 end subroutine add_potential_atom

 subroutine add_potential_parameter(param)
    real, intent(in) :: param

    real, dimension(:), allocatable :: tmp_params
    integer :: params_size

    if (associated(write_pointer%parameters)) then
        params_size = size(write_pointer%parameters)
        allocate(tmp_params(params_size))
        tmp_params = write_pointer%parameters
        deallocate(write_pointer%parameters)
        allocate(write_pointer%parameters(params_size+1))
        write_pointer%parameters(1:params_size) = tmp_params(:)
        write_pointer%parameters(params_size+1) = param
        deallocate(tmp_params)
    else
        allocate(write_pointer%parameters(1))
        write_pointer%parameters(1) = param
    endif
 end subroutine add_potential_parameter

 subroutine add_potential_parameter_name(param_name)
    character(len=*), intent(in) :: param_name

    character(len=PARAMETER_NAME_LENGTH), dimension(:), allocatable :: tmp_params
    integer :: params_size

    if (associated(write_pointer%parameter_name)) then
        params_size = size(write_pointer%parameter_name)
        allocate(tmp_params(params_size))
        tmp_params = write_pointer%parameter_name
        deallocate(write_pointer%parameter_name)
        allocate(write_pointer%parameter_name(params_size+1))
        write_pointer%parameter_name(1:params_size) = tmp_params(:)
        write_pointer%parameter_name(params_size+1) = param_name
        deallocate(tmp_params)
    else
        allocate(write_pointer%parameter_name(1))
        write_pointer%parameter_name(1) = param_name
    endif
 end subroutine add_potential_parameter_name

 subroutine read_potential(atom1, atom2, parameters, parameter_name, potid)

     character(len=*), intent(out) :: atom1, atom2
     real, dimension(:), intent(out) :: parameters
     character(len=*), dimension(:), intent(out) :: parameter_name
     character(len=*), intent(out) :: potid

     atom1 = read_pointer%atoms(1)
     atom2 = read_pointer%atoms(2)
     parameters(:) = read_pointer%parameters(:)
     print*, read_pointer%parameter_name(:)
     parameter_name(:) = read_pointer%parameter_name(:)
     potid = read_pointer%potid

 end subroutine read_potential

 logical function next_potential()

     if (associated(read_pointer%next_pot)) then
         read_pointer => read_pointer%next_pot
         next_potential = .true.
     else
         next_potential = .false.
     endif
 end function next_potential

 logical function find_parameter(parameter_name)

     character(len=*), intent(in) :: parameter_name

     integer :: num_params
     integer :: num_params_names 
     integer :: i

     find_parameter = .false.

     num_params = size(read_pointer%parameters)
     num_params_names = size(read_pointer%parameter_name)

     if (num_params.ne.num_params_names) then
         stop "Internal error in cml_pot_data, get_parameter: array length missmatch"
     endif

     do i = 1, num_params
        if ( trim(read_pointer%parameter_name(i)) .eq. trim(parameter_name) ) then
            find_parameter = .true.
            exit
        endif
     enddo

 end function find_parameter


 real function get_parameter(parameter_name)

     character(len=*), intent(in) :: parameter_name

     integer :: num_params
     integer :: num_params_names 
     integer :: i

     num_params = size(read_pointer%parameters)
     num_params_names = size(read_pointer%parameter_name)

     if (num_params.ne.num_params_names) then
         stop "Internal error in cml_pot_data, get_parameter: array length missmatch"
     endif

     do i = 1, num_params
        if ( trim(read_pointer%parameter_name(i)) .eq. trim(parameter_name) ) then
            get_parameter = read_pointer%parameters(i)
            exit
        endif
     enddo

 end function get_parameter
     

!===============================================================================!
!                                                                               !
!                                   == PRIVATE SUBS ==                          !
!                                                                               !
!===============================================================================!

 recursive subroutine remove_pots (this_pot)

     type(two_body_pot), pointer :: this_pot

     print*, "In remove_pots"

     if (associated(this_pot%next_pot)) then
         call remove_pots(this_pot%next_pot)
     endif
     deallocate(this_pot%parameters)
     deallocate(this_pot%parameter_name)
     deallocate(this_pot%atoms)
     deallocate(this_pot)

 end subroutine remove_pots

end module cml_pot_data
