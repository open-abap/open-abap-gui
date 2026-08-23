CLASS cl_salv_form_layout_grid DEFINITION PUBLIC INHERITING FROM cl_salv_form_element.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        columns TYPE i OPTIONAL.

    METHODS create_header_information
      IMPORTING
        row            TYPE i OPTIONAL
        column         TYPE i OPTIONAL
        rowspan        TYPE i OPTIONAL
        colspan        TYPE i OPTIONAL
        text           TYPE any OPTIONAL
        tooltip        TYPE any OPTIONAL
      RETURNING
        VALUE(r_value) TYPE REF TO cl_salv_form_header_info.

    METHODS create_label
      IMPORTING
        row            TYPE i OPTIONAL
        column         TYPE i OPTIONAL
        rowspan        TYPE i OPTIONAL
        colspan        TYPE i OPTIONAL
        text           TYPE any OPTIONAL
        tooltip        TYPE any OPTIONAL
      RETURNING
        VALUE(r_value) TYPE REF TO cl_salv_form_label.

ENDCLASS.

CLASS cl_salv_form_layout_grid IMPLEMENTATION.

  METHOD constructor.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD create_header_information.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD create_label.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
