! XML parser

module m_sax_parser

  use m_common_array_str, only: str_vs, string_list, &
    destroy_string_list, devnull, vs_str_alloc
  use m_common_attrs, only: init_dict, destroy_dict, add_item_to_dict, &
    has_key, get_value
  use m_common_charset, only: XML1_0, XML1_0_INITIALNAMECHARS, &
    XML1_1_INITIALNAMECHARS, XML_WHITESPACE, operator(.in.)
  use m_common_element, only: element_t, element_list, init_element_list, &
    destroy_element_list, existing_element, add_element, get_element, &
    parse_dtd_element, parse_dtd_attlist, report_declarations, isCdataAtt, &
    get_default_atts
  use m_common_elstack, only: push_elstack, pop_elstack, init_elstack, &
    destroy_elstack, is_empty, len
  use m_common_entities, only: existing_entity, init_entity_list, &
    destroy_entity_list, add_internal_entity, add_external_entity, &
    expand_entity_value_alloc, is_external_entity, expand_entity, &
    expand_char_entity, is_unparsed_entity, pop_entity_list
  use m_common_error, only: FoX_error, add_error, &
    init_error_stack, destroy_error_stack, in_error
  use m_common_io, only: io_eof, io_err
  use m_common_namecheck, only: checkName, checkPubId, &
    checkCharacterEntityReference, likeCharacterEntityReference, &
    checkQName, checkPITarget
  use m_common_namespaces, only: getnamespaceURI, invalidNS, &
    checkNamespaces, checkEndNamespaces, &
    initNamespaceDictionary, destroyNamespaceDictionary
  use m_common_notations, only: init_notation_list, destroy_notation_list, &
    add_notation, notation_exists

  use m_sax_reader, only: file_buffer_t, pop_buffer_stack, push_buffer_stack
  use m_sax_tokenizer, only: sax_tokenize, parse_xml_declaration, normalize_text
  use m_sax_types ! everything, really

  implicit none
  private

  public :: sax_parser_init
  public :: sax_parser_destroy
  public :: sax_parse

