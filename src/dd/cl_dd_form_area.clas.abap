CLASS cl_dd_form_area DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS add_button
      IMPORTING
        label    TYPE string OPTIONAL
        sap_icon TYPE any OPTIONAL
        tooltip  TYPE string OPTIONAL
        name     TYPE any OPTIONAL
        sub_area TYPE REF TO cl_dd_area OPTIONAL
        tabindex TYPE i OPTIONAL
        hotkey   TYPE any OPTIONAL
      EXPORTING
        button   TYPE REF TO cl_dd_button_element.
ENDCLASS.

CLASS cl_dd_form_area IMPLEMENTATION.

  METHOD add_button.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.