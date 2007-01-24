program readpots

 use cml_read_pot

 implicit none 

 print*, 'about to open buck.xml'
 call cml_read_pots('buck.xml')
 print*, "All done in test"

end program readpots
