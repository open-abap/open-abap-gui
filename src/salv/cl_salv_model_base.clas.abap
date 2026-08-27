CLASS cl_salv_model_base DEFINITION PUBLIC.
  PUBLIC SECTION.

    CONSTANTS c_functions_none TYPE i VALUE 0.
    CONSTANTS c_functions_default TYPE i VALUE 1.
    CONSTANTS c_functions_all TYPE i VALUE 2.

    METHODS set_screen_status
      IMPORTING
        pfstatus      TYPE any
        set_functions TYPE any OPTIONAL
        report        TYPE any.

ENDCLASS.

CLASS cl_salv_model_base IMPLEMENTATION.

  METHOD set_screen_status.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
