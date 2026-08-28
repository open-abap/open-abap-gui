CLASS ltcl_ex_50 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS runs_list_processing FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_50 IMPLEMENTATION.

  METHOD runs_list_processing.
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_ex_50( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `inside the list processor` ) ) ).
  ENDMETHOD.

ENDCLASS.
