CLASS cl_salv_layout_service DEFINITION PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS f4_layouts
      IMPORTING
        s_key        TYPE salv_s_layout_key
        layout       TYPE any OPTIONAL
        restrict     TYPE any OPTIONAL
      RETURNING
        VALUE(value) TYPE salv_s_layout_info.

    CLASS-METHODS get_default_layout
      IMPORTING
        s_key         TYPE salv_s_layout_key
        restrict      TYPE any OPTIONAL
        mandt         TYPE mandt DEFAULT sy-mandt
        bypass_buffer TYPE abap_bool OPTIONAL
      RETURNING
        VALUE(value)  TYPE salv_s_layout_info.

    CLASS-METHODS get_layouts
      IMPORTING
        s_key           TYPE salv_s_layout_key
      RETURNING
        VALUE(t_layout) TYPE salv_t_layout_info.
ENDCLASS.

CLASS cl_salv_layout_service IMPLEMENTATION.
  METHOD get_default_layout.
    CLEAR value.
  ENDMETHOD.

  METHOD get_layouts.
    CLEAR t_layout.
  ENDMETHOD.

  METHOD f4_layouts.
    CLEAR value.
  ENDMETHOD.

ENDCLASS.
