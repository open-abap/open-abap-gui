CLASS cl_gui_html_viewer DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
    EVENTS sapevent
      EXPORTING
        VALUE(action)      TYPE c OPTIONAL
        VALUE(frame)       TYPE c OPTIONAL
        VALUE(getdata)     TYPE c OPTIONAL
        VALUE(postdata)    TYPE any OPTIONAL
        VALUE(query_table) TYPE any OPTIONAL.

    METHODS constructor
      IMPORTING
        parent               TYPE REF TO cl_gui_container
        query_table_disabled TYPE c OPTIONAL.

    METHODS go_back.

    METHODS close_document.

    METHODS get_current_url
      EXPORTING
        url TYPE c.

    METHODS load_data
      IMPORTING
        url          TYPE c OPTIONAL
        type         TYPE c DEFAULT 'text'
        subtype      TYPE c DEFAULT 'html'
        size         TYPE i DEFAULT 0
      EXPORTING
        assigned_url TYPE c
      CHANGING
        data_table   TYPE STANDARD TABLE.

    METHODS show_url
      IMPORTING
        url TYPE c.
ENDCLASS.

CLASS cl_gui_html_viewer IMPLEMENTATION.
  METHOD show_url.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD load_data.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_current_url.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD close_document.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD go_back.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD constructor.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.