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
    super->constructor( ).
  ENDMETHOD.

  METHOD create_header_information.
    r_value = NEW #( text    = text
                     tooltip = tooltip ).
    add_cell( row     = row
              column  = column
              colspan = colspan
              rowspan = rowspan
              element = r_value ).
  ENDMETHOD.

  METHOD create_label.
    r_value = NEW #( r_label_for = r_label_for
                     text        = text
                     tooltip     = tooltip ).
    add_cell( row     = row
              column  = column
              colspan = colspan
              rowspan = rowspan
              element = r_value ).
  ENDMETHOD.

  METHOD create_text.
    r_value = NEW #( text    = text
                     tooltip = tooltip ).
    add_cell( row     = row
              column  = column
              colspan = colspan
              rowspan = rowspan
              element = r_value ).
  ENDMETHOD.

  METHOD create_flow.
    r_value = NEW #( ).
    add_cell( row     = row
              column  = column
              colspan = colspan
              rowspan = rowspan
              element = r_value ).
  ENDMETHOD.

  METHOD create_grid.
    r_value = NEW #( ).
    add_cell( row     = row
              column  = column
              colspan = colspan
              rowspan = rowspan
              element = r_value ).
  ENDMETHOD.

  METHOD set_column_label_for.
    DATA lo_label TYPE REF TO cl_salv_form_label.
    DATA lo_text TYPE REF TO cl_salv_form_uie_text_view.

    LOOP AT mt_cells INTO DATA(ls_label) WHERE column = label_column.
      READ TABLE mt_cells INTO DATA(ls_text) WITH KEY row = ls_label-row column = text_column.
      IF sy-subrc = 0.
        CLEAR: lo_label, lo_text.
        TRY.
            lo_label ?= ls_label-element.
            lo_text ?= ls_text-element.
          CATCH cx_sy_move_cast_error.
            CLEAR: lo_label, lo_text.
        ENDTRY.
        IF lo_label IS BOUND AND lo_text IS BOUND.
          lo_label->set_label_for( lo_text ).
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
