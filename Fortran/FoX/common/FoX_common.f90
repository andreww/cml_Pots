module FoX_common

  use m_common_attrs
  use m_common_format

  implicit none
  private

  character(len=*), parameter :: FoX_version = '2.1.0'

  public :: FoX_version

  public :: str
  public :: operator(//)

!These are all exported through SAX now
  public :: dictionary_t
!SAX functions
  public :: getIndex 
  public :: getLength
  public :: getLocalName
  public :: getQName
  public :: getURI
  public :: getValue
  public :: getType
!For convenience
  public :: len
  public :: hasKey

  public :: print_dict

end module FoX_common
