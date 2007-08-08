module cml_pot

! This module just provides and interface needed to allow 
! sax parsing and recovery of data by the caller without
! having to use multiple modules. There may be a case 
! to provide some wrapper functons here

  use cml_pot_sax, only : cml_read_pots
  use cml_pot_data, only : next_potential, read_potential, number_of_pots, &
         & potential_list_init, potential_list_exit, get_parameter

end module cml_pot
