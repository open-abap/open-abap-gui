CLASS cl_salv_events DEFINITION PUBLIC CREATE PROTECTED.
  PUBLIC SECTION.

    INTERFACES if_salv_events_functions.
    INTERFACES if_salv_events_list.

    EVENTS added_function
      EXPORTING
        e_salv_function TYPE salv_de_function.

    EVENTS before_salv_function
      EXPORTING
        e_salv_function TYPE salv_de_function.

    EVENTS after_salv_function
      EXPORTING
        e_salv_function TYPE salv_de_function.

    EVENTS end_of_page
      EXPORTING
        VALUE(page)          TYPE i
        VALUE(r_end_of_page) TYPE REF TO cl_salv_form_element.

    EVENTS top_of_page
      EXPORTING
        VALUE(page)          TYPE i
        VALUE(r_top_of_page) TYPE REF TO cl_salv_form_element
        VALUE(table_index)   TYPE i.

  PROTECTED SECTION.

    METHODS raise_added_function
      IMPORTING
        e_salv_function TYPE salv_de_function.

    METHODS raise_before_salv_function
      IMPORTING
        e_salv_function TYPE salv_de_function.

    METHODS raise_after_salv_function
      IMPORTING
        e_salv_function TYPE salv_de_function.

    METHODS raise_end_of_page
      IMPORTING
        page  TYPE i
        value TYPE REF TO cl_salv_form_element.

    METHODS raise_top_of_page
      IMPORTING
        page        TYPE i
        table_index TYPE i
        value       TYPE REF TO cl_salv_form_element.

ENDCLASS.

CLASS cl_salv_events IMPLEMENTATION.

  METHOD raise_added_function.
    RAISE EVENT added_function
      EXPORTING
        e_salv_function = e_salv_function.
  ENDMETHOD.

  METHOD raise_before_salv_function.
    RAISE EVENT before_salv_function
      EXPORTING
        e_salv_function = e_salv_function.
  ENDMETHOD.

  METHOD raise_after_salv_function.
    RAISE EVENT after_salv_function
      EXPORTING
        e_salv_function = e_salv_function.
  ENDMETHOD.

  METHOD raise_end_of_page.
    RAISE EVENT end_of_page
      EXPORTING
        page          = page
        r_end_of_page = value.
  ENDMETHOD.

  METHOD raise_top_of_page.
    RAISE EVENT top_of_page
      EXPORTING
        page          = page
        table_index   = table_index
        r_top_of_page = value.
  ENDMETHOD.

ENDCLASS.
