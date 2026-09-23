CLASS ltcl_ex_159 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS publishes_and_renders FOR TESTING.
ENDCLASS.

CLASS ltcl_ex_159 IMPLEMENTATION.
  METHOD publishes_and_renders.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_159( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_159( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-tcode
                                        exp = 'ZGG_EX_159' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( ls_result-html CS 'Nine month calendar' ) ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_result-status-active_ucomm ).
  ENDMETHOD.
ENDCLASS.
