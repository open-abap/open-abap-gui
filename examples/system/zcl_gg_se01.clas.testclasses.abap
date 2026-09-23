CLASS ltcl_gg_se01 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS metadata FOR TESTING.
    METHODS has_five_selection_tabs FOR TESTING.
    METHODS keeps_mutation_disabled FOR TESTING.
    METHODS switches_to_the_tab_screen FOR TESTING.
    METHODS keeps_criteria_per_tab FOR TESTING.
    METHODS displays_standard_request FOR TESTING.
    METHODS displays_any_known_number FOR TESTING.
    METHODS rejects_wrong_convention FOR TESTING.
    METHODS rejects_cross_type_request FOR TESTING.
    METHODS rejects_malformed_number FOR TESTING.
    METHODS opens_logs_from_individual FOR TESTING.
    METHODS rejects_action_log FOR TESTING.
    METHODS returns_to_the_active_tab FOR TESTING.
    METHODS offers_value_help_per_tab FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_se01 IMPLEMENTATION.

  METHOD metadata.
    DATA(ls_transaction) = NEW zcl_gg_se01( )->zif_gg_transaction_v1~get_transaction( ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-tcode
                                        exp = 'SE01' ).
  ENDMETHOD.

  METHOD has_five_selection_tabs.
    DATA(ls_result) = zcl_gg_host_dynpro=>run( io_program   = NEW zcl_gg_se01( )
                                               iv_submitted = abap_false ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '>Display</button>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '>Transports</button>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '>Piece Lists</button>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '>Deliveries</button>' ) ).
    cl_abap_unit_assert=>assert_true( act = line_exists( ls_result-controls[ screen = '0110' name = 'P_STD_REQUEST' ] ) ).
    cl_abap_unit_assert=>assert_true( act = line_exists( ls_result-controls[ screen = '0130' name = 'P_CLI_TARGET' ] ) ).
  ENDMETHOD.

  METHOD keeps_mutation_disabled.
    DATA(ls_result) = zcl_gg_host_dynpro=>run( io_program   = NEW zcl_gg_se01( )
                                               iv_submitted = abap_false ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-status-active_ucomm[ table_line = 'CREATE' ] ) ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-values[ name = 'P_CAPABILITY' ]-value CS 'CTS persistence' ) ).
    cl_abap_unit_assert=>assert_false( act = ls_result-states[ name = 'PB_RELEASE' ]-enabled ).
    cl_abap_unit_assert=>assert_false( act = ls_result-states[ name = 'PB_EXPORT' ]-enabled ).
  ENDMETHOD.

  METHOD switches_to_the_tab_screen.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se01( )
      iv_ucomm   = 'PIECE' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0120' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'K9nnnnn convention' ) ).
  ENDMETHOD.

  METHOD keeps_criteria_per_tab.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se01( )
      iv_ucomm   = 'CLIENT'
      it_values  = VALUE #( ( name = 'P_REQUEST' value = 'DEVK900001' )
                            ( name = 'P_STD_REQUEST' value = 'DEVK900099' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0130' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'P_REQUEST' ]-value
                                        exp = 'DEVK900001' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'P_STD_REQUEST' ]-value
                                        exp = 'DEVK900099' ).
  ENDMETHOD.

  METHOD displays_standard_request.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se01( )
      iv_screen  = '0110'
      iv_ucomm   = 'DISPLAY'
      it_values  = VALUE #( ( name = 'P_STD_REQUEST' value = 'DEVK900001' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0200' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_REQ_ID' ]-value
                                        exp = 'DEVK900001' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ container = 'TC_TASKS' name = 'TASK_TEXT' row = 1 ]-value
                                        exp = 'Dictionary inspection task' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_ROUTE' ]-value
                                        exp = 'DEV -> QAS' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'P_ACTIVE_TAB' ]-value
                                        exp = 'STANDARD' ).
  ENDMETHOD.

  METHOD displays_any_known_number.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se01( )
      iv_ucomm   = 'DISPLAY'
      it_values  = VALUE #( ( name = 'P_REQUEST' value = 'DEVKD00001' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0200' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_REQ_TYPE' ]-value
                                        exp = 'Delivery transport' ).
  ENDMETHOD.

  METHOD rejects_wrong_convention.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se01( )
      iv_screen  = '0130'
      iv_ucomm   = 'DISPLAY'
      it_values  = VALUE #( ( name = 'P_CLI_REQUEST' value = 'DEVK900001' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0130' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'Request DEVK900001 does not follow the <SID>KOnnnnn convention for client transports.' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'P_CLI_REQUEST' ]-value
                                        exp = 'DEVK900001' ).
  ENDMETHOD.

  METHOD rejects_cross_type_request.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se01( )
      iv_screen  = '0110'
      iv_ucomm   = 'DISPLAY'
      it_values  = VALUE #( ( name = 'P_STD_REQUEST' value = 'DEVK900010' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0110' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'Request DEVK900010 is a Piece list and cannot be displayed on the standard requests tab.' ).
  ENDMETHOD.

  METHOD rejects_malformed_number.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se01( )
      iv_ucomm   = 'DISPLAY'
      it_values  = VALUE #( ( name = 'P_REQUEST' value = 'DEV1' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0100' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'Request DEV1 is not a ten-character transport request number.' ).
  ENDMETHOD.

  METHOD opens_logs_from_individual.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se01( )
      iv_ucomm   = 'LOGS'
      it_values  = VALUE #( ( name = 'P_REQUEST' value = 'DEVK900001' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0240' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ container = 'TC_LOGS' name = 'LOG_SEVERITY' row = 1 ]-value
                                        exp = 'INFO' ).
  ENDMETHOD.

  METHOD rejects_action_log.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se01( )
      iv_ucomm   = 'ACTION_LOG' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0100' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'The action log needs a real CTS backend; this deployment cannot show it.' ).
  ENDMETHOD.

  METHOD offers_value_help_per_tab.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program       = NEW zcl_gg_se01( )
      iv_screen        = '0120'
      iv_submitted     = abap_false
      iv_value_request = 'P_PCE_REQUEST' ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-help_values )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-help_values[ 1 ]-value
                                        exp = 'DEVK900010' ).
  ENDMETHOD.

  METHOD returns_to_the_active_tab.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se01( )
      iv_screen  = '0200'
      iv_ucomm   = 'BACK'
      it_values  = VALUE #( ( name = 'P_ACTIVE_TAB' value = 'CLIENT' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0130' ).
  ENDMETHOD.

ENDCLASS.
