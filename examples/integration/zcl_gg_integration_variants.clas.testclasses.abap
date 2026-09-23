CLASS ltcl_gg_integration_var DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS saves_values FOR TESTING.
    METHODS loads_values_before_run FOR TESTING.
    METHODS overwrites_values FOR TESTING.
    METHODS deletes_values FOR TESTING.
    METHODS reports_missing_variant FOR TESTING.
    METHODS repeats_without_leak FOR TESTING.
    METHODS isolates_memory_list FOR TESTING.
    METHODS restores_memory_level FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_integration_var IMPLEMENTATION.

  METHOD saves_values.
    zcl_gg_host_variant=>clear( ).
    zcl_gg_host=>run(
      io_report = NEW zcl_gg_integration_variants( 'SAVE' )
      it_input  = VALUE #(
        ( name = 'P_CARR' value = 'LH' )
        ( name = 'P_DATE' value = '20260228' ) ) ).

    DATA(lt_values) = zcl_gg_host_variant=>load( 'FLIGHT_VARIANT' ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_values[ name = 'P_CARR' ]-value
      exp = 'LH' ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_values[ name = 'P_DATE' ]-value
      exp = '20260228' ).
  ENDMETHOD.

  METHOD loads_values_before_run.
    zcl_gg_host_variant=>clear( ).
    zcl_gg_host_variant=>save(
      iv_name   = 'FLIGHT_VARIANT'
      it_values = VALUE #(
        ( name = 'P_CARR' value = 'LH' )
        ( name = 'P_DATE' value = '20260228' ) ) ).

    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_variants( 'LOAD' ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `Loaded LH/20260228` ) ) ).
  ENDMETHOD.

  METHOD overwrites_values.
    zcl_gg_host_variant=>clear( ).
    zcl_gg_host_variant=>save(
      iv_name   = 'FLIGHT_VARIANT'
      it_values = VALUE #( ( name = 'P_CARR' value = 'AA' ) ) ).
    zcl_gg_host_variant=>save(
      iv_name   = 'FLIGHT_VARIANT'
      it_values = VALUE #( ( name = 'P_CARR' value = 'SQ' ) ) ).

    DATA(lt_values) = zcl_gg_host_variant=>load( 'FLIGHT_VARIANT' ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_values[ name = 'P_CARR' ]-value
      exp = 'SQ' ).
  ENDMETHOD.

  METHOD deletes_values.
    zcl_gg_host_variant=>clear( ).
    zcl_gg_host_variant=>save(
      iv_name   = 'FLIGHT_VARIANT'
      it_values = VALUE #( ( name = 'P_CARR' value = 'AA' ) ) ).
    zcl_gg_host_variant=>delete( 'FLIGHT_VARIANT' ).

    cl_abap_unit_assert=>assert_initial( zcl_gg_host_variant=>load( 'FLIGHT_VARIANT' ) ).
  ENDMETHOD.

  METHOD reports_missing_variant.
    zcl_gg_host_variant=>clear( ).
    DATA(ls_result) = zcl_gg_host=>run( NEW zcl_gg_integration_variants( 'LOAD' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `Variant missing` ) ) ).
  ENDMETHOD.

  METHOD repeats_without_leak.
    zcl_gg_host_variant=>clear( ).
    zcl_gg_host_variant=>save(
      iv_name   = 'FLIGHT_VARIANT'
      it_values = VALUE #( ( name = 'P_CARR' value = 'LH' ) ) ).
    DATA(ls_loaded) = zcl_gg_host=>run( NEW zcl_gg_integration_variants( 'LOAD' ) ).
    DATA(ls_plain) = zcl_gg_host=>run( NEW zcl_gg_integration_variants( 'PLAIN' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_loaded-lines[ 1 ]
      exp = `Loaded LH/20260101` ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_plain-lines[ 1 ]
      exp = `Plain AA/20260101` ).
  ENDMETHOD.

  METHOD isolates_memory_list.
    DATA(ls_first) = zcl_gg_host=>run(
      io_report        = NEW zcl_gg_integration_variants( 'MEMORY' )
      io_submit_report = NEW zcl_gg_ex_001( ) ).
    DATA(ls_second) = zcl_gg_host=>run(
      io_report        = NEW zcl_gg_integration_variants( 'MEMORY' )
      io_submit_report = NEW zcl_gg_ex_001( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_first-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `Memory level: 1` )
        ( `Memory: hello world` )
        ( `Restored memory level: 0` ) ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_first-lines
                                        exp = ls_second-lines ).
  ENDMETHOD.

  METHOD restores_memory_level.
    DATA(ls_result) = zcl_gg_host=>run(
      io_report        = NEW zcl_gg_integration_variants( 'MEMORY' )
      io_submit_report = NEW zcl_gg_ex_001( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines[ 3 ]
      exp = `Restored memory level: 0` ).
  ENDMETHOD.

ENDCLASS.
