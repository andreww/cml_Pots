module m_common_entities

  ! Entity management

  ! It deals with: 
  !    1. The five standard entities (gt,lt,amp,apos,quot)
  !    2. Character entities  (but only within the range of the char intrinsic)
  !    3. Parameter entities
  !    4. Internal entities
  ! In addition, it has the capacity to make lists of
  !    1. External parsed entities
  !    2. External unparsed entities
  ! Though nothing is done with them currently elsewhere in FoX.

  !FIXME need to worry about removing entities from a list.

  use m_common_array_str, only: str_vs, vs_str, vs_str_alloc
  use m_common_charset, only: digits, hexdigits
  use m_common_error, only: ERR_WARNING, ERR_ERROR, &
    FoX_warning, FoX_error, error_stack, add_error
  use m_common_format, only: str_to_int_10, str_to_int_16
  use m_common_namecheck, only: checkName, &
    checkCharacterEntityReference, checkEntityValue

  implicit none
  private

  type entity_t
    logical :: external
    character(len=1), dimension(:), pointer :: code => null()
    character(len=1), dimension(:), pointer :: repl => null()
    character(len=1), dimension(:), pointer :: publicId => null()
    character(len=1), dimension(:), pointer :: systemId => null()
    character(len=1), dimension(:), pointer :: notation => null()
  end type entity_t

  type entity_list
    private
    type(entity_t), dimension(:), pointer :: list => null()
  end type entity_list

  public :: is_unparsed_entity
  public :: is_external_entity

  public :: expand_entity_text
  public :: expand_entity_text_len
  public :: existing_entity

  public :: expand_char_entity

  public :: expand_entity
  public :: expand_entity_len

  public :: expand_entity_value_alloc

  public :: entity_list
  public :: init_entity_list
  public :: reset_entity_list
  public :: destroy_entity_list
  public :: print_entity_list
  public :: add_internal_entity
  public :: add_external_entity
  public :: pop_entity_list

