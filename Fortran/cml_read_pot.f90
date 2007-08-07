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

 character(len=20) :: potid 

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
         read (chars, *) thisparam
         call add_potential_parameter(thisparam)
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
                 ! FIXME - Store this properly 
                 if (hasKey(attributes,"id")) then
                      potid = getValue(attributes, "", "id")
                 end if 
                 if (DEBUG) print*, "CML read DEBUG: And this has an ID: ", potid
                 call add_potential(trim(potid))
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
                     call add_potential_parameter_name(getValue(attributes, "", "dictRef"))
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
                     call add_potential_atom(getValue(attributes, "", "elementType"))
                     if (DEBUG) print*, "Atom type is:", getValue(attributes, "", "elementType")
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
              print*, "added pot"
          else if (localName == "atom") then
              if (DEBUG) print*, "CML read DEBUG: Out of atom"
              parser_state = parser_state - IN_ATOM
         end if
     end if

 end subroutine handle_endElement

end module cml_read_pot