contains

  subroutine sax_parser_init(fx)
    type(sax_parser_t), intent(out) :: fx

    allocate(fx%token(0))

    call init_error_stack(fx%error_stack)
    call init_elstack(fx%elstack)
    call initNamespaceDictionary(fx%nsdict)
    call init_notation_list(fx%nlist)
    call init_entity_list(fx%ge_list)
    call init_entity_list(fx%pe_list)
    call init_element_list(fx%element_list)

    allocate(fx%wf_stack(1))
    call init_entity_list(fx%forbidden_ge_list)
    call init_entity_list(fx%forbidden_pe_list)

    call init_entity_list(fx%predefined_e_list)

    call add_internal_entity(fx%predefined_e_list, 'amp', '&', XML1_0)
    call add_internal_entity(fx%predefined_e_list, 'lt', '<', XML1_0)
    call add_internal_entity(fx%predefined_e_list, 'gt', '>', XML1_0)
    call add_internal_entity(fx%predefined_e_list, 'apos', "'", XML1_0)
    call add_internal_entity(fx%predefined_e_list, 'quot', '"', XML1_0)
  end subroutine sax_parser_init

  subroutine sax_parser_destroy(fx)
    type(sax_parser_t), intent(inout) :: fx

    fx%context = CTXT_NULL
    fx%state = ST_NULL

    if (associated(fx%encoding)) deallocate(fx%encoding)
    if (associated(fx%token)) deallocate(fx%token)
    if (associated(fx%root_element)) deallocate(fx%root_element)

    call destroy_error_stack(fx%error_stack)
    call destroy_elstack(fx%elstack)
    call destroy_dict(fx%attributes)
    call destroyNamespaceDictionary(fx%nsdict)
    call destroy_notation_list(fx%nlist)
    call destroy_entity_list(fx%ge_list)
    call destroy_entity_list(fx%pe_list)
    call destroy_element_list(fx%element_list)

    deallocate(fx%wf_stack)
    call destroy_entity_list(fx%forbidden_ge_list)
    call destroy_entity_list(fx%forbidden_pe_list)
    call destroy_entity_list(fx%predefined_e_list)

    if (associated(fx%token)) deallocate(fx%token)
    if (associated(fx%next_token)) deallocate(fx%next_token)
    if (associated(fx%name)) deallocate(fx%name)
    if (associated(fx%attname)) deallocate(fx%attname)
    if (associated(fx%publicId)) deallocate(fx%publicId)
    if (associated(fx%systemId)) deallocate(fx%systemId)
    if (associated(fx%Ndata)) deallocate(fx%Ndata)

  end subroutine sax_parser_destroy

  subroutine sax_parse(fx, fb, &
! org.xml.sax
! SAX ContentHandler
    characters_handler,            &
    endDocument_handler,           &
    endElement_handler,            &
    endPrefixMapping_handler,      &
    ignorableWhitespace_handler,   &
    processingInstruction_handler, &
    ! setDocumentLocator
    skippedEntity_handler,         &
    startDocument_handler,         & 
    startElement_handler,          &
    startPrefixMapping_handler,    &
! SAX DTDHandler
    notationDecl_handler,          &
    unparsedEntityDecl_handler,    &
! SAX ErrorHandler
    error_handler,                 &
    fatalError_handler,            &
    warning_handler,               &
! org.xml.sax.ext
! SAX DeclHandler
    attributeDecl_handler,         &
    elementDecl_handler,           &
    externalEntityDecl_handler,    &
    internalEntityDecl_handler,    &
! SAX LexicalHandler
    comment_handler,               &
    endCdata_handler,              &
    endDTD_handler,                &
    endEntity_handler,             &
    startCdata_handler,            &
    startDTD_handler,              &
    startEntity_handler,           &
    validate)

    type(sax_parser_t), intent(inout) :: fx
    type(file_buffer_t), intent(inout) :: fb
    optional :: characters_handler
    optional :: endDocument_handler
    optional :: endElement_handler
    optional :: endPrefixMapping_handler
    optional :: ignorableWhitespace_handler
    optional :: processingInstruction_handler
    optional :: skippedEntity_handler
    optional :: startElement_handler
    optional :: startDocument_handler
    optional :: startPrefixMapping_handler
    optional :: notationDecl_handler
    optional :: unparsedEntityDecl_handler
    optional :: error_handler
    optional :: fatalError_handler
    optional :: warning_handler
    optional :: attributeDecl_handler
    optional :: elementDecl_handler
    optional :: externalEntityDecl_handler
    optional :: internalEntityDecl_handler
    optional :: comment_handler
    optional :: endCdata_handler
    optional :: endEntity_handler
    optional :: endDTD_handler
    optional :: startCdata_handler
    optional :: startDTD_handler
    optional :: startEntity_handler

    logical, intent(in), optional :: validate

    interface

      subroutine characters_handler(chunk)
        character(len=*), intent(in) :: chunk
      end subroutine characters_handler

      subroutine endDocument_handler()     
      end subroutine endDocument_handler

      subroutine endElement_handler(namespaceURI, localName, name)
        character(len=*), intent(in)     :: namespaceURI
        character(len=*), intent(in)     :: localName
        character(len=*), intent(in)     :: name
      end subroutine endElement_handler
      
      subroutine endPrefixMapping_handler(prefix)
        character(len=*), intent(in) :: prefix
      end subroutine endPrefixMapping_handler

      subroutine ignorableWhitespace_handler(chars)
        character(len=*), intent(in) :: chars
      end subroutine ignorableWhitespace_handler

      subroutine processingInstruction_handler(name, content)
        character(len=*), intent(in)     :: name
        character(len=*), intent(in)     :: content
      end subroutine processingInstruction_handler

      subroutine skippedEntity_handler(name)
        character(len=*), intent(in) :: name
      end subroutine skippedEntity_handler

      subroutine startDocument_handler()   
      end subroutine startDocument_handler

      subroutine startElement_handler(namespaceURI, localName, name, attributes)
        use FoX_common
        character(len=*), intent(in)     :: namespaceUri
        character(len=*), intent(in)     :: localName
        character(len=*), intent(in)     :: name
        type(dictionary_t), intent(in)   :: attributes
      end subroutine startElement_handler

      subroutine startPrefixMapping_handler(namespaceURI, prefix)
        character(len=*), intent(in) :: namespaceURI
        character(len=*), intent(in) :: prefix
      end subroutine startPrefixMapping_handler

      subroutine notationDecl_handler(name, publicId, systemId)
        character(len=*), intent(in) :: name
        character(len=*), optional, intent(in) :: publicId
        character(len=*), optional, intent(in) :: systemId
      end subroutine notationDecl_handler

      subroutine unparsedEntityDecl_handler(name, publicId, systemId, notation)
        character(len=*), intent(in) :: name
        character(len=*), optional, intent(in) :: publicId
        character(len=*), intent(in) :: systemId
        character(len=*), intent(in) :: notation
      end subroutine unparsedEntityDecl_handler

      subroutine error_handler(msg)
        character(len=*), intent(in)     :: msg
      end subroutine error_handler

      subroutine fatalError_handler(msg)
        character(len=*), intent(in)     :: msg
      end subroutine fatalError_handler
      
      subroutine warning_handler(msg)
        character(len=*), intent(in)     :: msg
      end subroutine warning_handler

      subroutine attributeDecl_handler(eName, aName, type, mode, value)
        character(len=*), intent(in) :: eName
        character(len=*), intent(in) :: aName
        character(len=*), intent(in) :: type
        character(len=*), intent(in), optional :: mode
        character(len=*), intent(in), optional :: value
      end subroutine attributeDecl_handler

      subroutine elementDecl_handler(name, model)
        character(len=*), intent(in) :: name
        character(len=*), intent(in) :: model
      end subroutine elementDecl_handler

      subroutine externalEntityDecl_handler(name, publicId, systemId)
        character(len=*), intent(in) :: name
        character(len=*), optional, intent(in) :: publicId
        character(len=*), intent(in) :: systemId
      end subroutine externalEntityDecl_handler

      subroutine internalEntityDecl_handler(name, value)
        character(len=*), intent(in) :: name
        character(len=*), intent(in) :: value
      end subroutine internalEntityDecl_handler

      subroutine comment_handler(comment)
        character(len=*), intent(in) :: comment
      end subroutine comment_handler

      subroutine endCdata_handler()
      end subroutine endCdata_handler

      subroutine endDTD_handler()
      end subroutine endDTD_handler

      subroutine endEntity_handler(name)
        character(len=*), intent(in) :: name
      end subroutine endEntity_handler

      subroutine startCdata_handler()
      end subroutine startCdata_handler

      subroutine startDTD_handler(name, publicId, systemId)
        character(len=*), intent(in) :: name
        character(len=*), optional, intent(in) :: publicId
        character(len=*), optional, intent(in) :: systemId
      end subroutine startDTD_handler

      subroutine startEntity_handler(name)
        character(len=*), intent(in) :: name
      end subroutine startEntity_handler

    end interface

    logical :: validCheck, processDTD, pe
    integer :: i, iostat
    character, pointer :: tempString(:)
    type(element_t), pointer :: elem
    integer, pointer :: temp_wf_stack(:)

    nullify(tempString)
    nullify(elem)

    if (present(validate)) then
      validCheck = validate
    else
      validCheck = .false.
    endif
    processDTD = .true.
    iostat = 0

    if (fx%parse_stack==0) then
      call parse_xml_declaration(fx, fb, iostat)
      if (iostat/=0) goto 100
      fx%context = CTXT_BEFORE_DTD
      fx%state = ST_MISC
      fx%whitespace = WS_DISCARD
      if (present(startDocument_handler)) &
        call startDocument_handler()
    endif

    do

      call sax_tokenize(fx, fb, iostat)
      if (in_error(fx%error_stack)) iostat = io_err
      if (iostat==io_eof.and.fx%parse_stack>0) then
        if (fx%context==CTXT_IN_DTD) then
          ! that's just the end of a parameter entity expansion.
          ! pop the parse stack, and carry on ..
          if (present(endEntity_handler)) then
            call endEntity_handler('%'//pop_entity_list(fx%forbidden_pe_list))
          else
            call devnull(pop_entity_list(fx%forbidden_pe_list))
          endif
        elseif (fx%context==CTXT_IN_CONTENT) then
          if (fx%state==ST_TAG_IN_CONTENT) fx%state = ST_CHAR_IN_CONTENT
          ! because CHAR_IN_CONTENT *always* leads to TAG_IN_CONTENT
          ! *except* when it is the end of an entity expansion
          ! it's the end of a general entity expansion
          if (present(endEntity_handler)) then
            call endEntity_handler(pop_entity_list(fx%forbidden_ge_list))
          else
            call devnull(pop_entity_list(fx%forbidden_ge_list))
          endif
          if (fx%state/=ST_CHAR_IN_CONTENT.or.fx%wf_stack(1)/=0) then
            call add_error(fx%error_stack, 'Ill-formed entity')
            goto 100
          endif
          temp_wf_stack => fx%wf_stack
          allocate(fx%wf_stack(size(temp_wf_stack)-1))
          fx%wf_stack = temp_wf_stack(2:size(temp_wf_stack))
          deallocate(temp_wf_stack)
        endif
        iostat = 0
        call pop_buffer_stack(fb)
        fx%parse_stack = fx%parse_stack - 1
        cycle
      elseif (iostat/=0) then
        ! Any other error, we want to quit sax_tokenizer
        call add_error(fx%error_stack, 'Error getting token')
        goto 100
      endif
      if (.not.associated(fx%token)) then
        call add_error(fx%error_stack, 'Internal error! No token found!')
        goto 100
      endif

      select case (fx%state)

      case (ST_MISC)
        !write(*,*) 'ST_MISC'
        if (str_vs(fx%token) == '<?') then
          fx%state = ST_START_PI
          fx%whitespace = WS_FORBIDDEN
        elseif (str_vs(fx%token) ==  '<!') then
          fx%state = ST_BANG_TAG
          fx%whitespace = WS_FORBIDDEN
        elseif (str_vs(fx%token) == '<') then
          fx%state = ST_START_TAG
          fx%whitespace = WS_FORBIDDEN
        else
          call add_error(fx%error_stack, "Unexpected token found outside content")
          goto 100
        endif

      case (ST_BANG_TAG)
        !write(*,*)'ST_BANG_TAG'
        if (str_vs(fx%token)=='--') then
          fx%state = ST_START_COMMENT
        elseif (fx%context==CTXT_BEFORE_DTD) then
          if (str_vs(fx%token)=='DOCTYPE') then
            fx%whitespace = WS_MANDATORY
            fx%context = CTXT_IN_DTD
            fx%state = ST_IN_DTD
          endif
        elseif (fx%context==CTXT_IN_CONTENT) then
          if (str_vs(fx%token)=='[') then
            fx%state = ST_START_CDATA_1
          endif
        elseif (fx%context==CTXT_IN_DTD) then  
          if (str_vs(fx%token)=='ATTLIST') then
            fx%state = ST_DTD_ATTLIST
          elseif (str_vs(fx%token)=='ELEMENT') then
            fx%state = ST_DTD_ELEMENT
          elseif (str_vs(fx%token)=='ENTITY') then
            fx%state = ST_DTD_ENTITY
          elseif (str_vs(fx%token)=='NOTATION') then
            fx%state = ST_DTD_NOTATION
          endif
          fx%whitespace = WS_MANDATORY
        else
          call add_error(fx%error_stack, "Unexpected token after !")
          goto 100
        endif

      case (ST_START_PI)
        !write(*,*)'ST_START_PI'
        if (checkName(str_vs(fx%token), fx%xml_version)) then
          if (str_vs(fx%token)=='xml') then
            call add_error(fx%error_stack, "XML declaration must be at start of document")
            goto 100
          elseif (checkPITarget(str_vs(fx%token), fx%xml_version)) then
            fx%whitespace = WS_MANDATORY
            fx%state = ST_PI_CONTENTS
            fx%name => fx%token
            nullify(fx%token)
          else
            call add_error(fx%error_stack, "Invalid PI target name")
            goto 100
          endif
        else
          call add_error(fx%error_stack, "Unexpected token found for PI target; expecting Name")
          goto 100
        endif

      case (ST_PI_CONTENTS)
        !write(*,*)'ST_PI_CONTENTS'
        if (str_vs(fx%token)=='?>') then
          ! No data for this PI
          if (present(processingInstruction_handler)) &
            call processingInstruction_handler(str_vs(fx%name), '')
          deallocate(fx%name)
          if (fx%context==CTXT_IN_CONTENT) then
            fx%state = ST_CHAR_IN_CONTENT
          else
            fx%whitespace = WS_DISCARD
            fx%state = ST_MISC
          endif
        else
          if (present(processingInstruction_handler)) &
            call processingInstruction_handler(str_vs(fx%name), str_vs(fx%token))
          deallocate(fx%name)
          fx%state = ST_PI_END
        endif

      case (ST_PI_END)
        !write(*,*)'ST_PI_END'
        if (str_vs(fx%token)=='?>') then
          if (fx%context==CTXT_IN_CONTENT) then
            fx%state = ST_CHAR_IN_CONTENT
            fx%whitespace = WS_PRESERVE
          elseif (fx%context==CTXT_IN_DTD) then
            fx%state = ST_INT_SUBSET
            fx%whitespace = WS_DISCARD
          else
            fx%state = ST_MISC
            fx%whitespace = WS_DISCARD
          endif
        else
          call add_error(fx%error_stack, "Internal error: unexpected token at end of PI, expecting ?>")
          goto 100
        endif

      case (ST_START_COMMENT)
        !write(*,*)'ST_START_COMMENT'
        fx%name => fx%token
        nullify(fx%token)
        fx%state = ST_COMMENT_END_1

      case (ST_COMMENT_END_1)
        !write(*,*)'ST_COMMENT_END_1'
        if (str_vs(fx%token)=='--') then
          fx%state = ST_COMMENT_END_2
        else
          call add_error(fx%error_stack, "Internal error: expecting --")
          goto 100
        endif

      case (ST_COMMENT_END_2)
        !write(*,*)'ST_COMMENT_END_2'
        if (str_vs(fx%token)=='>') then
          if (present(comment_handler)) &
            call comment_handler(str_vs(fx%name))
          deallocate(fx%name)
          if (fx%context==CTXT_IN_CONTENT) then
            fx%state = ST_CHAR_IN_CONTENT
            fx%whitespace = WS_PRESERVE
          elseif (fx%context==CTXT_IN_DTD) then
            fx%state = ST_INT_SUBSET
            fx%whitespace = WS_DISCARD
          else
            fx%state = ST_MISC
            fx%whitespace = WS_DISCARD
          endif
        else
          call add_error(fx%error_stack, "Expecting > after -- in comment")
          goto 100
        endif

      case (ST_START_TAG)
        !write(*,*)'ST_START_TAG', fx%context
        if (fx%context==CTXT_BEFORE_DTD &
          .or. fx%context==CTXT_BEFORE_CONTENT &
          .or. fx%context==CTXT_IN_CONTENT) then
          fx%name => fx%token
          nullify(fx%token)
          ! FIXME check name is name? ought to be.
          fx%whitespace = WS_MANDATORY
          fx%state = ST_IN_TAG
          call init_dict(fx%attributes)
        elseif (fx%context == CTXT_AFTER_CONTENT) then
          call add_error(fx%error_stack, "Cannot open second root element")
          goto 100
        elseif (fx%context == CTXT_IN_DTD) then
          call add_error(fx%error_stack, "Cannot open root element before DTD is finished")
          goto 100
        endif

      case (ST_START_CDATA_1)
        !write(*,*)'ST_START_CDATA_1'
        if (str_vs(fx%token) == 'CDATA') then
          fx%state = ST_START_CDATA_2
          fx%whitespace = WS_FORBIDDEN
        else
          call add_error(fx%error_stack, "Unexpected token found - expecting CDATA afte <![")
          goto 100
        endif

      case (ST_START_CDATA_2)
        !write(*,*)'ST_START_CDATA_2'
        if (str_vs(fx%token) == '[') then
          fx%state = ST_CDATA_CONTENTS
        else
          call add_error(fx%error_stack, "Unexpected token found - expecting [ after CDATA")
          goto 100
        endif

      case (ST_CDATA_CONTENTS)
        !write(*,*)'ST_CDATA_CONTENTS'
        fx%name => fx%token
        nullify(fx%token)
        fx%state = ST_CDATA_END

      case (ST_CDATA_END)
        !write(*,*)'ST_CDATA_END'
        if (str_vs(fx%token) == ']]>') then
          if (present(startCdata_handler)) &
            call startCdata_handler
          if (size(fx%name)>0) then
            if (present(characters_handler)) &
              call characters_handler(str_vs(fx%name))
          endif
          if (present(endCdata_handler)) &
            call endCdata_handler
          deallocate(fx%name)
          fx%state = ST_CHAR_IN_CONTENT
        else
          call add_error(fx%error_stack, "Internal error, unexpected token in CDATA")
          goto 100
        endif

      case (ST_IN_TAG)
        !write(*,*)'ST_IN_TAG'
        if (str_vs(fx%token)=='>') then
          if (fx%context /= CTXT_IN_CONTENT) then
            if (associated(fx%root_element)) then
              if (validCheck) then
                if (str_vs(fx%name)/=str_vs(fx%root_element)) then
                  call add_error(fx%error_stack, "Root element name does not match document name")
                  goto 100
                endif
              endif
              deallocate(fx%root_element)
            endif
            fx%context = CTXT_IN_CONTENT
          endif
          call open_tag
          if (in_error(fx%error_stack)) goto 100
          deallocate(fx%name)
          fx%state = ST_CHAR_IN_CONTENT

        elseif (str_vs(fx%token)=='/>') then
          if (fx%context==CTXT_IN_CONTENT) then
            fx%state = ST_CHAR_IN_CONTENT
          else
            ! only a single element in this doc
            if (associated(fx%root_element)) then
              if (validCheck) then
                if (str_vs(fx%name)/=str_vs(fx%root_element)) then
                  call add_error(fx%error_stack, "Root element name does not match document name")
                  goto 100
                endif
              endif
              deallocate(fx%root_element)
            endif
          endif
          call open_tag
          if (in_error(fx%error_stack)) goto 100
          call close_tag
          if (in_error(fx%error_stack)) goto 100
          deallocate(fx%name)
          if (fx%context==CTXT_IN_CONTENT) then
            fx%whitespace = WS_PRESERVE
          else
            fx%well_formed = .true.
            fx%context = CTXT_AFTER_CONTENT
            fx%state = ST_MISC
            fx%whitespace = WS_DISCARD
          endif
        else
          ! FIXME It should be an XML name for the attribute
          ! pick up that it is a name:
          fx%attname => fx%token
          nullify(fx%token)
          fx%state = ST_ATT_NAME
          fx%whitespace = WS_DISCARD
        endif

      case (ST_ATT_NAME)
        !write(*,*)'ST_ATT_NAME'
        if (str_vs(fx%token)=='=') then
          fx%state = ST_ATT_EQUALS
        else
          call add_error(fx%error_stack, "Unexpected token in tag - expected =")
          goto 100
        endif

      case (ST_ATT_EQUALS)
        !write(*,*)'ST_ATT_EQUALS'
        ! token is pre-processed attribute value.
        ! fx%name still contains attribute name
        if (.not.checkQName(str_vs(fx%attname), fx%xml_version)) then
          call add_error(fx%error_stack, "Invalid QName for attribute name")
          goto 100
        endif
        !Have we already had this dictionary item?
        if (has_key(fx%attributes, str_vs(fx%attname))) then
          call add_error(fx%error_stack, "Duplicate attribute name")
          goto 100
        endif
        !If this attribute is CDATA, we must process further;
        if (isCdataAtt(fx%element_list, &
          str_vs(fx%name), str_vs(fx%attname))) then
          call add_item_to_dict(fx%attributes, str_vs(fx%attname), &
            str_vs(fx%token))
        else
          call add_item_to_dict(fx%attributes, str_vs(fx%attname), &
            trim(NotCDataNormalize(str_vs(fx%token))))
        endif
        deallocate(fx%attname)
        fx%state = ST_IN_TAG

      case (ST_CHAR_IN_CONTENT)
        !write(*,*)'ST_CHAR_IN_CONTENT'
        if (index(str_vs(fx%token),']]>')/=0) then
          call add_error(fx%error_stack, "Cannot have ]]> in character context")
          goto 100
        endif
        if (size(fx%token)>0) then
          if (present(characters_handler)) call characters_handler(str_vs(fx%token))
        endif
        !FIXME If current element is not ANY or EMPTY or MIXED then
        ! any whitespace here is not significant, and we should call
        ! back to ignorableWhitespace.
        fx%whitespace = WS_FORBIDDEN
        fx%state = ST_TAG_IN_CONTENT

      case (ST_TAG_IN_CONTENT)
        !write(*,*)'ST_TAG_IN_CONTENT'
        if (str_vs(fx%token)=='<') then
          fx%state = ST_START_TAG
        elseif (str_vs(fx%token)=='<!') then
          fx%state = ST_BANG_TAG
        elseif (str_vs(fx%token)=='<?') then
          fx%state = ST_START_PI
        elseif (str_vs(fx%token)=='</') then
          fx%state = ST_CLOSING_TAG
        elseif (fx%token(1)=='&') then
          tempString => vs_str_alloc(str_vs(fx%token(2:size(fx%token)-1)))
          ! tell tokenizer to expand it
          if (existing_entity(fx%forbidden_ge_list, str_vs(tempString))) then
            call add_error(fx%error_stack, 'Recursive entity reference')
            goto 100
          endif
          if (existing_entity(fx%predefined_e_list, str_vs(tempString))) then
            ! Expand immediately
            if (present(startEntity_handler)) &
              call startEntity_handler(str_vs(tempString))
            if (present(characters_handler)) &
              call characters_handler(expand_entity(fx%predefined_e_list, str_vs(tempString)))
            if (present(endEntity_handler)) &
              call endEntity_handler(str_vs(tempString))
          elseif (likeCharacterEntityReference(str_vs(tempString), fx%xml_version)) then
            if (.not.checkCharacterEntityReference(str_vs(tempString), fx%xml_version)) then
              call add_error(fx%error_stack, "Illegal character reference")
            endif
            if (present(characters_handler)) &
              call characters_handler(expand_char_entity(str_vs(tempString)))
          elseif (existing_entity(fx%ge_list, str_vs(tempString))) then
            if (is_unparsed_entity(fx%ge_list, str_vs(tempString))) then
              call add_error(fx%error_stack, &
                'Cannot reference unparsed entity in content')
              goto 100
            elseif (is_external_entity(fx%ge_list, str_vs(tempString))) then
              if (present(skippedEntity_handler)) &
                call skippedEntity_handler(str_vs(fx%token))
            else
              if (present(startEntity_handler)) &
                call startEntity_handler(str_vs(tempString))
              call add_internal_entity(fx%forbidden_ge_list, str_vs(tempString), "", fx%xml_version)
              call push_buffer_stack(fb, expand_entity(fx%ge_list, str_vs(tempString)))
              fx%parse_stack = fx%parse_stack + 1
              temp_wf_stack => fx%wf_stack
              allocate(fx%wf_stack(size(temp_wf_stack)+1))
              fx%wf_stack(2:size(fx%wf_stack)) = temp_wf_stack
              fx%wf_stack(1) = 0
              deallocate(temp_wf_stack)
            endif
          else
            ! Unknown entity check standalone etc
            if (fx%skippedExternal.and..not.fx%standalone) then
              if (present(skippedEntity_handler)) &
                call skippedEntity_handler(str_vs(fx%token))
            else
              call add_error(fx%error_stack, &
                'Encountered reference to undeclared entity')
            endif
          endif
          deallocate(tempString)
          fx%state = ST_CHAR_IN_CONTENT
        else
          call add_error(fx%error_stack, "Unexpected token found in character context")
          goto 100
        endif

      case (ST_CLOSING_TAG)
        !write(*,*)'ST_CLOSING_TAG'
        if (checkName(str_vs(fx%token), fx%xml_version)) then!fx%token, fx%xml_version)) then
          fx%name => fx%token
          nullify(fx%token)
          fx%whitespace = WS_DISCARD
          fx%state = ST_IN_CLOSING_TAG
        else
          call add_error(fx%error_stack, "Unexpected token found in closing tag: expecting a Name")
          goto 100
        endif

      case (ST_IN_CLOSING_TAG)
        !write(*,*)'ST_IN_CLOSING_TAG'
        if (str_vs(fx%token) == '>') then
          call close_tag
          if (in_error(fx%error_stack)) goto 100
          deallocate(fx%name)
          if (is_empty(fx%elstack)) then
            !we're done
            fx%well_formed = .true.
            fx%state = ST_MISC
            fx%context = CTXT_AFTER_CONTENT
            fx%whitespace = WS_DISCARD
          else
            fx%whitespace = WS_PRESERVE
            fx%state = ST_CHAR_IN_CONTENT
          endif
        else
          call add_error(fx%error_stack, "Unexpected token in closing tag - expecting Name")
          goto 100
        endif

      case (ST_IN_DTD)
        !write(*,*)'ST_IN_DTD'
        ! check token is name
        fx%root_element => fx%token
        nullify(fx%token)
        fx%whitespace = WS_MANDATORY
        fx%state = ST_DTD_NAME

      case (ST_DTD_NAME)
        !write(*,*) 'ST_DTD_NAME'
        if (str_vs(fx%token)=='SYSTEM') then
          fx%state = ST_DTD_SYSTEM
        elseif (str_vs(fx%token)=='PUBLIC') then
          fx%state = ST_DTD_PUBLIC
        elseif (str_vs(fx%token)=='[') then
          if (present(startDTD_handler)) &
            call startDTD_handler(str_vs(fx%root_element))
          fx%whitespace = WS_DISCARD
          fx%state = ST_INT_SUBSET
        elseif (str_vs(fx%token)=='>') then
          if (present(startDTD_handler)) &
            call startDTD_handler(str_vs(fx%root_element))
          fx%context = CTXT_BEFORE_CONTENT
          fx%state = ST_MISC
        else
          call add_error(fx%error_stack, "Internal error: unexpected token")
          goto 100
        endif

      case (ST_DTD_PUBLIC)
        !write(*,*) 'ST_DTD_PUBLIC'
        if (fx%token(1)/='"'.and.fx%token(1)/="'" &
          .and.fx%token(1)/=fx%token(size(fx%token))) then
          call add_error(fx%error_stack, "Invalid Public Id literal")
          goto 100
        endif
        if (checkPubId(str_vs(fx%token(2:size(fx%token)-1)))) then
          fx%publicId => vs_str_alloc(str_vs(fx%token(2:size(fx%token)-1)))
          deallocate(fx%token)
          fx%state = ST_DTD_SYSTEM
        else
          call add_error(fx%error_stack, "Invalid document public id")
          goto 100
        endif

      case (ST_DTD_SYSTEM)
        !write(*,*) 'ST_DTD_SYSTEM'
        if (fx%token(1)/='"'.and.fx%token(1)/="'" &
          .and.fx%token(1)/=fx%token(size(fx%token))) then
          call add_error(fx%error_stack, "Invalid System Id literal")
          goto 100
        endif
        fx%systemId => vs_str_alloc(str_vs(fx%token(2:size(fx%token)-1)))
        deallocate(fx%token)
        fx%whitespace = WS_DISCARD
        fx%state = ST_DTD_DECL

      case (ST_DTD_DECL)
        !write(*,*) 'ST_DTD_DECL'
        if (str_vs(fx%token)=='[') then
          if (associated(fx%publicId).or.associated(fx%systemId)) &
            fx%skippedExternal = .true.
          if (present(startDTD_handler)) then
            if (associated(fx%publicId)) then
              call startDTD_handler(str_vs(fx%root_element), publicId=str_vs(fx%publicId), systemId=str_vs(fx%systemId))
            elseif (associated(fx%systemId)) then
              call startDTD_handler(str_vs(fx%root_element), systemId=str_vs(fx%systemId))
            else
              call startDTD_handler(str_vs(fx%root_element))
            endif
          endif
          if (associated(fx%systemId)) deallocate(fx%systemId)
          if (associated(fx%publicId)) deallocate(fx%publicId)
          fx%whitespace = WS_DISCARD
          fx%state = ST_INT_SUBSET
        elseif (str_vs(fx%token)=='>') then
          if (associated(fx%publicId).or.associated(fx%systemId)) &
            fx%skippedExternal = .true.
          if (present(startDTD_handler)) then
            if (associated(fx%publicId)) then
              call startDTD_handler(str_vs(fx%root_element), publicId=str_vs(fx%publicId), systemId=str_vs(fx%systemId))
              deallocate(fx%publicId)
            elseif (associated(fx%systemId)) then
              call startDTD_handler(str_vs(fx%root_element), systemId=str_vs(fx%systemId))
            else
              call startDTD_handler(str_vs(fx%root_element))
            endif
          endif
          if (associated(fx%systemId)) deallocate(fx%systemId)
          if (associated(fx%publicId)) deallocate(fx%publicId)
          if (present(endDTD_handler)) &
            call endDTD_handler
          fx%context = CTXT_BEFORE_CONTENT
          fx%state = ST_MISC
        else
          call add_error(fx%error_stack, "Internal error: unexpected token")
          goto 100
        endif

      case (ST_INT_SUBSET)
        write(*,*) 'ST_INT_SUBSET'
        if (str_vs(fx%token)==']') then
          fx%state = ST_CLOSE_DTD
        elseif (fx%token(1)=='%') then
          tempString => vs_str_alloc(str_vs(fx%token(2:size(fx%token)-1)))
          if (existing_entity(fx%forbidden_pe_list, str_vs(tempString))) then
            call add_error(fx%error_stack, &
              'Recursive entity reference')
            goto 100
          endif
          if (existing_entity(fx%pe_list, str_vs(tempString))) then
            if (is_external_entity(fx%pe_list, str_vs(tempString))) then
              ! We are not validating, do not include external entities
              if (present(skippedEntity_handler)) &
                call skippedEntity_handler('%'//str_vs(tempString))
              !  then are we standalone?
              !   then look at XML section 5.1
              fx%skippedExternal = .true.
              processDTD = fx%standalone !FIXME use this everywhere
            else
              ! Expand the entity, 
              if (present(startEntity_handler)) &
                call startEntity_handler('%'//str_vs(tempString))
              call add_internal_entity(fx%forbidden_pe_list, &
                str_vs(tempString), "", fx%xml_version)
              call push_buffer_stack(fb, &
                " "//expand_entity(fx%pe_list, str_vs(tempString))//" ")
              fx%parse_stack = fx%parse_stack + 1
            endif
            ! and do nothing else, carry on ...
          else
            ! Have we previously skipped an external entity?
            if (fx%skippedExternal.and..not.fx%standalone) then
              if (processDTD) then
                if (present(skippedEntity_handler)) &
                  call skippedEntity_handler('%'//str_vs(tempString))
              endif
            else
              ! If not, 
              call add_error(fx%error_stack, &
                "Reference to undeclared parameter entity.")
              goto 100
            endif
          endif
          deallocate(tempString)
        elseif (str_vs(fx%token)=='<?') then
          fx%state = ST_START_PI
          fx%whitespace = WS_FORBIDDEN
        elseif (str_vs(fx%token)=='<!') then
          fx%state = ST_BANG_TAG
          fx%whitespace = WS_FORBIDDEN
        else
          call add_error(fx%error_stack, "Unexpected token in internal subset")
          goto 100
        endif

      case (ST_DTD_ATTLIST)
        !write(*,*) 'ST_DTD_ATTLIST'
        ! check is name
        fx%name => fx%token
        if (existing_element(fx%element_list, str_vs(fx%name))) then
          elem => get_element(fx%element_list, str_vs(fx%name))
        else
          elem => add_element(fx%element_list, str_vs(fx%name))
        endif
        nullify(fx%token)
        fx%state = ST_DTD_ATTLIST_CONTENTS

      case (ST_DTD_ATTLIST_CONTENTS)
        if (str_vs(fx%token)==">") then
          deallocate(fx%name)
          if (processDTD) then
            if (present(attributeDecl_handler)) &
              call report_declarations(elem, attributeDecl_handler)
          endif
          fx%state = ST_INT_SUBSET
          fx%whitespace = WS_DISCARD
        else
          !token is everything up to >
          if (processDTD) then
            call parse_dtd_attlist(str_vs(fx%token), fx%xml_version, fx%error_stack, elem)
          else
            call parse_dtd_attlist(str_vs(fx%token), fx%xml_version, fx%error_stack)
          endif
          if (in_error(fx%error_stack)) goto 100
          ! Normalize attribute values in attlist
          do i = 1, size(elem%attlist%list)
            if (associated(elem%attlist%list(i)%default)) then
              tempString => elem%attlist%list(i)%default
              elem%attlist%list(i)%default => normalize_text(fx, tempString)
              deallocate(tempString)
              if (in_error(fx%error_stack)) goto 100
            endif
          enddo
          fx%state = ST_DTD_ATTLIST_END
        endif

      case (ST_DTD_ATTLIST_END)
        if (str_vs(fx%token)=='>') then
          deallocate(fx%name)
          if (processDTD) then
            if (present(attributeDecl_handler)) &
              call report_declarations(elem, attributeDecl_handler)
          endif
          fx%state = ST_INT_SUBSET
          fx%whitespace = WS_DISCARD

        else
          call add_error(fx%error_stack, "Unexpected token in ATTLIST")
          goto 100
        endif

      case (ST_DTD_ELEMENT)
        !write(*,*) 'ST_DTD_ELEMENT'
        ! check is name
        fx%name => fx%token
        nullify(fx%token)
        fx%whitespace = WS_MANDATORY
        fx%state = ST_DTD_ELEMENT_CONTENTS

      case (ST_DTD_ELEMENT_CONTENTS)
        !token is everything up to >
        !write(*,*)'ST_DTD_ELEMENT_CONTENTS'
        if (existing_element(fx%element_list, str_vs(fx%name))) then
          if (validCheck) then
            call add_error(fx%error_stack, "Duplicate Element declaration")
            goto 100
          else
            ! Ignore contents ...
            nullify(elem)
            call parse_dtd_element(str_vs(fx%token), fx%xml_version, fx%error_stack)
          endif
        else
          if (processDTD) then
            elem => add_element(fx%element_list, str_vs(fx%name))
            call parse_dtd_element(str_vs(fx%token), fx%xml_version, fx%error_stack, elem)
          else
            nullify(elem)
            call parse_dtd_element(str_vs(fx%token), fx%xml_version, fx%error_stack)
          endif
        endif
        if (in_error(fx%error_stack)) goto 100
        fx%state = ST_DTD_ELEMENT_END

      case (ST_DTD_ELEMENT_END)
        !write(*,*)'ST_DTD_ELEMENT_END'
        if (str_vs(fx%token)=='>') then
          if (processDTD.and.associated(elem)) then
            if (present(elementDecl_handler)) &
              call elementDecl_handler(str_vs(fx%name), str_vs(elem%model))
          endif
          deallocate(fx%name)
          fx%state = ST_INT_SUBSET
          fx%whitespace = WS_DISCARD
        else
          call add_error(fx%error_stack, "Unexpected token in ELEMENT")
          goto 100
          !FIXME this can't happen
        endif

      case (ST_DTD_ENTITY)
        !write(*,*) 'ST_DTD_ENTITY'
        if (str_vs(fx%token) == '%') then
          pe = .true.
          ! this will be a PE
          fx%state = ST_DTD_ENTITY_PE
        else
          pe = .false.
          if (.not.checkName(str_vs(fx%token), fx%xml_version)) then
            call add_error(fx%error_stack, &
              "Illegal name for general entity")
            goto 100
          endif
          fx%name => fx%token
          nullify(fx%token)
          fx%state = ST_DTD_ENTITY_ID
        endif

      case (ST_DTD_ENTITY_PE)
        !write(*,*) 'ST_DTD_ENTITY_PE'
        if (.not.checkName(str_vs(fx%token), fx%xml_version)) then
          call add_error(fx%error_stack, &
            "Illegal name for parameter entity")
          goto 100
        endif
        fx%name => fx%token
        nullify(fx%token)
        fx%state = ST_DTD_ENTITY_ID

      case (ST_DTD_ENTITY_ID)
        !write(*,*) 'ST_DTD_ENTITY_ID'
        if (str_vs(fx%token) == 'PUBLIC') then
          fx%state = ST_DTD_ENTITY_PUBLIC
        elseif (str_vs(fx%token) == 'SYSTEM') then
          fx%state = ST_DTD_ENTITY_SYSTEM
        elseif (fx%token(1)=="'".or.fx%token(1)=='"') then
          fx%attname => expand_entity_value_alloc(fx%token, fx%xml_version, fx%error_stack)
          if (in_error(fx%error_stack)) goto 100
          fx%state = ST_DTD_ENTITY_END
          fx%whitespace = WS_DISCARD
        else
          call add_error(fx%error_stack, "Unexpected token in ENTITY")
          goto 100
        endif

      case (ST_DTD_ENTITY_PUBLIC)
        !write(*,*) 'ST_DTD_ENTITY_PUBLIC'
        if (fx%token(1)/='"'.and.fx%token(1)/="'" &
          .and.fx%token(1)/=fx%token(size(fx%token))) then
          call add_error(fx%error_stack, "Invalid Public Id literal")
          goto 100
        endif
        if (checkPubId(str_vs(fx%token(2:size(fx%token)-1)))) then
          fx%publicId => vs_str_alloc(str_vs(fx%token(2:size(fx%token)-1)))
          deallocate(fx%token)
          fx%state = ST_DTD_ENTITY_SYSTEM
        else
          call add_error(fx%error_stack, "Invalid PUBLIC id in ENTITY")
          goto 100
        endif

      case (ST_DTD_ENTITY_SYSTEM)
        !write(*,*) 'ST_DTD_ENTITY_SYSTEM'
        if (fx%token(1)/='"'.and.fx%token(1)/="'" &
          .and.fx%token(1)/=fx%token(size(fx%token))) then
          call add_error(fx%error_stack, "Invalid System Id literal")
          goto 100
        endif
        fx%systemId => vs_str_alloc(str_vs(fx%token(2:size(fx%token)-1)))
        deallocate(fx%token)
        fx%state = ST_DTD_ENTITY_NDATA

      case (ST_DTD_ENTITY_NDATA)
        !write(*,*) 'ST_DTD_ENTITY_NDATA'
        if (str_vs(fx%token)=='>') then
          if (processDTD) then
            call add_entity
          endif
          deallocate(fx%name)
          if (associated(fx%attname)) deallocate(fx%attname)
          if (associated(fx%systemId)) deallocate(fx%systemId)
          if (associated(fx%publicId)) deallocate(fx%publicId)
          if (associated(fx%Ndata)) deallocate(fx%Ndata)
          fx%state = ST_INT_SUBSET
          fx%whitespace = WS_DISCARD
        elseif (str_vs(fx%token)=='NDATA') then
          if (pe) then
            call add_error(fx%error_stack, "Parameter entity cannot have NDATA declaration")
            goto 100
          endif
          fx%state = ST_DTD_ENTITY_NDATA_VALUE
        else
          call add_error(fx%error_stack, "Unexpected token in ENTITY")
          goto 100
        endif

      case (ST_DTD_ENTITY_NDATA_VALUE)
        !write(*,*) 'ST_DTD_ENTITY_NDATA_VALUE'
        !check is a name and exists in notationlist
        if (.not.checkName(str_vs(fx%token), fx%xml_version)) then
          call add_error(fx%error_stack, "Invalid name for Notation")
          goto 100
        endif
        if (notation_exists(fx%nlist, str_vs(fx%token))) then
          fx%Ndata => fx%token
          nullify(fx%token)
        else
          if (validCheck) then
            call add_error(fx%error_stack, "Attempt to use undeclared notation")
            goto 100
          endif
          fx%Ndata => fx%token
          nullify(fx%token)
        endif
        fx%state = ST_DTD_ENTITY_END
        fx%whitespace = WS_DISCARD

      case (ST_DTD_ENTITY_END)
        !write(*,*) 'ST_DTD_ENTITY_END'
        if (str_vs(fx%token)=='>') then
          if (processDTD) then
            call add_entity
          endif
          deallocate(fx%name)
          if (associated(fx%attname)) deallocate(fx%attname)
          if (associated(fx%systemId)) deallocate(fx%systemId)
          if (associated(fx%publicId)) deallocate(fx%publicId)
          if (associated(fx%Ndata)) deallocate(fx%Ndata)
          fx%state = ST_INT_SUBSET
        else
          call add_error(fx%error_stack, "Unexpected token at end of ENTITY")
          goto 100
        endif

      case (ST_DTD_NOTATION)
        !write(*,*) 'ST_DTD_NOTATION'
        ! check name is name FIXMe
        fx%name => fx%token
        nullify(fx%token)
        fx%state = ST_DTD_NOTATION_ID

      case (ST_DTD_NOTATION_ID)
        !write(*,*)'ST_DTD_NOTATION_ID'
        if (str_vs(fx%token)=='SYSTEM') then
          fx%state = ST_DTD_NOTATION_SYSTEM
        elseif (str_vs(fx%token)=='PUBLIC') then
          fx%state = ST_DTD_NOTATION_PUBLIC
        else
          call add_error(fx%error_stack, "Unexpected token after NOTATION")
          exit
        endif

      case (ST_DTD_NOTATION_SYSTEM)
        !write(*,*)'ST_DTD_NOTATION_SYSTEM'
        if (fx%token(1)/='"'.and.fx%token(1)/="'" &
          .and.fx%token(1)/=fx%token(size(fx%token))) then
          call add_error(fx%error_stack, "Invalid System Id literal")
          goto 100
        endif
        fx%systemId => vs_str_alloc(str_vs(fx%token(2:size(fx%token)-1)))
        deallocate(fx%token)
        fx%state = ST_DTD_NOTATION_END

      case (ST_DTD_NOTATION_PUBLIC)
        !write(*,*)'ST_DTD_NOTATION_PUBLIC'
        if (fx%token(1)/='"'.and.fx%token(1)/="'" &
          .and.fx%token(1)/=fx%token(size(fx%token))) then
          call add_error(fx%error_stack, "Invalid Public Id literal")
          goto 100
        endif
        if (checkPubId(str_vs(fx%token(2:size(fx%token)-1)))) then
          fx%publicId => vs_str_alloc(str_vs(fx%token(2:size(fx%token)-1)))
          deallocate(fx%token)
          fx%state = ST_DTD_NOTATION_PUBLIC_2
        else
          call add_error(fx%error_stack, "Invalid PUBLIC id in NOTATION")
          exit
        endif

      case (ST_DTD_NOTATION_PUBLIC_2)
        !write(*,*)'ST_DTD_NOTATION_PUBLIC_2'
        if (str_vs(fx%token)=='>') then
          if (validCheck) then
            if (notation_exists(fx%nlist, str_vs(fx%name))) then
              call add_error(fx%error_stack, "Duplicate notation declaration")
              exit
            endif
          endif
          if (processDTD) then
            call add_notation(fx%nlist, str_vs(fx%name), fx%xml_version, &
              publicId=str_vs(fx%publicId))
            if (present(notationDecl_handler)) &
              call notationDecl_handler(str_vs(fx%name), publicId=str_vs(fx%publicId)) 
          endif
          deallocate(fx%name)
          deallocate(fx%publicId)
          fx%state = ST_INT_SUBSET
        else
          if (fx%token(1)/='"'.and.fx%token(1)/="'" &
            .and.fx%token(1)/=fx%token(size(fx%token))) then
            call add_error(fx%error_stack, "Invalid System Id literal")
            goto 100
          endif
          fx%systemId => vs_str_alloc(str_vs(fx%token(2:size(fx%token)-1)))
          deallocate(fx%token)
          fx%state = ST_DTD_NOTATION_END
        endif

      case (ST_DTD_NOTATION_END)
        !write(*,*)'ST_DTD_NOTATION_END'
        if (str_vs(fx%token)=='>') then
          if (validCheck) then
            if (notation_exists(fx%nlist, str_vs(fx%name))) then
              call add_error(fx%error_stack, "Duplicate notation declaration")
              exit
            endif
          endif
          if (processDTD) then
            if (associated(fx%publicId)) then
              call add_notation(fx%nlist, str_vs(fx%name), fx%xml_version, &
                publicId=str_vs(fx%publicId), systemId=str_vs(fx%systemId))
              if (present(notationDecl_handler)) &
                call notationDecl_handler(str_vs(fx%name), &
                publicId=str_vs(fx%publicId), systemId=str_vs(fx%systemId)) 
            else
              call add_notation(fx%nlist, str_vs(fx%name), fx%xml_version, &
                systemId=str_vs(fx%systemId))
              if (present(notationDecl_handler)) &
                call notationDecl_handler(str_vs(fx%name), &
                systemId=str_vs(fx%systemId)) 
            endif
          endif
          if (associated(fx%publicId)) deallocate(fx%publicId)
          deallocate(fx%systemId)
          deallocate(fx%name)
          fx%state = ST_INT_SUBSET
          fx%whitespace = WS_DISCARD
        else
          call add_error(fx%error_stack, "Unexpected token in NOTATION")
          exit
        endif

      case (ST_CLOSE_DTD)
        !write(*,*) 'ST_CLOSE_DTD'
        ! token must be '>'
        if (present(endDTD_handler)) &
          call endDTD_handler
        fx%state = ST_MISC
        fx%context = CTXT_BEFORE_CONTENT

      end select

    end do

100 if (associated(tempString)) deallocate(tempString)

    if (iostat==io_eof) then ! error is end of file then
      ! EOF of main file
      if (fx%well_formed.and.fx%state==ST_MISC) then
        if (present(endDocument_handler)) &
          call endDocument_handler()
      else
        call add_error(fx%error_stack, "File is not well-formed")
        call sax_error(fx, error_handler)
      endif
    elseif (iostat==io_err) then ! we generated the error
      call sax_error(fx, error_handler)
    else ! Hard error - stop immediately
      if (fx%parse_stack>0) then !we are parsing an entity
        call add_error(fx%error_stack, "Error encountered processing entity.")
        call sax_error(fx, error_handler)
      else
        call sax_error(fx, error_handler)
      endif
    endif

  contains

    subroutine open_tag
      ! Is Name a valid QName?
      if (.not.checkQName(str_vs(fx%name), fx%xml_version)) then
        call add_error(fx%error_stack, "Invalid QName")
        return
      endif
      ! Are there any default values missing?
      call checkImplicitAttributes(fx%element_list, str_vs(fx%name), &
        fx%attributes)
      ! Check for namespace changes
      call checkNamespaces(fx%attributes, fx%nsDict, &
        len(fx%elstack), fx%xml_version, startPrefixMapping_handler)
      if (getURIofQName(fx,str_vs(fx%name))==invalidNS) then
        ! no namespace was found for the current element
        call add_error(fx%error_stack, "No namespace found for current element")
        return
      endif
      call checkXmlAttributes
      if (in_error(fx%error_stack)) return
      call push_elstack(str_vs(fx%name), fx%elstack)
      if (present(startElement_handler)) &
        call startElement_handler(getURIofQName(fx, str_vs(fx%name)), &
        getlocalNameofQName(str_vs(fx%name)), &
        str_vs(fx%name), fx%attributes)
      call destroy_dict(fx%attributes)
      fx%wf_stack(1) = fx%wf_stack(1) + 1
    end subroutine open_tag

    subroutine close_tag
      fx%wf_stack(1) = fx%wf_stack(1) - 1
      if (fx%wf_stack(1)<0) then
        call add_error(fx%error_stack, &
          'Ill-formed entity')
        return
      endif
      if (str_vs(fx%name)/=pop_elstack(fx%elstack)) then
        call add_error(fx%error_stack, "Mismatching close tag - expecting "//str_vs(fx%name))
        return
      endif
      if (present(endElement_handler)) &
        call endElement_handler(getURIofQName(fx, str_vs(fx%name)), &
        getlocalnameofQName(str_vs(fx%name)), &
        str_vs(fx%name))
      call checkEndNamespaces(fx%nsDict, len(fx%elstack)+1, &
        endPrefixMapping_handler)
    end subroutine close_tag

    subroutine add_entity
      !Parameter or General Entity?
      if (pe) then
        !Does entity with this name exist?
        if (.not.existing_entity(fx%pe_list, str_vs(fx%name))) then
          ! Internal or external?
          if (associated(fx%attname)) then ! it's internal
            call add_internal_entity(fx%pe_list, str_vs(fx%name), &
              str_vs(fx%attname(2:size(fx%attname)-1)), fx%xml_version) ! stripping off quotes
            ! FIXME need to expand value here before reporting ...
            if (present(internalEntityDecl_handler)) &
              call internalEntityDecl_handler('%'//str_vs(fx%name), str_vs(fx%attname(2:size(fx%attname)-1)))
          else ! PE can't have Ndata declaration
            if (associated(fx%publicId)) then
              call add_external_entity(fx%pe_list, str_vs(fx%name), fx%xml_version, &
                str_vs(fx%systemId), publicId=str_vs(fx%publicId))
              !FIXME need to 'fully resolve URL'
              if (present(externalEntityDecl_handler)) &
                call externalEntityDecl_handler('%'//str_vs(fx%name), &
                systemId=str_vs(fx%systemId), publicId=str_vs(fx%publicId))
            else
              call add_external_entity(fx%pe_list, str_vs(fx%name), fx%xml_version, &
                str_vs(fx%systemId))
              if (present(externalEntityDecl_handler)) &
                call externalEntityDecl_handler('%'//str_vs(fx%name), &
                systemId=str_vs(fx%systemId))
            endif
          endif
          ! else we ignore it
        endif
      else !It's a general entity
        if (.not.existing_entity(fx%ge_list, str_vs(fx%name))) then
          ! Internal or external?
          if (associated(fx%attname)) then ! it's internal
            call add_internal_entity(fx%ge_list, str_vs(fx%name), &
              str_vs(fx%attname(2:size(fx%attname)-1)), fx%xml_version)
            if (present(internalEntityDecl_handler)) &
              call internalEntityDecl_handler(str_vs(fx%name),&
              str_vs(fx%attname(2:size(fx%attname)-1))) ! stripping quotes
          else
            if (associated(fx%publicId).and.associated(fx%Ndata)) then
              call add_external_entity(fx%ge_list, str_vs(fx%name), fx%xml_version, &
                str_vs(fx%systemId), publicId=str_vs(fx%publicId), &
                notation=str_vs(fx%Ndata))
              if (present(unparsedEntityDecl_handler)) &
                call unparsedEntityDecl_handler(str_vs(fx%name), &
                systemId=str_vs(fx%systemId), publicId=str_vs(fx%publicId), &
                notation=str_vs(fx%Ndata))
            elseif (associated(fx%Ndata)) then
              call add_external_entity(fx%ge_list, str_vs(fx%name), fx%xml_version, &
                str_vs(fx%systemId), notation=str_vs(fx%Ndata))
              if (present(unparsedEntityDecl_handler)) &
                call unparsedEntityDecl_handler(str_vs(fx%name), &
                systemId=str_vs(fx%systemId), notation=str_vs(fx%Ndata))
            elseif (associated(fx%publicId)) then
              call add_external_entity(fx%ge_list, str_vs(fx%name), fx%xml_version, &
                str_vs(fx%systemId), publicId=str_vs(fx%publicId))
              !FIXME need to 'fully resolve URL'
              if (present(externalEntityDecl_handler)) &
                call externalEntityDecl_handler('%'//str_vs(fx%name), &
                systemId=str_vs(fx%systemId), publicId=str_vs(fx%publicId))
            else
              call add_external_entity(fx%ge_list, str_vs(fx%name), fx%xml_version, &
                str_vs(fx%systemId))
              if (present(externalEntityDecl_handler)) &
                call externalEntityDecl_handler('%'//str_vs(fx%name), &
                systemId=str_vs(fx%systemId))
            endif
          endif
        endif
      endif
    end subroutine add_entity

    function NotCDataNormalize(s1) result(s2)
      character(len=*), intent(in) :: s1
      character(len=len(s1)) :: s2

      integer :: i, i2
      logical :: w

      i2 = 1
      w = .true.
      do i = 1, len(s1)
        if (w.and.(s1(i:i).in.XML_WHITESPACE)) cycle
        w = .false.
        s2(i2:i2) = s1(i:i)
        i2 = i2 + 1
        if (s1(i:i).in.XML_WHITESPACE) w = .true.
      enddo
      s2(i2:) = ''
    end function NotCDataNormalize

    subroutine checkImplicitAttributes(e_list, eName, dict)
      type(element_list), intent(in) :: e_list
      character(len=*), intent(in) :: eName
      type(dictionary_t), intent(inout) :: dict

      integer :: i
      type(element_t), pointer :: e
      type(string_list) :: default_atts

      if (existing_element(e_list, eName)) then
        e => get_element(e_list, eName)
        default_atts = get_default_atts(e%attlist)
        do i = 1, size(default_atts%list), 2
          if (.not.has_key(dict, str_vs(default_atts%list(i)%s))) then
            call add_item_to_dict(dict, str_vs(default_atts%list(i)%s), &
              str_vs(default_atts%list(i+1)%s))
          endif
        enddo
        call destroy_string_list(default_atts)
      endif

    end subroutine checkImplicitAttributes

    subroutine checkXMLAttributes
      if (has_key(fx%attributes, 'xml:space')) then
        if (get_value(fx%attributes, 'xml:space')/='default' &
          .and. get_value(fx%attributes, 'xml:space')/='preserve') then
          call add_error(fx%error_stack, 'Illegal value of xml:space attribute')
        endif
      endif
      ! FIXME
      !if (has_key(fx%attributes, 'xml:id')) then
      ! must be an NCName
      ! must be unique ...
      !endif
      !if (has_key(fx%attributes, 'xml:base')
      !if (has_key(fx%attributes, 'xml:lang')
    end subroutine checkXMLAttributes
  end subroutine sax_parse


  subroutine sax_error(fx, error_handler)
    type(sax_parser_t), intent(inout) :: fx
    optional :: error_handler
    interface
      subroutine error_handler(msg)
        character(len=*), intent(in)     :: msg
      end subroutine error_handler
    end interface

    character, dimension(:), pointer :: errmsg

    integer :: i, m, n, n_err
    n = size(fx%error_stack%stack)
    n_err = n

    do i = 1, n
      n_err = n_err + size(fx%error_stack%stack(i)%msg) ! + spaces + size of entityref
    enddo
    allocate(errmsg(n_err))
    errmsg = ''
    n = 1
    do i = 1, size(fx%error_stack%stack)
      m = size(fx%error_stack%stack(i)%msg)
      errmsg(n:n+m-1) = fx%error_stack%stack(i)%msg
      errmsg(n+m:n+m) = " "
      n = n + m + 1
    enddo
    ! FIXME put location information in here
    if (present(error_handler)) then
      call error_handler(str_vs(errmsg))
      deallocate(errmsg)
    else
      call FoX_error(str_vs(errmsg))
    endif

  end subroutine sax_error

  pure function getURIofQName(fx, qname) result(URI)
    type(sax_parser_t), intent(in) :: fx
    character(len=*), intent(in) :: qName
    character(len=URIlength(fx, qname)) :: URI

    integer :: n
    n = index(QName, ':')
    if (n > 0) then
      URI = getnamespaceURI(fx%nsDict, QName(1:n-1))
    else
      URI = getnamespaceURI(fx%nsDict)
    endif

  end function getURIofQName

  pure function URIlength(fx, qname) result(l_u)
    type(sax_parser_t), intent(in) :: fx
    character(len=*), intent(in) :: qName
    integer :: l_u
    integer :: n
    n = index(QName, ':')
    if (n > 0) then
      l_u = len(getnamespaceURI(fx%nsDict, QName(1:n-1)))
    else
      l_u = len(getnamespaceURI(fx%nsDict))
    endif
  end function URIlength

  pure function getLocalNameofQName(qname) result(localName)
    character(len=*), intent(in) :: qName
    character(len=len(QName)-index(QName,':')) :: localName

    localName = QName(index(QName,':')+1:)
  end function getLocalNameofQName

end module m_sax_parser
