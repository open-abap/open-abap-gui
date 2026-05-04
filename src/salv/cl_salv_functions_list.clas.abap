CLASS cl_salv_functions_list DEFINITION PUBLIC INHERITING FROM cl_salv_functions.
  PUBLIC SECTION.


    METHODS get_functions
      RETURNING
        VALUE(sdf) TYPE string.

    METHODS set_default
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_view_excel
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_group_filter
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_group_sort
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

ENDCLASS.

CLASS cl_salv_functions_list IMPLEMENTATION.
  METHOD set_group_sort.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_group_filter.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_view_excel.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_functions.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_default.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

ENDCLASS.