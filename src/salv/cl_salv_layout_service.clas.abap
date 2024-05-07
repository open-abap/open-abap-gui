CLASS cl_salv_layout_service DEFINITION PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS f4_layouts
      IMPORTING
        s_key        TYPE any
        layout       TYPE any OPTIONAL
        restrict     TYPE any OPTIONAL
      RETURNING
        VALUE(value) TYPE salv_s_layout_info.


    CLASS-METHODS get_layouts
      IMPORTING
        s_key           TYPE any
      RETURNING
        VALUE(t_layout) TYPE salv_t_layout_info.
ENDCLASS.

CLASS cl_salv_layout_service IMPLEMENTATION.

  METHOD get_layouts.
    ASSERT 1 = 2.
  ENDMETHOD.

  METHOD f4_layouts.
    ASSERT 1 = 2.
  ENDMETHOD.

ENDCLASS.