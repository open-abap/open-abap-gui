CLASS zcl_gg_selector DEFINITION PUBLIC INHERITING FROM cl_gui_selector.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_option,
             key  TYPE string,
             text TYPE string,
           END OF ty_option.
    TYPES ty_options TYPE STANDARD TABLE OF ty_option WITH DEFAULT KEY.

    METHODS set_options
      IMPORTING
        options TYPE ty_options.
ENDCLASS.

CLASS zcl_gg_selector IMPLEMENTATION.

  METHOD set_options.
    DATA lv_html TYPE string.

    LOOP AT options INTO DATA(ls_option).
      lv_html = lv_html && |<option value="{ escape_html( CONV string( ls_option-key ) ) }">{ escape_html( CONV string( ls_option-text ) ) }</option>|.
    ENDLOOP.
    cl_gui_control=>set_html( control = me
                              html    = lv_html ).
  ENDMETHOD.

ENDCLASS.
