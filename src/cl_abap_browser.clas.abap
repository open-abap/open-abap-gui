CLASS cl_abap_browser DEFINITION PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS show_xml
      IMPORTING
        xml_string  TYPE string OPTIONAL
        title       TYPE string OPTIONAL
        container   TYPE REF TO cl_gui_container OPTIONAL
        dialog      TYPE abap_bool OPTIONAL
        xml_xstring TYPE xstring OPTIONAL
        printing    TYPE abap_bool OPTIONAL.

    CLASS-METHODS show_html
      IMPORTING
        html_string TYPE string
        title       TYPE string OPTIONAL
        container   TYPE REF TO cl_gui_container OPTIONAL
        dialog      TYPE abap_bool OPTIONAL
        printing    TYPE abap_bool OPTIONAL.

    CLASS-METHODS get_last_html
      RETURNING
        VALUE(html_string) TYPE string.

    CLASS-METHODS get_last_title
      RETURNING
        VALUE(title) TYPE string.

  PRIVATE SECTION.
    CLASS-DATA mv_html TYPE string.
    CLASS-DATA mv_title TYPE string.
    CLASS-DATA mo_viewer TYPE REF TO cl_gui_html_viewer.
ENDCLASS.

CLASS cl_abap_browser IMPLEMENTATION.
  METHOD show_xml.
    DATA lv_xml TYPE string.

    IF xml_xstring IS NOT INITIAL.
      lv_xml = cl_abap_codepage=>convert_from( source = xml_xstring ).
    ELSE.
      lv_xml = xml_string.
    ENDIF.
    show_html(
      html_string = |<pre>{ cl_gui_control=>escape_html( lv_xml ) }</pre>|
      title       = title
      container   = container
      dialog      = dialog
      printing    = printing ).
  ENDMETHOD.

  METHOD show_html.
    DATA lt_html TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lo_container TYPE REF TO cl_gui_container.

    mv_html = html_string.
    mv_title = title.
    lo_container = container.
    IF lo_container IS NOT BOUND.
      lo_container = cl_gui_container=>default_screen.
    ENDIF.
    IF lo_container IS NOT BOUND.
      RETURN.
    ENDIF.

    IF mo_viewer IS BOUND AND mo_viewer->parent <> lo_container.
      mo_viewer->free( ).
      FREE mo_viewer.
    ENDIF.
    IF mo_viewer IS NOT BOUND.
      CREATE OBJECT mo_viewer
        EXPORTING
          parent = lo_container.
    ENDIF.
    mo_viewer->close_document( ).
    APPEND mv_html TO lt_html.
    mo_viewer->load_data( CHANGING data_table = lt_html ).
  ENDMETHOD.

  METHOD get_last_html.
    html_string = mv_html.
  ENDMETHOD.

  METHOD get_last_title.
    title = mv_title.
  ENDMETHOD.
ENDCLASS.
