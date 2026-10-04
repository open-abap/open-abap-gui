CLASS ltcl_ex_83 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS drills_down FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_83 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_083( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_083' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD drills_down.
    DATA(ls_detail) = zcl_gg_host=>run( io_report     = NEW zcl_gg_ex_083( )
                                        iv_line_index = 1 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( line_exists( ls_detail-lines[ table_line = 'Detail list' ] ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_detail-render_lines[ 2 ]-fields[ name = 'GV_NODE' ]-value
                                        exp = 'SUBDETAIL' ).
  ENDMETHOD.

ENDCLASS.
