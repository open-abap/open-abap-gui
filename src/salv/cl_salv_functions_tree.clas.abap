CLASS cl_salv_functions_tree DEFINITION PUBLIC INHERITING FROM cl_salv_functions.
  PUBLIC SECTION.

    METHODS set_help
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

ENDCLASS.

CLASS cl_salv_functions_tree IMPLEMENTATION.

  METHOD set_help.
    set_named_visibility( name  = 'HELP'
                          value = value ).
  ENDMETHOD.

ENDCLASS.
