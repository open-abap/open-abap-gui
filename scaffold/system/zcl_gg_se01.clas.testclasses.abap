CLASS ltcl_gg_se01 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS metadata FOR TESTING.
    METHODS has_five_selection_tabs FOR TESTING.
    METHODS keeps_mutation_disabled FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_se01 IMPLEMENTATION.

  METHOD metadata.
    DATA(ls_transaction) = NEW zcl_gg_se01( )->zif_gg_transaction_v1~get_transaction( ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-tcode exp = 'SE01' ).
  ENDMETHOD.

  METHOD has_five_selection_tabs.
    DATA(ls_result) = zcl_gg_host_dynpro=>run( io_program = NEW zcl_gg_se01( ) iv_submitted = abap_false ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '>Display</button>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '>Transports</button>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '>Piece Lists</button>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS '>Deliveries</button>' ) ).
  ENDMETHOD.

  METHOD keeps_mutation_disabled.
    DATA(ls_result) = zcl_gg_host_dynpro=>run( io_program = NEW zcl_gg_se01( ) iv_submitted = abap_false ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_result-status-active_ucomm[ table_line = 'CREATE' ] ) ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-values[ name = 'P_CAPABILITY' ]-value CS 'CTS persistence' ) ).
  ENDMETHOD.

ENDCLASS.
