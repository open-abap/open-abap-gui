CLASS cl_salv_functions DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS add_function
        IMPORTING
        name     TYPE any
        icon     TYPE any OPTIONAL
        text     TYPE any OPTIONAL
        tooltip  TYPE any
        position TYPE any.

    METHODS set_function
      IMPORTING
        name    TYPE salv_de_function
        boolean TYPE abap_bool
      RAISING
        cx_salv_not_found
        cx_salv_wrong_call.

    METHODS set_all
      IMPORTING
        flag TYPE abap_bool OPTIONAL.

    METHODS get_functions
      RETURNING
        VALUE(function_list) TYPE salv_t_ui_func.

    METHODS remove_function
      IMPORTING
        name TYPE salv_de_function
      RAISING
        cx_salv_not_found
        cx_salv_wrong_call.

  PROTECTED SECTION.
    TYPES: BEGIN OF ty_function_state,
             name     TYPE salv_de_function,
             function TYPE REF TO cl_salv_function,
           END OF ty_function_state.
    TYPES ty_function_states TYPE STANDARD TABLE OF ty_function_state WITH DEFAULT KEY.
    DATA mt_functions TYPE ty_function_states.
    DATA mv_all TYPE abap_bool.

    METHODS set_named_visibility
      IMPORTING
        name  TYPE salv_de_function
        value TYPE abap_bool.

ENDCLASS.

CLASS cl_salv_functions IMPLEMENTATION.
  METHOD set_function.
    READ TABLE mt_functions INTO DATA(ls_function) WITH KEY name = name.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_salv_not_found.
    ENDIF.
    ls_function-function->set_visible( boolean ).
    MODIFY mt_functions FROM ls_function INDEX sy-tabix.
  ENDMETHOD.

  METHOD remove_function.
    READ TABLE mt_functions TRANSPORTING NO FIELDS WITH KEY name = name.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_salv_not_found.
    ENDIF.
    DELETE mt_functions INDEX sy-tabix.
  ENDMETHOD.

  METHOD get_functions.
    LOOP AT mt_functions INTO DATA(ls_function).
      APPEND VALUE #( r_function = ls_function-function ) TO function_list.
    ENDLOOP.
  ENDMETHOD.

  METHOD set_all.
    mv_all = flag.
    LOOP AT mt_functions INTO DATA(ls_function).
      ls_function-function->set_visible( flag ).
      MODIFY mt_functions FROM ls_function INDEX sy-tabix.
    ENDLOOP.
  ENDMETHOD.

  METHOD add_function.
    DATA lv_name TYPE salv_de_function.
    lv_name = CONV salv_de_function( name ).
    IF line_exists( mt_functions[ name = lv_name ] ).
      RETURN.
    ENDIF.
    DATA(lo_function) = NEW cl_salv_function( ).
    lo_function->set_name( lv_name ).
    lo_function->set_icon( CONV string( icon ) ).
    lo_function->set_text( CONV string( text ) ).
    lo_function->set_tooltip( CONV string( tooltip ) ).
    lo_function->set_visible( abap_true ).
    APPEND VALUE #( name = lv_name function = lo_function ) TO mt_functions.
  ENDMETHOD.

  METHOD set_named_visibility.
    READ TABLE mt_functions INTO DATA(ls_function) WITH KEY name = name.
    IF sy-subrc = 0.
      ls_function-function->set_visible( value ).
      MODIFY mt_functions FROM ls_function INDEX sy-tabix.
    ELSE.
      add_function(
        name     = name
        tooltip  = name
        position = 0 ).
      READ TABLE mt_functions INTO ls_function WITH KEY name = name.
      IF sy-subrc = 0.
        ls_function-function->set_visible( value ).
        MODIFY mt_functions FROM ls_function INDEX sy-tabix.
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
