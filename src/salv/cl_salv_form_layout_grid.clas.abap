CLASS cl_salv_form_layout_grid DEFINITION PUBLIC INHERITING FROM cl_salv_form_uie_layout_grid.
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
        r_label_for    TYPE REF TO cl_salv_form_text OPTIONAL
        text           TYPE any OPTIONAL
        tooltip        TYPE any OPTIONAL
      RETURNING
        VALUE(r_value) TYPE REF TO cl_salv_form_label.

    METHODS create_text
      IMPORTING
        row            TYPE i OPTIONAL
        column         TYPE i OPTIONAL
        rowspan        TYPE i OPTIONAL
        colspan        TYPE i OPTIONAL
        text           TYPE any OPTIONAL
        tooltip        TYPE any OPTIONAL
      RETURNING
        VALUE(r_value) TYPE REF TO cl_salv_form_text.

    METHODS create_flow
      IMPORTING
        row            TYPE i OPTIONAL
        column         TYPE i OPTIONAL
        rowspan        TYPE i OPTIONAL
        colspan        TYPE i OPTIONAL
      RETURNING
        VALUE(r_value) TYPE REF TO cl_salv_form_layout_flow.

    METHODS create_grid
      IMPORTING
        row            TYPE i OPTIONAL
        column         TYPE i OPTIONAL
        rowspan        TYPE i OPTIONAL
        colspan        TYPE i OPTIONAL
      RETURNING
        VALUE(r_value) TYPE REF TO cl_salv_form_layout_grid.

    METHODS set_column_label_for
      IMPORTING
        label_column TYPE i
        text_column  TYPE i.

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

  METHOD create_text.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD create_flow.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD create_grid.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_column_label_for.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
