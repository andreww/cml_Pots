program test

  use FoX_wcml, only : xmlf_t, cmlBeginFile, cmlFinishFile, cmlStartCml, cmlEndCml, cmlStartStep, cmlEndStep
  implicit none

  character(len=*), parameter :: filename = 'test.xml'
  type(xmlf_t) :: xf

  call cmlBeginFile(xf, filename, unit=-1)
  call cmlStartCml(xf)
  call cmlStartStep(xf, type="CG")
  call cmlFinishFile(xf)

end program test
