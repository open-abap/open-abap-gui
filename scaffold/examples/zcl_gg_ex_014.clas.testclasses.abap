CLASS ltcl_ex_14 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS stops_before_following_write FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_14 IMPLEMENTATION.

  METHOD stops_before_following_write.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_014( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `before` )
        ( `end` ) ) ).
  ENDMETHOD.

ENDCLASS.
