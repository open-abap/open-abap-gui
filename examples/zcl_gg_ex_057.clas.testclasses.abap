CLASS ltcl_ex_57 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS leaves_to_transaction FOR TESTING.
    METHODS leaves_program FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_57 IMPLEMENTATION.

  METHOD leaves_to_transaction.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report = NEW zcl_gg_ex_057( )
      it_input  = VALUE #( ( name = 'P_GO' value = 'X' ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-terminal
      exp = 'LEAVE TO TRANSACTION SE38' ).
  ENDMETHOD.

  METHOD leaves_program.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_057( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-terminal
      exp = 'LEAVE PROGRAM' ).
  ENDMETHOD.

ENDCLASS.
