program test_sax_reader

  use m_sax_reader

  type(file_buffer_t) :: fb

  integer :: iostat

  call open_file(fb, file="test_sax_reader_2.in", iostat=iostat)

  write(*,'(2a)') 'char:', read_chars(fb, 3, iostat)
  write(*,'(a,i0)') 'iost:', iostat

  call close_file(fb) 

end program test_sax_reader
