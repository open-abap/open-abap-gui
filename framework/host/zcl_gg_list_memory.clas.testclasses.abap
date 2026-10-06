CLASS ltcl_memory DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS opaque_memory_roundtrip FOR TESTING.
    METHODS string_table_roundtrip FOR TESTING.
ENDCLASS.

CLASS ltcl_memory IMPLEMENTATION.
  METHOD opaque_memory_roundtrip.
    DATA lt_memory TYPE STANDARD TABLE OF abaplist WITH DEFAULT KEY.
    DATA lt_ascii TYPE string_table.
    DATA(lt_lines) = VALUE string_table( ( `A  B  ` ) ( repeat( val = `x`
                                                                occ = 1500 ) )
      ( cl_abap_codepage=>convert_from( CONV xstring( 'C3A9' ) ) ) ).
    zcl_gg_list_memory=>from_lines( EXPORTING it_lines = lt_lines CHANGING ct_list = lt_memory ).
    cl_abap_unit_assert=>assert_true( xsdbool( lines( lt_memory ) > 1 ) ).
    zcl_gg_list_memory=>to_ascii( EXPORTING it_list = lt_memory CHANGING ct_ascii = lt_ascii ).
    cl_abap_unit_assert=>assert_equals( act = lt_ascii
                                        exp = lt_lines ).
  ENDMETHOD.

  METHOD string_table_roundtrip.
    DATA lt_memory TYPE string_table.
    DATA lt_ascii TYPE string_table.
    DATA(lt_lines) = VALUE string_table( ( `one` ) ( `two` ) ).
    zcl_gg_list_memory=>from_lines( EXPORTING it_lines = lt_lines CHANGING ct_list = lt_memory ).
    zcl_gg_list_memory=>to_ascii( EXPORTING it_list = lt_memory CHANGING ct_ascii = lt_ascii ).
    cl_abap_unit_assert=>assert_equals( act = lt_ascii
                                        exp = lt_lines ).
  ENDMETHOD.
ENDCLASS.
