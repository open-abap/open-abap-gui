CLASS ltcl_ex_38 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS suppresses_batch_dialog FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_38 IMPLEMENTATION.

  METHOD suppresses_batch_dialog.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_038( )
      iv_batch  = abap_true ).

    cl_abap_unit_assert=>assert_true( ls_result-dialog_suppressed ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_A' ]-value
      exp = 'X' ).
  ENDMETHOD.

ENDCLASS.
