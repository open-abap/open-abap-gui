CLASS ltcl_list_processor DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS fixture_lines
      RETURNING
        VALUE(rt_lines) TYPE zcl_gg_host_list=>ty_render_lines.
    METHODS find_asks_for_the_term FOR TESTING.
    METHODS find_and_find_next FOR TESTING.
    METHODS find_next_without_term FOR TESTING.
    METHODS search_wraps FOR TESTING.
    METHODS search_options_and_hits FOR TESTING.
    METHODS richtext_escapes_markup FOR TESTING.
    METHODS richtext_encodes_unicode FOR TESTING.
    METHODS save_asks_for_the_format FOR TESTING.
    METHODS save_as_spreadsheet FOR TESTING.
    METHODS paging_is_a_function FOR TESTING.

ENDCLASS.

CLASS ltcl_list_processor IMPLEMENTATION.
  METHOD search_options_and_hits.
    DATA(ls_case) = zcl_gg_host_list_processor=>process( iv_ucomm = '%SC'
                                                         iv_value = 'Frankfurt'
      iv_target                                                   = 'CASE'
                                                         it_lines = fixture_lines( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_case-found
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_case-hits )
                                        exp = 1 ).
    DATA(ls_cursor) = zcl_gg_host_list_processor=>process( iv_ucomm  = '%SC'
                                                           iv_value  = 'Frankfurt'
      iv_target                                                      = 'CURSOR'
                                                           iv_cursor = 2
                                                           it_lines  = fixture_lines( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_cursor-found
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_cursor-hits )
                                        exp = 2 ).
  ENDMETHOD.

  METHOD richtext_escapes_markup.
    DATA(ls_outcome) = zcl_gg_host_list_processor=>process( iv_ucomm = '%PC'
                                                            iv_value = 'RICHTEXT'
      it_lines                                                       = VALUE #( ( index = 1 text = 'a{b}\c' ) ) ).
    cl_abap_unit_assert=>assert_equals( act = cl_abap_codepage=>convert_from( ls_outcome-downloads[ 1 ]-content )
      exp                                   = '{\rtf1\ansi\uc1 a\{b\}\\c\par }' ).
  ENDMETHOD.

  METHOD richtext_encodes_unicode.
    DATA(lv_text) = cl_abap_codepage=>convert_from( CONV xstring( 'C3A9' ) ).
    DATA(ls_outcome) = zcl_gg_host_list_processor=>process( iv_ucomm = '%PC'
      iv_value                                                       = 'RICHTEXT'
                                                            it_lines = VALUE #( ( index = 1 text = lv_text ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = cl_abap_codepage=>convert_from( ls_outcome-downloads[ 1 ]-content )
      exp = '{\rtf1\ansi\uc1 \u233?\par }' ).
  ENDMETHOD.

  METHOD fixture_lines.
    rt_lines = VALUE #(
      ( index = 1 fragments = VALUE #( ( text = `LH` position = 1 ) ( text = `Frankfurt` position = 5 ) ) )
      ( index = 2 fragments = VALUE #( ( text = `UA` position = 1 ) ( text = `Chicago` position = 5 ) ) )
      ( index = 3 fragments = VALUE #( ( text = `LH` position = 1 ) ( text = `FRANKFURT` position = 5 ) ) ) ).
  ENDMETHOD.

  METHOD find_asks_for_the_term.
    DATA(ls_outcome) = zcl_gg_host_list_processor=>process(
      iv_ucomm = zcl_gg_host_list_processor=>find
      it_lines = fixture_lines( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_outcome-dialog
                                        exp = zcl_gg_host_list_processor=>dialog_find ).
  ENDMETHOD.

  METHOD find_and_find_next.
* As on SAP, Find ignores case and Find next goes on after the last hit.
    DATA(ls_first) = zcl_gg_host_list_processor=>process(
      iv_ucomm = zcl_gg_host_list_processor=>find
      iv_value = `frankfurt`
      it_lines = fixture_lines( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_first-found
                                        exp = 1 ).
    DATA(ls_next) = zcl_gg_host_list_processor=>process(
      iv_ucomm = zcl_gg_host_list_processor=>find_next
      is_find  = ls_first-find
      it_lines = fixture_lines( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_next-found
                                        exp = 3 ).
  ENDMETHOD.

  METHOD find_next_without_term.
    DATA(ls_outcome) = zcl_gg_host_list_processor=>process(
      iv_ucomm = zcl_gg_host_list_processor=>find_next
      it_lines = fixture_lines( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_outcome-dialog
                                        exp = zcl_gg_host_list_processor=>dialog_find ).
  ENDMETHOD.

  METHOD search_wraps.
    DATA(ls_outcome) = zcl_gg_host_list_processor=>process(
      iv_ucomm = zcl_gg_host_list_processor=>find_next
      is_find  = VALUE #( term = `chicago` line = 2 )
      it_lines = fixture_lines( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_outcome-found
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = ls_outcome-message
                                        exp = `` ).
    cl_abap_unit_assert=>assert_equals( act = ls_outcome-find-line
                                        exp = 2 ).
  ENDMETHOD.

  METHOD save_asks_for_the_format.
    DATA(ls_outcome) = zcl_gg_host_list_processor=>process(
      iv_ucomm = zcl_gg_host_list_processor=>save_file
      it_lines = fixture_lines( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_outcome-dialog
                                        exp = zcl_gg_host_list_processor=>dialog_save ).
    cl_abap_unit_assert=>assert_initial( ls_outcome-downloads ).
  ENDMETHOD.

  METHOD save_as_spreadsheet.
    DATA(ls_outcome) = zcl_gg_host_list_processor=>process(
      iv_ucomm  = zcl_gg_host_list_processor=>save_file
      iv_value  = zcl_gg_host_list_processor=>format_spreadsheet
      iv_target = `flights.xls`
      it_lines  = fixture_lines( ) ).
    cl_abap_unit_assert=>assert_equals( act = ls_outcome-downloads[ 1 ]-filename
                                        exp = `flights.xls` ).
    cl_abap_unit_assert=>assert_equals(
      act = cl_abap_codepage=>convert_from( ls_outcome-downloads[ 1 ]-content )
      exp = |LH\tFrankfurt\r\nUA\tChicago\r\nLH\tFRANKFURT\r\n| ).
  ENDMETHOD.

  METHOD paging_is_a_function.
    cl_abap_unit_assert=>assert_true( zcl_gg_host_list_processor=>is_function( 'P+' ) ).
    cl_abap_unit_assert=>assert_true( zcl_gg_host_list_processor=>is_function( 'PRI' ) ).
    cl_abap_unit_assert=>assert_false( zcl_gg_host_list_processor=>is_function( 'BACK' ) ).
    cl_abap_unit_assert=>assert_false( zcl_gg_host_list_processor=>is_function( 'TOTAL' ) ).
  ENDMETHOD.

ENDCLASS.
