CLASS cl_abap_browser DEFINITION PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS show_xml
      IMPORTING
        xml_string TYPE string
        title      TYPE string OPTIONAL
        container  TYPE REF TO cl_gui_container OPTIONAL
        dialog     TYPE abap_bool OPTIONAL
        printing   TYPE abap_bool OPTIONAL.

    CLASS-METHODS show_html
      IMPORTING
        html_string TYPE string
        title       TYPE string OPTIONAL
        container   TYPE REF TO cl_gui_container OPTIONAL
        dialog      TYPE abap_bool OPTIONAL
        printing    TYPE abap_bool OPTIONAL.
ENDCLASS.

CLASS cl_abap_browser IMPLEMENTATION.
  METHOD show_xml.
    RETURN.
  ENDMETHOD.

  METHOD show_html.
    RETURN.
  ENDMETHOD.
ENDCLASS.
