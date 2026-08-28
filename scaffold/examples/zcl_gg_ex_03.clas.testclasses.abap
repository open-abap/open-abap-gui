CLASS ltcl_ex_03 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS lays_out_list_commands FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_03 IMPLEMENTATION.

  METHOD lays_out_list_commands.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_03( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `first` )
        ( `` )
        ( `` )
        ( `--------------------` )
        ( `    second` ) ) ).
  ENDMETHOD.

ENDCLASS.
