 


! This file is AUTOGENERATED!!!!
! Do not edit this file; edit m_wcml_metadata.m4 and regenerate.
!

module m_wcml_lists

  use FoX_common, only: str
  use FoX_wxml, only: xmlf_t
  use FoX_wxml, only: xml_NewElement, xml_EndElement
  use FoX_wxml, only: xml_AddAttribute

  implicit none
  private

  public :: cmlStartMetadataList
  public :: cmlEndMetadataList

  public :: cmlStartPropertyList
  public :: cmlEndPropertyList

  public :: cmlStartParameterList
  public :: cmlEndParameterList

  public :: cmlStartBandList
  public :: cmlEndBandList

  public :: cmlStartKpointList
  public :: cmlEndKpointList

  public :: cmlStartModule
  public :: cmlEndModule

  public :: cmlStartStep
  public :: cmlEndStep

contains


  subroutine cmlStartmetadataList(xf, dictRef, convention, title, id, name, role)

    type(xmlf_t), intent(inout) :: xf
    character(len=*), intent(in), optional :: dictRef
    character(len=*), intent(in), optional :: convention
    character(len=*), intent(in), optional :: title
    character(len=*), intent(in), optional :: id
    character(len=*), intent(in), optional :: name
    character(len=*), intent(in), optional :: role


    call xml_NewElement(xf, "metadataList")

    if (present(dictRef)) call xml_addAttribute(xf, "dictRef", dictRef)
    if (present(convention)) call xml_addAttribute(xf, "convention", convention)
    if (present(title)) call xml_addAttribute(xf, "title", title)
    if (present(id)) call xml_addAttribute(xf, "id", id)
    if (present(name)) call xml_addAttribute(xf, "name", name)
    if (present(role)) call xml_addAttribute(xf, "role", role)

 
  end subroutine cmlStartmetadataList

  subroutine cmlEndmetadataList(xf)
    type(xmlf_t), intent(inout) :: xf
    call xml_EndElement(xf, "metadataList")
  end subroutine cmlEndmetadataList




  subroutine cmlStartpropertyList(xf, dictRef, convention, title, id, ref, role)

    type(xmlf_t), intent(inout) :: xf
    character(len=*), intent(in), optional :: dictRef
    character(len=*), intent(in), optional :: convention
    character(len=*), intent(in), optional :: title
    character(len=*), intent(in), optional :: id
    character(len=*), intent(in), optional :: ref
    character(len=*), intent(in), optional :: role


    call xml_NewElement(xf, "propertyList")

    if (present(dictRef)) call xml_addAttribute(xf, "dictRef", dictRef)
    if (present(convention)) call xml_addAttribute(xf, "convention", convention)
    if (present(title)) call xml_addAttribute(xf, "title", title)
    if (present(id)) call xml_addAttribute(xf, "id", id)
    if (present(ref)) call xml_addAttribute(xf, "ref", ref)
    if (present(role)) call xml_addAttribute(xf, "role", role)

 
  end subroutine cmlStartpropertyList

  subroutine cmlEndpropertyList(xf)
    type(xmlf_t), intent(inout) :: xf
    call xml_EndElement(xf, "propertyList")
  end subroutine cmlEndpropertyList




  subroutine cmlStartparameterList(xf, dictRef, convention, title, id, ref, role)

    type(xmlf_t), intent(inout) :: xf
    character(len=*), intent(in), optional :: dictRef
    character(len=*), intent(in), optional :: convention
    character(len=*), intent(in), optional :: title
    character(len=*), intent(in), optional :: id
    character(len=*), intent(in), optional :: ref
    character(len=*), intent(in), optional :: role


    call xml_NewElement(xf, "parameterList")

    if (present(dictRef)) call xml_addAttribute(xf, "dictRef", dictRef)
    if (present(convention)) call xml_addAttribute(xf, "convention", convention)
    if (present(title)) call xml_addAttribute(xf, "title", title)
    if (present(id)) call xml_addAttribute(xf, "id", id)
    if (present(ref)) call xml_addAttribute(xf, "ref", ref)
    if (present(role)) call xml_addAttribute(xf, "role", role)

 
  end subroutine cmlStartparameterList

  subroutine cmlEndparameterList(xf)
    type(xmlf_t), intent(inout) :: xf
    call xml_EndElement(xf, "parameterList")
  end subroutine cmlEndparameterList




  subroutine cmlStartbandList(xf, dictRef, convention, title, id, ref, role)

    type(xmlf_t), intent(inout) :: xf
    character(len=*), intent(in), optional :: dictRef
    character(len=*), intent(in), optional :: convention
    character(len=*), intent(in), optional :: title
    character(len=*), intent(in), optional :: id
    character(len=*), intent(in), optional :: ref
    character(len=*), intent(in), optional :: role


    call xml_NewElement(xf, "bandList")

    if (present(dictRef)) call xml_addAttribute(xf, "dictRef", dictRef)
    if (present(convention)) call xml_addAttribute(xf, "convention", convention)
    if (present(title)) call xml_addAttribute(xf, "title", title)
    if (present(id)) call xml_addAttribute(xf, "id", id)
    if (present(ref)) call xml_addAttribute(xf, "ref", ref)
    if (present(role)) call xml_addAttribute(xf, "role", role)

 
  end subroutine cmlStartbandList

  subroutine cmlEndbandList(xf)
    type(xmlf_t), intent(inout) :: xf
    call xml_EndElement(xf, "bandList")
  end subroutine cmlEndbandList


