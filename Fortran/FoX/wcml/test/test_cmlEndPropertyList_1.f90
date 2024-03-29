program test

  use FoX_wcml, only : xmlf_t, cmlBeginFile, cmlFinishFile, cmlStartCml, cmlEndCml, cmlStartPropertyList, cmlEndPropertyList
  implicit none

  character(len=*), parameter :: filename = 'test.xml'
  type(xmlf_t) :: xf

  call cmlBeginFile(xf, filename, unit=-1)
  call cmlStartCml(xf)
  call cmlStartPropertyList(xf)
  call cmlEndPropertyList(xf)
  call cmlFinishFile(xf)

end program test
