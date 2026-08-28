CLASS ltcl_ex_37 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS leaves_on_cancel FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_37 IMPLEMENTATION.

  METHOD leaves_on_cancel.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report    = NEW zcl_gg_ex_37( )
      iv_exit_ucomm = 'ECAN' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-terminal
      exp = 'LEAVE PROGRAM' ).
    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
  ENDMETHOD.

ENDCLASS.
