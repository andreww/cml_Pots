module cml_read_pot

 use FoX_sax
 implicit none

 character(len=29), parameter :: cmlns = 'http://www.xml-cml.org/schema'
 ! What is the state of the SAX parser
 ! 0 = not in a potentialList (nothing of intrest)
 ! 1 = in a potentialList
 ! 2 = in a potential 
 ! 3 = in an arg
 ! 4 = in a scalar (I'm assuming we are not having array arguments for now)
 ! This should only ever increse or decrese by one and should never 
 ! transform between two of the same values.
 integer, save :: parser_state = 0

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

  print*, "At start of document"

 end subroutine handle_docStart
 
 subroutine handle_chars(chars)

  character(len=*), intent(in) :: chars
  
  if (parser_state == 4) then 
   print*, "HANDLE_CHARS was called: ", chars
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
     if ((parser_state.ge.1).and.(namespaceURI == CMLNS)) then
          if (localName == 'potentialList') then
                stop "Nested Potential lists are BAD - stopping FIXME"
! FIXME Should handle this stop nicly
          else if (localName =='potential') then
               if (parser_state.ge.2) then 
                   stop "Nested Potentials are (also) bad"
               end if
               print*, "A pot to work with"
               parser_state = 2
               potid = ""
               if (hasKey(attributes,"id")) then
!  Note - attributes only have namespaces if they are given them explicitly!
                   potid = getValue(attributes, "", "id")
               end if 
               print*, "And this has an ID: ", potid
          else if ((localName == "arg").and.(namespaceURI == CMLNS).and.(parser_state == 2)) then
               parser_state = 3
               print*, "In an argument"
          else if ((localName == "scalar").and.(namespaceURI == CMLNS).and.(parser_state == 3)) then
               parser_state = 4
               print*, "In a scalar"
          end if
!
! Ok then, is this the start of an intresting chunk of 
! XML?
!
     else if ((localName == 'potentialList').and.(namespaceURI == CMLNS)) then
         print*, "Now in Potential list"
         parser_state = 1
     end if

 end subroutine handle_startElement

 subroutine handle_endElement(namespaceURI, localName, QName)
  character(len=*), intent(in) :: namespaceURI
  character(len=*), intent(in) :: localName
  character(len=*), intent(in) :: QName

  if (parser_state.ge.1) then
   if ((localName == 'potentialList').and.(namespaceURI == CMLNS)) then
     parser_state = 0
     print*, "Out of Pot list"
    else if ((localName =='potential').and.(namespaceURI == CMLNS)) then
        parser_state = 1
    else if ((localName == "arg").and.(namespaceURI == CMLNS).and.(parser_state == 3)) then
        parser_state = 2
    else if ((localName == "scalar").and.(namespaceURI == CMLNS).and.(parser_state == 4)) then
        parser_state = 3
   end if
  end if

 end subroutine handle_endElement

end module cml_read_pot
