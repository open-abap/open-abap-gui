CLASS ltcl_gg_compatibility_popup DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS table_popup_returns_choice FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_compatibility_popup IMPLEMENTATION.

  METHOD table_popup_returns_choice.
    DATA lt_values TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    DATA lv_choice TYPE i.
    DATA lx_popup TYPE REF TO zcx_gg_control_flow.
    DATA lo_compatibility TYPE REF TO zif_gg_compatibility_v1.
    lo_compatibility ?= NEW zcl_gg_host_compatibility( ).

    APPEND 'First row' TO lt_values.
    APPEND 'Second row' TO lt_values.
    lo_compatibility->set_popup_request(
      iv_action = ''
      it_values = VALUE #( ) ).
    TRY.
        lv_choice = lo_compatibility->popup_with_table_display(
          EXPORTING
            is_request = VALUE #( title = 'Choose a row' )
          CHANGING
            ct_values  = lt_values ).
        cl_abap_unit_assert=>fail( 'The table popup must suspend on first display' ).
      CATCH zcx_gg_control_flow INTO lx_popup.
        cl_abap_unit_assert=>assert_equals(
          act = lx_popup->mv_operation
          exp = 'POPUP WITH TABLE DISPLAY' ).
    ENDTRY.

    DATA(ls_popup) = lo_compatibility->get_popup( ).
    cl_abap_unit_assert=>assert_equals( act = ls_popup-kind
                                        exp = 'TABLE' ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_popup-table_values )
                                        exp = 2 ).
    lo_compatibility->set_popup_request(
      iv_action = 'TABLE:2'
      it_values = VALUE #( ) ).
    lv_choice = lo_compatibility->popup_with_table_display(
      EXPORTING
        is_request = VALUE #( title = 'Choose a row' )
      CHANGING
        ct_values  = lt_values ).
    cl_abap_unit_assert=>assert_equals( act = lv_choice
                                        exp = 2 ).
  ENDMETHOD.

ENDCLASS.
