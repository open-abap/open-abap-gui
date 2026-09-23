CLASS ltcl_ex_36 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS returns_field_help FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_36 IMPLEMENTATION.

  METHOD returns_field_help.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report    = NEW zcl_gg_ex_036( )
      iv_help_name = 'P_CARR' ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-help_text
      exp = 'Two character IATA code' ).
  ENDMETHOD.

ENDCLASS.
