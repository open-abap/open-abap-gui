CLASS ltcl_ex_55 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS returns_submitted_list FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_55 IMPLEMENTATION.

  METHOD returns_submitted_list.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report         = NEW zcl_gg_ex_055( )
      io_submit_report  = NEW zcl_gg_ex_001( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `hello world` ) ) ).
  ENDMETHOD.

ENDCLASS.
