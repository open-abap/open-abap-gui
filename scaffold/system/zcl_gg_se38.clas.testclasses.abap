CLASS ltcl_gg_se38 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS metadata FOR TESTING.
    METHODS displays_escaped_source FOR TESTING.
    METHODS displays_chosen_subobject FOR TESTING.
    METHODS offers_no_variant_subobject FOR TESTING.
    METHODS keeps_subobject_after_error FOR TESTING.
    METHODS rejects_missing_program FOR TESTING.
    METHODS rejects_unauthorized_program FOR TESTING.
    METHODS rejects_inactive_execution FOR TESTING.
    METHODS rejects_include_execution FOR TESTING.
    METHODS displays_inactive_program FOR TESTING.
    METHODS executes_report_runtime FOR TESTING.
    METHODS offers_program_value_help FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_se38 IMPLEMENTATION.

  METHOD metadata.
    DATA(ls_transaction) = NEW zcl_gg_se38( )->zif_gg_transaction_v1~get_transaction( ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-tcode
                                        exp = 'SE38' ).
  ENDMETHOD.

  METHOD displays_escaped_source.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se38( )
      iv_ucomm   = 'DISPLAY'
      it_values  = VALUE #( ( name = 'P_PROGRAM' value = 'ZGG_EX_015' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0200' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'REPORT zgg_ex_015.' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'line numbers' ) ).
  ENDMETHOD.

  METHOD displays_chosen_subobject.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se38( )
      iv_ucomm   = 'DISPLAY'
      it_values  = VALUE #( ( name = 'P_PROGRAM' value = 'ZGG_EX_015' )
                            ( name = 'R_ATTRIBUTES' value = 'X' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0210' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_ATTR_TYPE' ]-value
                                        exp = 'Executable program' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'R_SOURCE' ]-value
                                        exp = `` ).
  ENDMETHOD.

  METHOD offers_no_variant_subobject.
    DATA(ls_result) = zcl_gg_host_dynpro=>run( io_program   = NEW zcl_gg_se38( )
                                               iv_submitted = abap_false ).
    cl_abap_unit_assert=>assert_false( act = line_exists( ls_result-controls[ name = 'R_VARIANTS' ] ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( ls_result-html CS 'Variant' ) ).
  ENDMETHOD.

  METHOD keeps_subobject_after_error.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se38( )
      iv_ucomm   = 'DISPLAY'
      it_values  = VALUE #( ( name = 'P_PROGRAM' value = 'ZUNKNOWN' )
                            ( name = 'R_DOCUMENTATION' value = 'X' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0100' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'P_PROGRAM' ]-value
                                        exp = 'ZUNKNOWN' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'R_DOCUMENTATION' ]-value
                                        exp = 'X' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'R_SOURCE' ]-value
                                        exp = `` ).
  ENDMETHOD.

  METHOD rejects_missing_program.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se38( )
      iv_ucomm   = 'DISPLAY'
      it_values  = VALUE #( ( name = 'P_PROGRAM' value = 'ZUNKNOWN' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0100' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-messages[ 1 ]-text
                                        exp = 'Program does not exist in the repository.' ).
  ENDMETHOD.

  METHOD rejects_unauthorized_program.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se38( )
      iv_ucomm   = 'DISPLAY'
      it_values  = VALUE #( ( name = 'P_PROGRAM' value = 'ZGG_LOCKED' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0100' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-messages[ 1 ]-text
                                        exp = 'You are not authorized to display this program.' ).
  ENDMETHOD.

  METHOD displays_inactive_program.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se38( )
      iv_ucomm   = 'DISPLAY'
      it_values  = VALUE #( ( name = 'P_PROGRAM' value = 'ZGG_DRAFT' )
                            ( name = 'R_ATTRIBUTES' value = 'X' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0210' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-values[ name = 'O_ATTR_STATUS' ]-value
                                        exp = 'INACTIVE' ).
  ENDMETHOD.

  METHOD rejects_inactive_execution.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se38( )
      iv_ucomm   = 'EXECUTE'
      it_values  = VALUE #( ( name = 'P_PROGRAM' value = 'ZGG_DRAFT' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0100' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'Program ZGG_DRAFT is inactive; activate it before execution.' ).
  ENDMETHOD.

  METHOD rejects_include_execution.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program = NEW zcl_gg_se38( )
      iv_ucomm   = 'EXECUTE'
      it_values  = VALUE #( ( name = 'P_PROGRAM' value = 'ZGG_EX_015_INC' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-screen
                                        exp = '0100' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'Program ZGG_EX_015_INC is a Include program and cannot be executed.' ).
  ENDMETHOD.

  METHOD offers_program_value_help.
    DATA(ls_result) = zcl_gg_host_dynpro=>run(
      io_program       = NEW zcl_gg_se38( )
      iv_submitted     = abap_false
      iv_value_request = 'P_PROGRAM' ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-help_values )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_false( act = line_exists( ls_result-help_values[ value = 'ZGG_LOCKED' ] ) ).
  ENDMETHOD.

  METHOD executes_report_runtime.
    zcl_gg_host_runtime=>clear( ).
    DATA(ls_start) = zcl_gg_host_runtime=>start( io_dynpro_program = NEW zcl_gg_se38( ) ).
    DATA(ls_result) = zcl_gg_host_runtime=>dispatch( VALUE #(
      session_id    = ls_start-session_id
      page_id       = ls_start-page_id
      action        = zif_gg_host_html_v1=>action_submit
      ucomm         = 'EXECUTE'
      dynpro_values = VALUE #( ( name = 'P_PROGRAM' value = 'ZGG_EX_015' ) ) ) ).
    cl_abap_unit_assert=>assert_true( act = ls_result-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-page_kind
                                        exp = zif_gg_host_html_v1=>page_selection ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

ENDCLASS.
