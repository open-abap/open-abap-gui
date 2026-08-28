CLASS ltcl_ex_24 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS builds_pushbutton FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_24 IMPLEMENTATION.

  METHOD builds_pushbutton.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_24( ) ).

    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
  ENDMETHOD.

ENDCLASS.
