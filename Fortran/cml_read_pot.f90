module cml_read_pot

 use FoX_sax
 use potential_list
 implicit none

 private 
 public :: cml_read_pots 

 logical, parameter :: DEBUG = .false.

 ! Sate for the SAX parser
 ! Known states:
 integer, parameter :: OUTSIDE_BLOCK = 0
 integer, parameter :: IN_POTENTIALLIST = 1
 integer, parameter :: IN_POTENTIAL = 2
 integer, parameter :: IN_ARG = 4
 integer, parameter :: IN_SCALAR = 8
 integer, parameter :: IN_PARAMETER = 16
 integer, parameter :: IN_ATOMARRAY = 32
 integer, parameter :: IN_ATOM = 64 

 ! Current state:
 integer, save :: parser_state = OUTSIDE_BLOCK

 ! CML namespace:
 character(len=29), parameter :: cmlns = 'http://www.xml-cml.org/schema'

 ! Opaque XML type for the parser:
 type(xml_t), save :: xp

 ! FIXME - this structure should be replaced with functions to add bits 
 ! at a time to the potential_list
 type two_body_pot_local
     character :: name
     character(len=20), dimension(2) :: atoms
     real, dimension(4) :: parameters
     character(len=100), dimension(4) :: parameter_name
     character(len=20) :: potid 
 end type two_body_pot_local

 character(len=20), dimension(2) :: atom_names
 character(len=20) :: potid 

 ! State for current potential.
 type(two_body_pot_local), save :: curpot
 integer, save :: next_pot_param = 1
 integer, save :: next_pot_atom = 1
 integer, save :: next_parameter_name = 1

contains

!===============================================================================!
!                                                                               !
!                                   == PUBLIC SUBS ==                           !
!                                                                               !
!===============================================================================!

 subroutine cml_read_pots(filename)

      character(len=*) :: filename
      integer :: iostat
 
      call open_xml_file(xp, filename, iostat)
      ! TODO probably need to check iostat in case of read errors. Otherwise will
      !      get runtime crash if filename does not exist or whatever.
      call parse(xp, characters_handler=handle_chars, &
             &   startDocument_handler=handle_docStart, &
             &   startElement_handler=handle_startElement, &
             &   endElement_handler=handle_endElement)
      call close_xml_t(xp)

 end subroutine cml_read_pots

!===============================================================================!
!                                                                               !
!                                   == PRIVATE SUBS  ==                         !
!                                                                               !
!===============================================================================!

 subroutine init_curpot
      implicit none

      curpot%name = ""
      curpot%atoms(1) = ""
      curpot%atoms(2) = ""
      curpot%parameters = (/0.0,0.0,0.0,0.0/)
      curpot%potid =""

      next_pot_param = 1
      next_pot_atom = 1
      next_parameter_name = 1
 end subroutine init_curpot

 subroutine dump_curpot
      implicit none
      print*, "==================================================================="
      print*, "CURPOT has the following elements"
      print*, "Name: ", trim(curpot%name)
      print*, "First atom: ", trim(curpot%atoms(1))
      print*, "Second atom: ", trim(curpot%atoms(2))
      print*, "Param1: (", trim(curpot%parameter_name(1)), "): ", curpot%parameters(1)
      print*, "Param2: (",  trim(curpot%parameter_name(2)), "): ", curpot%parameters(2)
      print*, "Param3: (",  trim(curpot%parameter_name(3)), "): ", curpot%parameters(3)
      print*, "Param4: (",  trim(curpot%parameter_name(4)), "): ", curpot%parameters(4)
      print*, "PotID: ", trim(curpot%potid)
      print*, "==================================================================="
 end subroutine dump_curpot

! subroutine add_curpot
!      implicit none
!      print*, "about to add pot"
!      call add_potential(trim(curpot%atoms(1)), trim(curpot%atoms(2)), curpot%parameters, & 
!              & curpot%parameter_name, trim(curpot%potid))
!      print*, "added pot"
! end subroutine add_curpot

