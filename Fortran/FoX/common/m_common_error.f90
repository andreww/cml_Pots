module m_common_error

  use m_common_array_str, only: vs_str_alloc
  use pxf, only: pxfabort, pxfflush

  implicit none
  private

  integer, parameter :: ERR_NULL = 0
  integer, parameter :: ERR_WARNING = 1
  integer, parameter :: ERR_ERROR = 2
  integer, parameter :: ERR_FATAL = 3

  type error_t
    integer :: severity = ERR_NULL
    character, dimension(:), pointer :: msg => null()
  end type error_t

  type error_stack
    type(error_t), dimension(:), pointer :: stack => null()
  end type error_stack

  interface FoX_warning
    module procedure FoX_warning_base
  end interface

  interface FoX_error
    module procedure FoX_error_base
  end interface

  interface FoX_fatal
    module procedure FoX_fatal_base
  end interface

  public :: ERR_NULL
  public :: ERR_WARNING
  public :: ERR_ERROR
  public :: ERR_FATAL

  public :: error_t
  public :: error_stack

  public :: init_error_stack
  public :: destroy_error_stack

  public :: FoX_warning
  public :: FoX_error
  public :: FoX_fatal

  public :: FoX_warning_base
  public :: FoX_error_base
  public :: FoX_fatal_base

  public :: add_error
  public :: in_error

contains

  subroutine FoX_warning_base(msg)
    ! Emit warning, but carry on.
    character(len=*), intent(in) :: msg

    write(0,'(a)') 'WARNING(FoX)'
    write(0,'(a)')  msg
    call pxfflush(0)

  end subroutine FoX_warning_base

  subroutine FoX_error_base(msg)
    ! Emit error message and stop.
    ! No clean up is done here, but this can
    ! be overridden to include clean-up routines
    character(len=*), intent(in) :: msg

    write(0,'(a)') 'ERROR(FoX)'
    write(0,'(a)')  msg
    call pxfflush(0)

    stop

  end subroutine FoX_error_base

  subroutine FoX_fatal_base(msg)
    !Emit error message and abort with coredump.
    !No clean-up occurs

    character(len=*), intent(in) :: msg

    write(0,'(a)') 'ABORT(FOX)'
    write(0,'(a)')  msg
    call pxfflush(0)

    call pxfabort()

  end subroutine FoX_fatal_base


  subroutine init_error_stack(stack)
    type(error_stack), intent(inout) :: stack
    
    allocate(stack%stack(0))
  end subroutine init_error_stack

  subroutine destroy_error_stack(stack)
    type(error_stack), intent(inout) :: stack
    
    integer :: i

    do i = 1, size(stack%stack)
      deallocate(stack%stack(i)%msg)
    enddo
    deallocate(stack%stack)
  end subroutine destroy_error_stack


  subroutine add_error(stack, msg, severity)
    type(error_stack), intent(inout) :: stack
    character(len=*), intent(in) :: msg
    integer, intent(in), optional :: severity

    integer :: i, n
    type(error_t), dimension(size(stack%stack)) :: temp_stack

    n = size(stack%stack)

    do i = 1, n
      temp_stack(i)%msg => stack%stack(i)%msg
      temp_stack(i)%severity = stack%stack(i)%severity
    enddo
    deallocate(stack%stack)
    allocate(stack%stack(n+1))
    do i = 1, n
      stack%stack(i)%msg => temp_stack(i)%msg
      stack%stack(i)%severity = temp_stack(i)%severity
    enddo

    stack%stack(n+1)%msg => vs_str_alloc(msg)
    if (present(severity)) then
      stack%stack(n+1)%severity = severity
    else
      stack%stack(n+1)%severity = ERR_ERROR
    endif

  end subroutine add_error

  function in_error(stack) result(p)
    type(error_stack), intent(in) :: stack
    logical :: p

    if (associated(stack%stack)) then
      p = (size(stack%stack) > 0)
    else
      p = .false.
    endif
  end function in_error


end module m_common_error
