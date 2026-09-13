CLASS cl_salv_layout DEFINITION PUBLIC.
  PUBLIC SECTION.
    CONSTANTS restrict_none TYPE i VALUE 3.

    METHODS set_key
      IMPORTING
        value TYPE salv_s_layout_key.

    METHODS set_save_restriction
      IMPORTING
        value TYPE any OPTIONAL.

    METHODS set_default
      IMPORTING
        value TYPE abap_bool.

    METHODS has_default
      RETURNING
        VALUE(value) TYPE abap_bool.

    METHODS set_initial_layout
      IMPORTING
        value TYPE clike.

    METHODS get_default_layout
      RETURNING
        VALUE(sdf) TYPE string.

    METHODS get_layouts
      RETURNING
        VALUE(value) TYPE salv_t_layout_info.

    METHODS get_current_layout
      RETURNING
        VALUE(value) TYPE salv_s_layout.

    METHODS f4_layouts
      RETURNING
        VALUE(value) TYPE salv_s_layout.

  PRIVATE SECTION.
    DATA ms_key TYPE salv_s_layout_key.
    DATA mv_save_restriction TYPE i.
    DATA mv_default TYPE abap_bool.
    DATA mv_initial_layout TYPE string.
    DATA ms_current_layout TYPE salv_s_layout.
ENDCLASS.

CLASS cl_salv_layout IMPLEMENTATION.
  METHOD get_layouts.
    CLEAR value.
  ENDMETHOD.

  METHOD get_default_layout.
    sdf = mv_initial_layout.
  ENDMETHOD.

  METHOD get_current_layout.
    value = ms_current_layout.
  ENDMETHOD.

  METHOD f4_layouts.
    value = ms_current_layout.
  ENDMETHOD.

  METHOD set_key.
    ms_key = value.
  ENDMETHOD.

  METHOD set_initial_layout.
    mv_initial_layout = value.
  ENDMETHOD.

  METHOD set_save_restriction.
    mv_save_restriction = value.
  ENDMETHOD.

  METHOD set_default.
    mv_default = value.
  ENDMETHOD.

  METHOD has_default.
    value = mv_default.
  ENDMETHOD.
ENDCLASS.