contains


  function shallow_copy_entity(ent1) result(ent2)
    type(entity_t), intent(in) :: ent1
    type(entity_t) :: ent2
    
    ent2%external = ent1%external
    ent2%code => ent1%code
    ent2%repl => ent1%repl
    ent2%publicId => ent1%publicId
    ent2%systemId => ent1%systemId
    ent2%notation => ent1%notation

  end function shallow_copy_entity


  subroutine destroy_entity(ent)
    type(entity_t), intent(inout) :: ent
    
    deallocate(ent%code)
    deallocate(ent%repl)
    deallocate(ent%publicId)
    deallocate(ent%systemId)
    deallocate(ent%notation)

  end subroutine destroy_entity


  subroutine init_entity_list(ents)
    type(entity_list), intent(inout) :: ents

    if (associated(ents%list)) deallocate(ents%list)
    allocate(ents%list(0))

  end subroutine init_entity_list


  subroutine reset_entity_list(ents)
    type(entity_list), intent(inout) :: ents

    call destroy_entity_list(ents)
    call init_entity_list(ents)

  end subroutine reset_entity_list


  subroutine destroy_entity_list(ents)
    type(entity_list), intent(inout) :: ents

    integer :: i, n

    n = size(ents%list)
    do i = 1, n
      call destroy_entity(ents%list(i))
    enddo
    deallocate(ents%list)
  end subroutine destroy_entity_list

  function pop_entity_list(ents) result(name)
    type(entity_list), intent(inout) :: ents
    character(len=size(ents%list(size(ents%list))%code)) :: name
    
    type(entity_t), pointer :: ents_tmp(:)
    integer :: i, n
    n = size(ents%list)

    ents_tmp => ents%list
    allocate(ents%list(n-1))
    do i = 1, n - 1
      ents%list(i) = shallow_copy_entity(ents_tmp(i))
    enddo
    name = str_vs(ents_tmp(i)%code)
    call destroy_entity(ents_tmp(i))
    deallocate(ents_tmp)
  end function pop_entity_list

  subroutine print_entity_list(ents)
    type(entity_list), intent(in) :: ents

    integer :: i, n

    n = size(ents%list)
    write(*,'(a)') '>ENTITYLIST'
    do i = 1, n
      write(*,'(a)') str_vs(ents%list(i)%code)
      write(*,'(a)') str_vs(ents%list(i)%repl)
      write(*,'(a)') str_vs(ents%list(i)%publicId)
      write(*,'(a)') str_vs(ents%list(i)%systemId)
      write(*,'(a)') str_vs(ents%list(i)%notation)
    enddo
    write(*,'(a)') '<ENTITYLIST'
  end subroutine print_entity_list


  subroutine add_entity(ents, code, repl, publicId, systemId, notation, external)
    type(entity_list), intent(inout) :: ents
    character(len=*), intent(in) :: code
    character(len=*), intent(in) :: repl
    character(len=*), intent(in) :: publicId
    character(len=*), intent(in) :: systemId
    character(len=*), intent(in) :: notation
    logical, intent(in) :: external

    type(entity_t), pointer :: ents_tmp(:)
    integer :: i, n

    ! This should only ever be called by add_internal_entity or add_external_entity
    ! below, so we don't bother sanity-checking input. Note especially we don't 
    ! check for duplication of entities, so this will happily add another entity
    ! of the same name if you ask it to. This should't matter though, since the
    ! first defined will always be picked up first, which is what the XML spec
    ! requires.

    n = size(ents%list)

    ents_tmp => ents%list
    allocate(ents%list(n+1))
    do i = 1, n
      ents%list(i) = shallow_copy_entity(ents_tmp(i))
    enddo
    deallocate(ents_tmp)
    ents%list(i)%external = external
    ents%list(i)%code => vs_str_alloc(code)
    ents%list(i)%repl => vs_str_alloc(repl)
    ents%list(i)%publicId => vs_str_alloc(publicId)
    ents%list(i)%systemId => vs_str_alloc(systemId)
    ents%list(i)%notation => vs_str_alloc(notation)
  end subroutine add_entity


  subroutine add_internal_entity(ents, code, repl, xv)
    type(entity_list), intent(inout) :: ents
    character(len=*), intent(in) :: code
    character(len=*), intent(in) :: repl
    integer, intent(in) :: xv

    !if (.not.checkName(code, xv)) &
    !  call FoX_error("Illegal entity name: "//code)
    !if (.not.checkEntityValue(repl)) &
    !  call FoX_error("Illegal entity value: "//repl)
    ! FIXME
    call add_entity(ents, code, repl, "", "", "", .false.)
  end subroutine add_internal_entity

  
  subroutine add_external_entity(ents, code, xv, systemId, publicId, notation)
    type(entity_list), intent(inout) :: ents
    character(len=*), intent(in) :: code
    integer, intent(in) :: xv
    character(len=*), intent(in) :: systemId
    character(len=*), intent(in), optional :: publicId
    character(len=*), intent(in), optional :: notation

    if (present(publicId) .and. present(notation)) then
      call add_entity(ents, code, "", systemId, publicId, notation, .true.)
    elseif (present(publicId)) then
      call add_entity(ents, code, "", systemId, publicId, "", .true.)
    elseif (present(notation)) then
      call add_entity(ents, code, "", systemId, "", notation, .true.)
    else
      call add_entity(ents, code, "", systemId, "", "", .true.)
    endif
  end subroutine add_external_entity


  function is_unparsed_entity(ents, code) result(p)
    type(entity_list), intent(in) :: ents
    character(len=*), intent(in) :: code
    logical :: p

    integer :: i

    p = .false.

    do i = 1, size(ents%list)
      if (code == str_vs(ents%list(i)%code)) then
        p = (size(ents%list(i)%notation)>0)
        exit
      endif
    enddo
  end function is_unparsed_entity

  function is_external_entity(ents, code) result(p)
    type(entity_list), intent(in) :: ents
    character(len=*), intent(in) :: code
    logical :: p

    integer :: i

    p = .false.

    do i = 1, size(ents%list)
      if (code == str_vs(ents%list(i)%code)) then
        p = ents%list(i)%external
        exit
      endif
    enddo
  end function is_external_entity
 
  pure function expand_char_entity_len(code) result(n)
    character(len=*), intent(in) :: code
    integer :: n

    integer :: number

    if (code(1:1) == "#") then
      if (code(2:2) == "x") then       ! hex character reference
        if (verify(code(3:), hexdigits) == 0) then
          number = str_to_int_16(code(3:))   
          if (0 <= number .and. number <= 128) then
            n = 1
          else
            n = len(code) + 2
          endif
        else 
           n = 0
        endif
      else                             ! decimal character reference
        if (verify(code(3:), digits) == 0) then
          number = str_to_int_10(code(2:))
          if (0 <= number .and. number <= 128) then
            n = 1
          else
            n = len(code) + 2
          endif
        else 
          n = 0
        endif
      endif
    else
      n = 0
    endif
  end function expand_char_entity_len


  function expand_char_entity(code) result(repl)
    character(len=*), intent(in) :: code
    character(len=expand_char_entity_len(code)) :: repl

    integer :: number

    select case (len(repl))
    case (0)
      call FoX_error("Invalid character entity reference")
    case (1)  
      if (code(2:2) == "x") then       ! hex character reference
        number = str_to_int_16(code(3:))   
      else                             ! decimal character reference
        number = str_to_int_10(code(2:))
      endif
      repl = achar(number)
      ! FIXME what about > 127 ...
    case default
      repl = "&"//code//";"
    end select

  end function expand_char_entity


  pure function existing_entity(ents, code) result(p)
    type(entity_list), intent(in) :: ents
    character(len=*), intent(in)  :: code
    logical :: p

    integer :: i

    p = .false.
    
!FIXME the following test is not entirely in accordance with the valid chars check we do elsewhere...

    do i = 1, size(ents%list)
      if (code == str_vs(ents%list(i)%code)) then
        p = .true.
        return
      endif
    enddo

  end function existing_entity


  pure function expand_entity_text_len(ents, code) result(n)
    type(entity_list), intent(in) :: ents
    character(len=*), intent(in)  :: code
    integer :: n

    integer :: i

    do i = 1, size(ents%list)
      if (code == str_vs(ents%list(i)%code)) then
        n = size(ents%list(i)%repl)
      endif
    enddo

  end function expand_entity_text_len


  function expand_entity_text(ents, code) result(repl)
    type(entity_list), intent(in) :: ents
    character(len=*), intent(in)  :: code
    character(len=expand_entity_text_len(ents, code)) :: repl

    integer :: i

    ! No error checking - make sure entity exists before calling it.

    do i = 1, size(ents%list)
      if (code == str_vs(ents%list(i)%code)) then
        repl = str_vs(ents%list(i)%repl)
        exit
      endif
    enddo

  end function expand_entity_text


  pure function expand_entity_len(ents, code) result(n)
    type(entity_list), intent(in) :: ents
    character(len=*), intent(in)  :: code
    integer :: n

    integer :: i

    do i = 1, size(ents%list)
      if (code == str_vs(ents%list(i)%code)) then
        n = size(ents%list(i)%repl)
      endif
    enddo

  end function expand_entity_len


  function expand_entity(ents, code) result(repl)
    type(entity_list), intent(in) :: ents
    character(len=*), intent(in)  :: code
    character(len=expand_entity_len(ents, code)) :: repl
    
    integer :: i
    
    do i = 1, size(ents%list)
      if (code == str_vs(ents%list(i)%code)) then
        repl = str_vs(ents%list(i)%repl)
      endif
    enddo

  end function expand_entity
    

  function expand_entity_value_alloc(repl, xv, stack) result(repl_new)
    !perform expansion of character entity references
    ! check that no parameter entities are present
    ! and check that all general entity references are well-formed.
    !before storing it.
    !
    ! This is only ever called from the SAX parser
    ! (might it be called from WXML?)
    ! so input & output is with character arrays, not strings.
    character, dimension(:), intent(in) :: repl
    integer, intent(in) :: xv
    type(error_stack), intent(inout) :: stack
    character, dimension(:), pointer :: repl_new

    character, dimension(size(repl)) :: repl_temp
    integer :: i, i2, j
    
    allocate(repl_new(0))
    if (index(str_vs(repl),'%')/=0) then
      call add_error(stack, "Not allowed % in internal subset general entity value")
      return
    endif

    i = 1
    i2 = 1
    do
      if (i>size(repl)) exit
      if (repl(i)=='&') then
        j = index(str_vs(repl(i+1:)),';')
        if (j==0) then
          call add_error(stack, "Not allowed bare & in entity value")
          return
        elseif (checkName(str_vs(repl(i+1:i+j-1)), xv)) then
          repl_temp(i2:i2+j) = repl(i:i+j)
          i = i + j + 1
          i2 = i2 + j + 1
        elseif (checkCharacterEntityReference(str_vs(repl(i+1:i+j-1)), xv)) then
          !if it is ascii then
          repl_temp(i2:i2) = vs_str(expand_char_entity(str_vs(repl(i+1:i+j-1))))
          i = i + j + 1
          i2 = i2 + 1
        else
          call add_error(stack, "Invalid entity reference in entity value")
          return
        endif
      else
        repl_temp(i2) = repl(i)
        i = i + 1
        i2 = i2 + 1
      endif
    enddo

    deallocate(repl_new)
    allocate(repl_new(i2-1))
    repl_new = repl_temp(:i2-1)

  end function expand_entity_value_alloc

end module m_common_entities
