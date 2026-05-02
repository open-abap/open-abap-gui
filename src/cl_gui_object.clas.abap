CLASS cl_gui_object DEFINITION PUBLIC.
  PUBLIC SECTION.

    CLASS-DATA activex TYPE abap_bool READ-ONLY.
    CLASS-DATA javabean TYPE abap_bool READ-ONLY.

    METHODS is_valid
      EXPORTING
        VALUE(result) TYPE i.

  PROTECTED SECTION.
    METHODS call_method
      IMPORTING
        p1         TYPE any OPTIONAL
        p2         TYPE any OPTIONAL
        p3         TYPE any OPTIONAL
        p4         TYPE any OPTIONAL
        p5         TYPE any OPTIONAL
        p6         TYPE any OPTIONAL
        p7         TYPE any OPTIONAL
        p8         TYPE any OPTIONAL
        p9         TYPE any OPTIONAL
        p10        TYPE any OPTIONAL
        p11        TYPE any OPTIONAL
        p12        TYPE any OPTIONAL
        p13        TYPE any OPTIONAL
        p14        TYPE any OPTIONAL
        p15        TYPE any OPTIONAL
        p16        TYPE any OPTIONAL
        method     TYPE c
        p_count    TYPE i OPTIONAL
        queue_only TYPE c DEFAULT 'X'
        keep_cache TYPE abap_bool OPTIONAL
      EXPORTING
        result     TYPE any
      EXCEPTIONS
        cntl_error
        cntl_system_error.
ENDCLASS.

CLASS cl_gui_object IMPLEMENTATION.
  METHOD call_method.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD is_valid.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.