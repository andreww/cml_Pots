program test

  use FoX_common, only: str
  use FoX_wcml, only : xmlf_t, cmlBeginFile, cmlFinishFile, cmlStartCml, cmlEndCml, cmlAddParameter
  use FoX_wxml, only: xml_AddCharacters
  implicit none

  character(len=*), parameter :: filename = 'test.xml'
  type(xmlf_t) :: xf

  call cmlBeginFile(xf, filename, unit=-1)
  call cmlStartCml(xf)
  call cmlAddParameter(xf, name="name", value=(/(1.0,2.0), (3.0,-4.0)/), fmt="s3", units="siUnits:m")

  call cmlFinishFile(xf)

end program test
