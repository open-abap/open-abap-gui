CLASS cl_abap_browser DEFINITION PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS show_xml
      IMPORTING
        xml_string  TYPE string
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
ENDCLASS.

CLASS cl_abap_browser IMPLEMENTATION.
  METHOD show_xml.
    mv_html = xml_string.
    mv_title = title.
  ENDMETHOD.

  METHOD show_html.
    mv_html = html_string.
    mv_title = title.
  ENDMETHOD.

  METHOD get_last_html.
    html_string = mv_html.
  ENDMETHOD.

  METHOD get_last_title.
    title = mv_title.
  ENDMETHOD.
ENDCLASS.
