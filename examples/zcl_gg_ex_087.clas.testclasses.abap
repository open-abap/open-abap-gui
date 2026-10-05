CLASS ltcl_ex_87 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS formats_fragments FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_87 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_087( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_087' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD formats_fragments.
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_087( ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-render_lines[ 1 ]-fragments )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_true( act = ls_result-render_lines[ 1 ]-fragments[ 1 ]-format-intensified ).
    cl_abap_unit_assert=>assert_true( act = ls_result-render_lines[ 1 ]-fragments[ 2 ]-format-hotspot ).
    cl_abap_unit_assert=>assert_true( act = ls_result-render_lines[ 1 ]-fragments[ 3 ]-format-inverse ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-render_lines[ 1 ]-fragments[ 1 ]-format-quickinfo
                                        exp = 'Heading & <safe>' ).
  ENDMETHOD.

ENDCLASS.
