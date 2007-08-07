module two_body_pot_str

 implicit none

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

end module two_body_pot_str
