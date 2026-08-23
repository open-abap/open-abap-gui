CLASS cl_dd_form_area DEFINITION PUBLIC INHERITING FROM cl_dd_area.
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

    METHODS add_input_element
      IMPORTING
        value         TYPE any OPTIONAL
        name          TYPE any OPTIONAL
        size          TYPE i OPTIONAL
        maxlength     TYPE i OPTIONAL
        sub_area      TYPE REF TO cl_dd_area OPTIONAL
        tooltip       TYPE string OPTIONAL
        tabindex      TYPE i OPTIONAL
        hotkey        TYPE any OPTIONAL
        a11y_label    TYPE string OPTIONAL
      EXPORTING
        input_element TYPE REF TO cl_dd_input_element.

    METHODS add_select_element
      IMPORTING
        name           TYPE sdydo_element_name OPTIONAL
        value          TYPE sdydo_value OPTIONAL
        options        TYPE sdydo_option_tab OPTIONAL
        sub_area       TYPE REF TO cl_dd_area OPTIONAL
        tooltip        TYPE string OPTIONAL
        tabindex       TYPE i OPTIONAL
        hotkey         TYPE sdydo_c1 OPTIONAL
        a11y_label     TYPE string OPTIONAL
      EXPORTING
        select_element TYPE REF TO cl_dd_select_element.
ENDCLASS.

CLASS cl_dd_form_area IMPLEMENTATION.
  METHOD add_input_element.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_select_element.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_button.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.