program test

  use FoX_wxml, only : xmlf_t
  use FoX_wxml, only : xml_AddXMLDeclaration
  implicit none

  character(len=*), parameter :: filename = 'test.xml'
  type(xmlf_t) :: xf

  call xml_AddXMLDeclaration(xf)

end program test
