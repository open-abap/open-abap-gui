CLASS ltcl_dd_document_support DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS renders_document_content FOR TESTING.
ENDCLASS.

CLASS ltcl_dd_document_support IMPLEMENTATION.
  METHOD renders_document_content.
    DATA lo_form TYPE REF TO cl_dd_form_area.
    DATA lo_input TYPE REF TO cl_dd_input_element.
    DATA lo_select TYPE REF TO cl_dd_select_element.
    DATA lo_button TYPE REF TO cl_dd_button_element.
    DATA lo_link TYPE REF TO cl_dd_link_element.
    DATA lv_url TYPE string.
    DATA lv_offline TYPE string.

    cl_gui_control=>clear( ).
    DATA(lo_document) = NEW cl_dd_document( background_color = 35 ).
    lo_document->add_text(
      text         = '<unsafe>'
      a11y_tooltip = 'Body text' ).
    lo_document->add_icon(
      sap_icon         = '@5B@'
      alternative_text = 'Success' ).
    lo_document->add_link(
      EXPORTING
        url     = '/details'
        text    = 'Details'
        name    = 'DETAILS'
        tooltip = 'Open details'
      IMPORTING
        link    = lo_link ).
    lo_document->add_form(
      IMPORTING
        formarea         = lo_form
        main_url         = lv_url
        alv_offline_info = lv_offline ).
    lo_form->add_input_element(
      EXPORTING
        value         = 'LH'
        name          = 'CARRIER'
        a11y_label    = 'Carrier'
      IMPORTING
        input_element = lo_input ).
    lo_form->add_select_element(
      EXPORTING
        name           = 'CLASS'
        value          = 'Y'
        options        = VALUE #( ( value = 'Y' text = 'Economy' )
                                  ( value = 'C' text = 'Business' ) )
        a11y_label     = 'Class'
      IMPORTING
        select_element = lo_select ).
    lo_form->add_button(
      EXPORTING
        name    = 'GO'
        label   = 'Go'
        tooltip = 'Submit form'
      IMPORTING
        button  = lo_button ).
    lo_document->display_document( ).

    cl_abap_unit_assert=>assert_bound( lo_link ).
    cl_abap_unit_assert=>assert_bound( lo_input ).
    cl_abap_unit_assert=>assert_bound( lo_select ).
    cl_abap_unit_assert=>assert_bound( lo_button ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lo_document->html_content CS '&lt;unsafe&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lo_document->html_content CS 'role="img"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lo_document->html_content CS 'name="CARRIER"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lo_document->html_content CS 'Economy' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( cl_gui_control=>has_content( ) ) ).
  ENDMETHOD.
ENDCLASS.
