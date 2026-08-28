CLASS cl_gui_html_viewer DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.

    CONSTANTS uiflag_no3dborder TYPE i VALUE 4.
    CONSTANTS m_id_sapevent TYPE i VALUE 1.

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

    METHODS go_forward
      EXCEPTIONS
        cntl_error.

    METHODS do_refresh
      EXCEPTIONS
        cntl_error.

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
        in_place TYPE abap_bool OPTIONAL
        url      TYPE c.

    METHODS set_ui_flag
      IMPORTING
        uiflag TYPE i DEFAULT 0
      EXCEPTIONS
        cntl_error.

    METHODS show_data
      IMPORTING
        url      TYPE c
        frame    TYPE c OPTIONAL
        in_place TYPE c DEFAULT 'X '
      EXCEPTIONS
        cntl_error
        cnht_error_not_allowed
        cnht_error_parameter
        dp_error_general.

  PRIVATE SECTION.
    DATA mv_document TYPE string.
    DATA mv_current_url TYPE string.
ENDCLASS.

CLASS cl_gui_html_viewer IMPLEMENTATION.
  METHOD set_ui_flag.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD show_data.
    mv_current_url = url.
    cl_gui_control=>set_payload( control = me payload = mv_document ).
  ENDMETHOD.

  METHOD show_url.
    mv_current_url = url.
    cl_gui_control=>set_payload( control = me payload = CONV string( url ) ).
  ENDMETHOD.

  METHOD load_data.
    LOOP AT data_table ASSIGNING FIELD-SYMBOL(<line>).
      mv_document = mv_document && CONV string( <line> ).
    ENDLOOP.
    assigned_url = url.
    mv_current_url = url.
    cl_gui_control=>set_payload( control = me payload = mv_document ).
  ENDMETHOD.

  METHOD get_current_url.
    url = mv_current_url.
  ENDMETHOD.

  METHOD close_document.
    CLEAR mv_document.
    cl_gui_control=>set_payload( control = me payload = `` ).
  ENDMETHOD.

  METHOD go_back.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD go_forward.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD do_refresh.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD constructor.
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'HTML_VIEWER' ).
    parent->add_child( me ).
  ENDMETHOD.

ENDCLASS.
