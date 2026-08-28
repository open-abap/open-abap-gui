CLASS ltcl_ex_26 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_tabbed_screen FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_26 IMPLEMENTATION.

  METHOD builds_tabbed_screen.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_26( ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
  ENDMETHOD.

ENDCLASS.
