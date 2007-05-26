program test_sax_reader

  use m_sax_operate

  use m_handlers

  type(xml_t) :: xt

  call open_xml_string(xt, &
"<?xml version='1.0'?><!--comment--><?abc xyz?><pqr:aaa xmlns:pqr='lalala' "//&
"att='value' att2='valuejhg'> <!--c--><![CDATA[<>]]> <b/> jhg </pqr:aaa><")

  call sax_parse_go(xt, &
       start_document_handler=start_document_handler, &
       end_document_handler=end_document_handler, &
       begin_element_handler=begin_element_handler, &
       end_element_handler=end_element_handler, &
       start_prefix_handler=start_prefix_handler, &
       end_prefix_handler=end_prefix_handler, &
       characters_handler=characters_handler)

  call close_xml_t(xt)

end program test_sax_reader
