!
! This file is AUTOGENERATED
! To update, edit m_wcml_lattice.m4 and regenerate

module m_wcml_lattice

!FIXME: unimplemented bits:
! periodicity of latticevectors ...
! conversion between lattices & crystals ...
! <lattice> can also contain xtal coords or a <matrix>

  use m_common_realtypes, only: sp, dp
  use FoX_wxml, only: xmlf_t
  use FoX_wxml, only: xml_NewElement, xml_EndElement
  use FoX_wxml, only: xml_AddAttribute, xml_AddCharacters

  implicit none
  private

  character(len=*), parameter :: U_ANGSTR = "units:angstrom"
  character(len=*), parameter :: U_DEGREE = "units:degree"

  interface cmlAddCrystal
     module procedure cmlAddCrystalSP
     module procedure cmlAddCrystalDP
  end interface

  interface cmlAddLattice
    module procedure cmlAddLatticeSP
    module procedure cmlAddLatticeDP
  end interface

  public :: cmlAddCrystal
  public :: cmlAddLattice

contains

  subroutine cmlAddCrystalsp(xf, a, b, c, alpha, beta, gamma, z,&
    id, title, dictref, convention, lenunits, angunits, spaceGroup, lenfmt, angfmt)
    type(xmlf_t), intent(inout) :: xf
    real(kind=sp), intent(in)               :: a, b, c
    real(kind=sp), intent(in)               :: alpha
    real(kind=sp), intent(in)               :: beta
    real(kind=sp), intent(in)               :: gamma
    integer, intent(in), optional           :: z
    character(len=*), intent(in), optional :: id
    character(len=*), intent(in), optional :: title
    character(len=*), intent(in), optional :: dictref
    character(len=*), intent(in), optional :: convention
    character(len=*), intent(in), optional :: lenunits
    character(len=*), intent(in), optional :: angunits
    character(len=*), intent(in), optional :: spaceGroup
    character(len=*), intent(in), optional :: lenfmt
    character(len=*), intent(in), optional :: angfmt

    call xml_NewElement(xf=xf, name="crystal")
    if (present(id))      call xml_AddAttribute(xf, "id", id)
    if (present(title))   call xml_AddAttribute(xf, "title", title)
    if (present(dictref)) call xml_AddAttribute(xf, "dictRef", dictRef)
    if (present(convention)) call xml_AddAttribute(xf, "convention", convention)
    if (present(z)) call xml_AddAttribute(xf, "z", z)

    call xml_NewElement(xf=xf, name="cellParameter")
    call xml_AddAttribute(xf=xf, name="latticeType", value="real")
    call xml_AddAttribute(xf=xf, name="parameterType", value="length")
    if (present(lenunits)) then
      call xml_AddAttribute(xf=xf, name="units", value=lenunits)
    else
      call xml_AddAttribute(xf=xf, name="units", value=U_ANGSTR)
    endif
    call xml_AddCharacters(xf=xf, chars=(/a, b, c/), fmt=lenfmt)
    call xml_EndElement(xf=xf, name="cellParameter")

    call xml_NewElement(xf=xf, name="cellParameter")
    call xml_AddAttribute(xf=xf, name="latticeType", value="real")
    call xml_AddAttribute(xf=xf, name="parameterType", value="angle")
    if (present(angunits)) then
      call xml_AddAttribute(xf=xf, name="units", value=angunits)
    else
      call xml_AddAttribute(xf=xf, name="units", value=U_DEGREE)
    endif
    call xml_AddCharacters(xf=xf, chars=(/alpha, beta, gamma/), fmt=angfmt)
    call xml_EndElement(xf=xf, name="cellParameter")

    if (present(spaceGroup)) then
      call xml_NewElement(xf, "symmetry")
      call xml_AddAttribute(xf, "spaceGroup", spaceGroup)
      call xml_EndElement(xf, "symmetry")
    endif
    call xml_EndElement(xf, "crystal")

  end subroutine cmlAddCrystalsp

  subroutine cmlAddLatticesp(xf, cell, units, title, id, dictref, convention, latticeType, spaceType, fmt)
    type(xmlf_t), intent(inout) :: xf
    real(kind=sp), intent(in)              :: cell(3,3)
    character(len=*), intent(in), optional :: units       
    character(len=*), intent(in), optional :: id
    character(len=*), intent(in), optional :: title
    character(len=*), intent(in), optional :: dictref
    character(len=*), intent(in), optional :: convention
    character(len=*), intent(in), optional :: latticeType
    character(len=*), intent(in), optional :: spaceType
    character(len=*), intent(in), optional :: fmt

    integer :: i

    call xml_NewElement(xf, "lattice")
    if (present(id)) call xml_AddAttribute(xf, "id", id)
    if (present(title)) call xml_AddAttribute(xf, "title", title)
    if (present(dictref)) call xml_AddAttribute(xf, "dictRef", dictref)
    if (present(convention)) call xml_AddAttribute(xf, "convention", convention)
    if (present(latticeType)) call xml_AddAttribute(xf, "latticeType", latticeType)
    if (present(spaceType)) call xml_AddAttribute(xf, "spaceType", spaceType)

    do i = 1,3
      call xml_NewElement(xf, "latticeVector")
      if (present(units)) then
        call xml_AddAttribute(xf, "units", units)
      else
        call xml_AddAttribute(xf, "units", U_ANGSTR)
      endif
      call xml_AddAttribute(xf, "dictRef", "cml:latticeVector")
      call xml_AddCharacters(xf, cell(:,i), fmt)
      call xml_EndElement(xf, "latticeVector")
    enddo
    call xml_EndElement(xf, "lattice")

  end subroutine cmlAddLatticesp



  subroutine cmlAddCrystaldp(xf, a, b, c, alpha, beta, gamma, z,&
    id, title, dictref, convention, lenunits, angunits, spaceGroup, lenfmt, angfmt)
    type(xmlf_t), intent(inout) :: xf
    real(kind=dp), intent(in)               :: a, b, c
    real(kind=dp), intent(in)               :: alpha
    real(kind=dp), intent(in)               :: beta
    real(kind=dp), intent(in)               :: gamma
    integer, intent(in), optional           :: z
    character(len=*), intent(in), optional :: id
    character(len=*), intent(in), optional :: title
    character(len=*), intent(in), optional :: dictref
    character(len=*), intent(in), optional :: convention
    character(len=*), intent(in), optional :: lenunits
    character(len=*), intent(in), optional :: angunits
    character(len=*), intent(in), optional :: spaceGroup
    character(len=*), intent(in), optional :: lenfmt
    character(len=*), intent(in), optional :: angfmt

    call xml_NewElement(xf=xf, name="crystal")
    if (present(id))      call xml_AddAttribute(xf, "id", id)
    if (present(title))   call xml_AddAttribute(xf, "title", title)
    if (present(dictref)) call xml_AddAttribute(xf, "dictRef", dictRef)
    if (present(convention)) call xml_AddAttribute(xf, "convention", convention)
    if (present(z)) call xml_AddAttribute(xf, "z", z)

    call xml_NewElement(xf=xf, name="cellParameter")
    call xml_AddAttribute(xf=xf, name="latticeType", value="real")
    call xml_AddAttribute(xf=xf, name="parameterType", value="length")
    if (present(lenunits)) then
      call xml_AddAttribute(xf=xf, name="units", value=lenunits)
    else
      call xml_AddAttribute(xf=xf, name="units", value=U_ANGSTR)
    endif
    call xml_AddCharacters(xf=xf, chars=(/a, b, c/), fmt=lenfmt)
    call xml_EndElement(xf=xf, name="cellParameter")

    call xml_NewElement(xf=xf, name="cellParameter")
    call xml_AddAttribute(xf=xf, name="latticeType", value="real")
    call xml_AddAttribute(xf=xf, name="parameterType", value="angle")
    if (present(angunits)) then
      call xml_AddAttribute(xf=xf, name="units", value=angunits)
    else
      call xml_AddAttribute(xf=xf, name="units", value=U_DEGREE)
    endif
    call xml_AddCharacters(xf=xf, chars=(/alpha, beta, gamma/), fmt=angfmt)
    call xml_EndElement(xf=xf, name="cellParameter")

    if (present(spaceGroup)) then
      call xml_NewElement(xf, "symmetry")
      call xml_AddAttribute(xf, "spaceGroup", spaceGroup)
      call xml_EndElement(xf, "symmetry")
    endif
    call xml_EndElement(xf, "crystal")

  end subroutine cmlAddCrystaldp

  subroutine cmlAddLatticedp(xf, cell, units, title, id, dictref, convention, latticeType, spaceType, fmt)
    type(xmlf_t), intent(inout) :: xf
    real(kind=dp), intent(in)              :: cell(3,3)
    character(len=*), intent(in), optional :: units       
    character(len=*), intent(in), optional :: id
    character(len=*), intent(in), optional :: title
    character(len=*), intent(in), optional :: dictref
    character(len=*), intent(in), optional :: convention
    character(len=*), intent(in), optional :: latticeType
    character(len=*), intent(in), optional :: spaceType
    character(len=*), intent(in), optional :: fmt

    integer :: i

    call xml_NewElement(xf, "lattice")
    if (present(id)) call xml_AddAttribute(xf, "id", id)
    if (present(title)) call xml_AddAttribute(xf, "title", title)
    if (present(dictref)) call xml_AddAttribute(xf, "dictRef", dictref)
    if (present(convention)) call xml_AddAttribute(xf, "convention", convention)
    if (present(latticeType)) call xml_AddAttribute(xf, "latticeType", latticeType)
    if (present(spaceType)) call xml_AddAttribute(xf, "spaceType", spaceType)

    do i = 1,3
      call xml_NewElement(xf, "latticeVector")
      if (present(units)) then
        call xml_AddAttribute(xf, "units", units)
      else
        call xml_AddAttribute(xf, "units", U_ANGSTR)
      endif
      call xml_AddAttribute(xf, "dictRef", "cml:latticeVector")
      call xml_AddCharacters(xf, cell(:,i), fmt)
      call xml_EndElement(xf, "latticeVector")
    enddo
    call xml_EndElement(xf, "lattice")

  end subroutine cmlAddLatticedp



end module m_wcml_lattice