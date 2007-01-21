program readpots

 use cml_read_pot

 implicit none 

 print*, 'about to open small1.xml'
 call cml_read_pots('small1.xml')
 print*, "All done in test"

end program readpots
