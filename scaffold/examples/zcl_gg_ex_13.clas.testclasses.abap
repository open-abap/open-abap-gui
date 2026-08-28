CLASS ltcl_ex_13 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS continues_same_list FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_13 IMPLEMENTATION.

  METHOD continues_same_list.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_13( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `select` )
        ( `done` ) ) ).
  ENDMETHOD.

ENDCLASS.