!FIXME what attributes

  subroutine cmlStartkpointList(xf, dictRef, convention, title, id, ref, role)

    type(xmlf_t), intent(inout) :: xf
    character(len=*), intent(in), optional :: dictRef
    character(len=*), intent(in), optional :: convention
    character(len=*), intent(in), optional :: title
    character(len=*), intent(in), optional :: id
    character(len=*), intent(in), optional :: ref
    character(len=*), intent(in), optional :: role


    call xml_NewElement(xf, "kpointList")

    if (present(dictRef)) call xml_addAttribute(xf, "dictRef", dictRef)
    if (present(convention)) call xml_addAttribute(xf, "convention", convention)
    if (present(title)) call xml_addAttribute(xf, "title", title)
    if (present(id)) call xml_addAttribute(xf, "id", id)
    if (present(ref)) call xml_addAttribute(xf, "ref", ref)
    if (present(role)) call xml_addAttribute(xf, "role", role)

 
  end subroutine cmlStartkpointList

  subroutine cmlEndkpointList(xf)
    type(xmlf_t), intent(inout) :: xf
    call xml_EndElement(xf, "kpointList")
  end subroutine cmlEndkpointList


!FIXME what attributes

  subroutine cmlStartmodule(xf, serial, title, id, convention, dictRef, role)

    type(xmlf_t), intent(inout) :: xf
    character(len=*), intent(in), optional :: serial
    character(len=*), intent(in), optional :: title
    character(len=*), intent(in), optional :: id
    character(len=*), intent(in), optional :: convention
    character(len=*), intent(in), optional :: dictRef
    character(len=*), intent(in), optional :: role


    call xml_NewElement(xf, "module")

    if (present(serial)) call xml_addAttribute(xf, "serial", serial)
    if (present(title)) call xml_addAttribute(xf, "title", title)
    if (present(id)) call xml_addAttribute(xf, "id", id)
    if (present(convention)) call xml_addAttribute(xf, "convention", convention)
    if (present(dictRef)) call xml_addAttribute(xf, "dictRef", dictRef)
    if (present(role)) call xml_addAttribute(xf, "role", role)

 
  end subroutine cmlStartmodule

  subroutine cmlEndmodule(xf)
    type(xmlf_t), intent(inout) :: xf
    call xml_EndElement(xf, "module")
  end subroutine cmlEndmodule



  subroutine cmlStartStep(xf, type, index, id, title, convention)
    type(xmlf_t), intent(inout) :: xf
    character(len=*), intent(in), optional :: type
    character(len=*), intent(in), optional :: id
    integer, intent(in), optional :: index
    character(len=*), intent(in), optional :: title
    character(len=*), intent(in), optional :: convention

    if (present(index)) then
      call cmlStartModule(xf=xf, id=id, title=title, convention=convention, &
        dictRef=type, role='step', serial=str(index))
    else
      call cmlStartModule(xf=xf, id=id, title=title, convention=convention, &
        dictRef=type, role='step')
    endif
    
  end subroutine cmlStartStep


  subroutine cmlEndStep(xf)
    type(xmlf_t), intent(inout) :: xf

    call xml_EndElement(xf, 'module')
    
  end subroutine cmlEndStep


end module m_wcml_lists
