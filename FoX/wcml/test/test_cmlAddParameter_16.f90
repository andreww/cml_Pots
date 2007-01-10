program test

  use FoX_wcml, only : xmlf_t, cmlBeginFile, cmlFinishFile, cmlStartCml, cmlEndCml, cmlAddParameter
  implicit none

  character(len=*), parameter :: filename = 'test.xml'
  type(xmlf_t) :: xf

  call cmlBeginFile(xf, filename, unit=-1)
  call cmlStartCml(xf)
  call cmlAddParameter(xf, name="name", value=reshape((/.true., .false., .true., .false./),(/2,2/)))

  call cmlFinishFile(xf)

end program test
