CLASS cl_dragdrop DEFINITION PUBLIC.
  PUBLIC SECTION.

    CONSTANTS copy TYPE i VALUE 1.
    CONSTANTS move TYPE i VALUE 2.

    METHODS add
      IMPORTING
        flavor         TYPE c
        dragsrc        TYPE abap_bool
        droptarget     TYPE abap_bool
        effect         TYPE i OPTIONAL
        effect_in_ctrl TYPE i OPTIONAL
      EXCEPTIONS
        already_defined
        obj_invalid.

    METHODS get
      IMPORTING
        flavor         TYPE c
      EXPORTING
        isdragsrc      TYPE abap_bool
        isdroptarget   TYPE abap_bool
        effect         TYPE i
        effect_in_ctrl TYPE i
      EXCEPTIONS
        not_found
        obj_invalid.

    METHODS get_handle
      EXPORTING
        handle TYPE i
      EXCEPTIONS
        obj_invalid.

ENDCLASS.

CLASS cl_dragdrop IMPLEMENTATION.
  METHOD add.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_handle.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.