module cml_read_pot

 use FoX_sax
 implicit none


 ! Sate of the SAX parser
 ! This should only ever increse or decrese by one and should never 
 ! transform between two of the same values.
 integer, save :: parser_state = 0

 integer, parameter :: IN_POTENTIALLIST = 1
 integer, parameter :: IN_POTENTIAL = 2
 integer, parameter :: IN_ARG = 4
 integer, parameter :: IN_SCALAR = 8
 integer, parameter :: IN_PARAMETER = 16
 
 ! CML namespace
 character(len=29), parameter :: cmlns = 'http://www.xml-cml.org/schema'

 ! State for current potential.
 character(len=20), save :: potid   ! The ID of the potential being looked at...

 type(xml_t), save :: xp

 type two_body_pot
     character :: name
     character :: atom_1
     character :: atom_2
     real, dimension(4) :: parameters
 end type two_body_pot


contains

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

 subroutine handle_docStart

  print*, "CML read DEBUG: At start of document"

 end subroutine handle_docStart
 
 subroutine handle_chars(chars)

  character(len=*), intent(in) :: chars
  
   print*, "CML read DEBUG: HANDLE_CHARS was called with parser_state:  ", parser_state
  if (parser_state == (IN_POTENTIALLIST + IN_POTENTIAL + IN_ARG + IN_SCALAR) ) then 
   print*, "CML read DEBUG: HANDLE_CHARS was called for argument: ", chars
  elseif (parser_state == (IN_POTENTIALLIST + IN_POTENTIAL + IN_PARAMETER + IN_SCALAR) ) then 
   print*, "CML read DEBUG: HANDLE_CHARS was called for parameters: ", chars
  end if

 end subroutine handle_chars

 subroutine handle_startElement(namespaceURI, localName, QName, attributes)
      character(len=*), intent(in) :: namespaceURI
      character(len=*), intent(in) :: localName
      character(len=*), intent(in) :: QName
      type(dictionary_t), intent(in) :: attributes

      
!
! Are we in a chunk of XML that is intresting
! (a desendent of a potentialList AND in the 
! XML namespace
!
     if ((parser_state.ge.IN_POTENTIALLIST).and.(namespaceURI == CMLNS)) then
          if (localName == 'potentialList') then
                stop "Nested Potential lists are BAD - stopping FIXME"
! FIXME Should handle this stop nicly
          else if (localName =='potential') then
               print*, "CML read DEBUG: A pot to work with"
               parser_state = parser_state + IN_POTENTIAL
               potid = ""
               if (hasKey(attributes,"id")) then
!  Note - attributes only have namespaces if they are given them explicitly!
                   potid = getValue(attributes, "", "id")
               end if 
               print*, "CML read DEBUG: And this has an ID: ", potid
          else if ((localName == "arg").and.(namespaceURI == CMLNS)) then
               parser_state = parser_state + IN_ARG
               print*, "CML read DEBUG: In an argument"
          else if ((localName == "scalar").and.(namespaceURI == CMLNS)) then
               parser_state = parser_state + IN_SCALAR
               print*, "CML read DEBUG: In a scalar"
          else if ((localName == "parameter").and.(namespaceURI == CMLNS)) then 
               parser_state = parser_state + IN_PARAMETER
               print*, "CML read DEBUG: In a parameter"
          end if
!
! Ok then, is this the start of an intresting chunk of 
! XML?
!
     else if ((localName == 'potentialList').and.(namespaceURI == CMLNS)) then
         print*, "CML read DEBUG: Now in Potential list"
         parser_state = parser_state + IN_POTENTIALLIST
     end if

 end subroutine handle_startElement

 subroutine handle_endElement(namespaceURI, localName, QName)
  character(len=*), intent(in) :: namespaceURI
  character(len=*), intent(in) :: localName
  character(len=*), intent(in) :: QName

  if (parser_state.ge.1) then
   if ((localName == 'potentialList').and.(namespaceURI == CMLNS)) then
     parser_state = parser_state - IN_POTENTIALLIST
     print*, "CML read DEBUG: Out of Pot list"
    else if ((localName =='potential').and.(namespaceURI == CMLNS)) then
        print*, "CML read DEBUG: Out of potential"
        parser_state = parser_state - IN_POTENTIAL
    else if ((localName == "arg").and.(namespaceURI == CMLNS)) then
        print*, "CML read DEBUG: Out of arg"
        parser_state = parser_state - IN_ARG
    else if ((localName == "scalar").and.(namespaceURI == CMLNS)) then
        print*, "CML read DEBUG: Out of scalar"
        parser_state = parser_state - IN_SCALAR
    else if ((localName == "parameter").and.(namespaceURI == CMLNS)) then
        print*, "CML read DEBUG: Out of parameter"
        parser_state = parser_state - IN_PARAMETER
   end if
  end if

 end subroutine handle_endElement

end module cml_read_pot
