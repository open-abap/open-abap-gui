CLASS ltcl_dd_document_support DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS renders_document_content FOR TESTING.
    METHODS renders_styled_split_table FOR TESTING.
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
    DATA lv_document_html TYPE string.

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
    LOOP AT lo_document->html_table INTO DATA(ls_line).
      lv_document_html = lv_document_html && ls_line-line.
    ENDLOOP.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_document_html CS '&lt;unsafe&gt;' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_document_html CS 'role="img"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_document_html CS 'name="CARRIER"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_document_html CS 'Economy' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( cl_gui_control=>has_content( ) ) ).
  ENDMETHOD.

  METHOD renders_styled_split_table.
    DATA lo_right_area TYPE REF TO cl_dd_area.
    DATA lo_form TYPE REF TO cl_dd_form_area.
    DATA lo_table TYPE REF TO cl_dd_table_element.
    DATA lo_table_area TYPE REF TO cl_dd_table_area.
    DATA lv_html TYPE string.
    DATA lv_heading_count TYPE i.

    cl_gui_control=>clear( ).
    DATA(lo_document) = NEW cl_dd_document( ).
    lo_document->vertical_split(
      EXPORTING
        split_area  = lo_document
        split_width = '72%'
      IMPORTING
        right_area  = lo_right_area ).
    lo_document->add_text(
      text         = 'SAP GUI Dynamic Documents'
      sap_style    = 'HEADING'
      sap_emphasis = 'STRONG' ).
    lo_document->underline( ).
    lo_right_area->add_text( text = 'Document area' ).
    lo_right_area->new_line( ).
    lo_right_area->add_text( text = 'User TEST' ).
    lo_document->add_icon( sap_icon = 'ICON_DISPLAY' ).
    lo_document->add_table(
      EXPORTING
        no_of_columns = 3
        with_heading  = abap_true
      IMPORTING
        table         = lo_table
        tablearea     = lo_table_area ).
    lo_table_area->add_heading( 'Control' ).
    lo_table_area->add_heading( 'Purpose' ).
    lo_table_area->add_heading( 'State' ).
    lo_table_area->add_text( text = 'Text' ).
    lo_table_area->add_text( text = 'Formatted content' ).
    lo_table_area->add_text( text = 'Ready' ).
    lo_table_area->new_row( sap_color = 'LIST_POSITIVE' ).
    lo_table_area->add_text( text = 'Form' ).
    lo_table_area->add_text( text = 'Interactive elements' ).
    lo_table_area->add_icon( sap_icon = 'ICON_OKAY' ).
    lo_table_area->new_row( ).
    lo_document->add_form( IMPORTING formarea = lo_form ).
    lo_form->add_text( text = 'Interactive form area:' ).
    lo_document->merge_document( ).
    LOOP AT lo_document->html_table INTO DATA(ls_line).
      lv_html = lv_html && ls_line-line.
    ENDLOOP.
    FIND ALL OCCURRENCES OF '<th' IN lv_html MATCH COUNT lv_heading_count.
    FIND FIRST OCCURRENCE OF '</table><form' IN lv_html MATCH OFFSET DATA(lv_form_offset).
    FIND FIRST OCCURRENCE OF 'Interactive form area:' IN lv_html MATCH OFFSET DATA(lv_form_text_offset).

    cl_abap_unit_assert=>assert_equals(
      exp = 6
      act = lv_heading_count ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'grid-template-columns:minmax(0,72fr) minmax(0,28fr)' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<aside class="gg-dd-right-area">' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-sap-style="HEADING"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-sap-color="LIST_POSITIVE"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-icon="ICON_OKAY"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'href="#wb-icon-circle-check"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_form_offset < lv_form_text_offset ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-dd-underline' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '<u>' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'Dynamic document table' ) ).
  ENDMETHOD.
ENDCLASS.