!===============================================================================!
!                                                                               !
!                                   == SAX CALLBACKS  ==                        !
!                                                                               !
!===============================================================================!

 subroutine handle_docStart

      if (DEBUG) print*, "CML read DEBUG: At start of document"

 end subroutine handle_docStart

 
 subroutine handle_chars(chars)

      character(len=*), intent(in) :: chars

      real :: thisparam
  
         if (DEBUG) print*, "CML read DEBUG: HANDLE_CHARS was called with parser_state:  ", parser_state
      if (parser_state == (OUTSIDE_BLOCK + IN_POTENTIALLIST + IN_POTENTIAL + IN_ARG + IN_SCALAR) ) then 
         if (DEBUG) print*, "CML read DEBUG: HANDLE_CHARS was called for argument: ", chars
      elseif (parser_state == (OUTSIDE_BLOCK + IN_POTENTIALLIST + IN_POTENTIAL + IN_PARAMETER + IN_SCALAR) ) then 
         if (DEBUG) print*, "CML read DEBUG: HANDLE_CHARS was called for parameters: ", chars
         !read (chars, *) curpot%parameters(next_pot_param)
         read (chars, *) thisparam
         call add_potential_parameter(thisparam)
         !if (DEBUG) print*, "debug real is: ", curpot%parameters(next_pot_param)
         next_pot_param = next_pot_param + 1
      end if

 end subroutine handle_chars


 subroutine handle_startElement(namespaceURI, localName, QName, attributes)
      character(len=*), intent(in) :: namespaceURI
      character(len=*), intent(in) :: localName
      character(len=*), intent(in) :: QName
      type(dictionary_t), intent(in) :: attributes

      ! We are not intrested in other namespaces
      if (namespaceURI /= CMLNS) then
          ! DO NOTHING
      !
      ! Ok then, is this the start of an intresting chunk of 
      ! XML?
      !
      else if ((localName == 'potentialList').and.(parser_state == OUTSIDE_BLOCK)) then
         if (DEBUG) print*, "CML read DEBUG: Now in Potential list"
         parser_state = parser_state + IN_POTENTIALLIST
      !
      ! Are we in a chunk of XML that is intresting
      ! (a desendent of a potentialList)? If so we may want to change state and / or
      !  grab intresting attributes if we are in an intresting state
      !  Note - attributes only have namespaces if they are given them explicitly!
      !
      else if (parser_state.ge.(OUTSIDE_BLOCK+IN_POTENTIALLIST)) then
          if (localName == 'potentialList') then
                ! FIXME Should handle this stop nicly
                stop "Nested Potential lists are BAD - stopping FIXME"
          else if (localName =='potential') then
               if (DEBUG) print*, "CML read DEBUG: A pot to work with"
               parser_state = parser_state + IN_POTENTIAL
               if (parser_state == OUTSIDE_BLOCK + IN_POTENTIALLIST + IN_POTENTIAL) then
                 if (DEBUG) print*, "************** NEWPOT - parser_state is: ", parser_state, "****************"
                 call init_curpot
                 ! FIXME - Store this properly 
                 if (hasKey(attributes,"id")) then
                      potid = getValue(attributes, "", "id")
                 end if 
                 if (DEBUG) print*, "CML read DEBUG: And this has an ID: ", curpot%potid
               end if
          else if (localName == "arg") then
               parser_state = parser_state + IN_ARG
               if (DEBUG) print*, "CML read DEBUG: In an argument"
          else if (localName == "scalar") then
               parser_state = parser_state + IN_SCALAR
               if (DEBUG) print*, "CML read DEBUG: In a scalar"
          else if (localName == "parameter") then 
               parser_state = parser_state + IN_PARAMETER
               if (DEBUG) print*, "CML read DEBUG: In a parameter"
              if (parser_state == OUTSIDE_BLOCK + IN_POTENTIALLIST + IN_POTENTIAL &
                   & + IN_PARAMETER) then
                if (hasKey(attributes, "dictRef")) then
                     ! FIXME - store these properly 
                     call add_potential_parameter_name(getValue(attributes, "", "dictRef"))
                     !curpot%parameter_name(next_parameter_name) = getValue(attributes, "", "dictRef")
                     !next_parameter_name = next_parameter_name + 1
                end if 
              end if
          else if (localName == "atomArray") then
              if (DEBUG) print*, "CML read DEBUG: In an atomArray"
              parser_state = parser_state + IN_ATOMARRAY
          else if (localName == "atom") then
              if (DEBUG) print*, "CML read DEBUG: In an atom"
              parser_state = parser_state + IN_ATOM
              if (parser_state == OUTSIDE_BLOCK + IN_POTENTIALLIST + IN_POTENTIAL &
                   & + IN_ATOMARRAY + IN_ATOM) then
                if (hasKey(attributes, "elementType")) then
                     ! FIXME - store these properly 
                     atom_names(next_pot_atom) = getValue(attributes, "", "elementType")
                     if (DEBUG) print*, "Atom type is:", atom_names(next_pot_atom)
                     next_pot_atom = next_pot_atom + 1
                end if 
              end if
          end if


     end if

 end subroutine handle_startElement


 subroutine handle_endElement(namespaceURI, localName, QName)
     character(len=*), intent(in) :: namespaceURI
     character(len=*), intent(in) :: localName
     character(len=*), intent(in) :: QName

     ! We are not intrested in other namespaces
     if (namespaceURI /= CMLNS) return

     if (parser_state.ge.(OUTSIDE_BLOCK + IN_POTENTIALLIST)) then
         if ((localName == 'potentialList').and.(namespaceURI == CMLNS)) then
              parser_state = parser_state - IN_POTENTIALLIST
              if (DEBUG) print*, "CML read DEBUG: Out of Pot list"
          else if ((localName =='potential').and.(namespaceURI == CMLNS)) then
              if (DEBUG) print*, "CML read DEBUG: Out of potential"
              parser_state = parser_state - IN_POTENTIAL
              !call dump_curpot
              !call add_curpot
          else if ((localName == "arg").and.(namespaceURI == CMLNS)) then
              if (DEBUG) print*, "CML read DEBUG: Out of arg"
              parser_state = parser_state - IN_ARG
          else if ((localName == "scalar").and.(namespaceURI == CMLNS)) then
              if (DEBUG) print*, "CML read DEBUG: Out of scalar"
              parser_state = parser_state - IN_SCALAR
          else if ((localName == "parameter").and.(namespaceURI == CMLNS)) then
              if (DEBUG) print*, "CML read DEBUG: Out of parameter"
              parser_state = parser_state - IN_PARAMETER
          else if (localName == "atomArray") then
              if (DEBUG) print*, "CML read DEBUG: Out of atomArray"
              parser_state = parser_state - IN_ATOMARRAY
              print*, "about to add pot"
              call add_potential(trim(atom_names(1)), trim(atom_names(2)), & 
                  & trim(potid))
              print*, "added pot"
          else if (localName == "atom") then
              if (DEBUG) print*, "CML read DEBUG: Out of atom"
              parser_state = parser_state - IN_ATOM
         end if
     end if

 end subroutine handle_endElement

end module cml_read_pot
