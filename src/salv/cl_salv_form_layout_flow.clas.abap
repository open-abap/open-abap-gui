CLASS cl_salv_form_layout_flow DEFINITION PUBLIC INHERITING FROM cl_salv_form_element.
  PUBLIC SECTION.

    METHODS create_text
      IMPORTING
        position       TYPE i OPTIONAL
        text           TYPE any OPTIONAL
        tooltip        TYPE any OPTIONAL
      RETURNING
        VALUE(r_value) TYPE REF TO cl_salv_form_text.

    METHODS create_label
      IMPORTING
        position       TYPE i OPTIONAL
        r_label_for    TYPE REF TO cl_salv_form_text OPTIONAL
        text           TYPE any OPTIONAL
        tooltip        TYPE any OPTIONAL
      RETURNING
        VALUE(r_value) TYPE REF TO cl_salv_form_label.

    METHODS create_header_information
      IMPORTING
        position       TYPE i OPTIONAL
        text           TYPE any OPTIONAL
        tooltip        TYPE any OPTIONAL
      RETURNING
        VALUE(r_value) TYPE REF TO cl_salv_form_header_info.

    METHODS create_flow
      IMPORTING
        position       TYPE i OPTIONAL
      RETURNING
        VALUE(r_value) TYPE REF TO cl_salv_form_layout_flow.

ENDCLASS.

CLASS cl_salv_form_layout_flow IMPLEMENTATION.

  METHOD create_text.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD create_label.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD create_header_information.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD create_flow.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
