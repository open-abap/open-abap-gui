CLASS ltcl_list_regressions DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS first_column_and_padding FOR TESTING.
    METHODS explicit_zero_decimals FOR TESTING.
    METHODS typed_dates_and_times FOR TESTING.
    METHODS format_preserves_options FOR TESTING.
    METHODS list_levels_are_checked FOR TESTING.
ENDCLASS.

CLASS ltcl_list_regressions IMPLEMENTATION.
  METHOD list_levels_are_checked.
    DATA(lo_list) = NEW zcl_gg_host_list( ).
    lo_list->begin_event( 1 ).
    TRY.
        lo_list->zif_gg_list_session_v1~set_level( 2 ).
        cl_abap_unit_assert=>fail( 'Accepted a level above the next list' ).
      CATCH zcx_gg_control_flow.
    ENDTRY.
    lo_list->end_event( ).
    TRY.
        lo_list->zif_gg_list_session_v1~set_level( 20 ).
        cl_abap_unit_assert=>fail( 'Accepted a level above the next list outside an event' ).
      CATCH zcx_gg_control_flow.
    ENDTRY.
    DO 20 TIMES.
      lo_list->begin_event( 1 ).
      lo_list->zif_gg_list_session_v1~get_writer( )->write_field( VALUE #( text = 'detail' ) ).
      lo_list->end_event( ).
    ENDDO.
    TRY.
        lo_list->begin_event( 1 ).
        cl_abap_unit_assert=>fail( 'Created list 21' ).
      CATCH zcx_gg_control_flow.
    ENDTRY.
  ENDMETHOD.

  METHOD first_column_and_padding.
    DATA(lo_list) = NEW zcl_gg_host_list( ).
    DATA(lo_writer) = lo_list->zif_gg_list_session_v1~get_writer( ).
    DATA lv_chars TYPE c LENGTH 4 VALUE 'I'.
    DATA(lv_text) = lo_writer->format_value( lv_chars ).
    cl_abap_unit_assert=>assert_equals( act = strlen( lv_text )
                                        exp = 4 ).
    lo_writer->write_field( VALUE #( text = 'I' ) ).
    lo_writer->write_field( VALUE #( text = 'EQ' ) ).
    lo_writer->new_line( ).
    lo_writer->write_field( VALUE #( text = 'I' ) ).
    lo_writer->write_field( VALUE #( text = 'EQ' ) ).
    DATA(lt_lines) = lo_list->finish_output( ).
    cl_abap_unit_assert=>assert_equals( act = lt_lines[ 1 ]
                                        exp = `I EQ` ).
    cl_abap_unit_assert=>assert_equals( act = lt_lines[ 2 ]
                                        exp = `I EQ` ).
  ENDMETHOD.

  METHOD explicit_zero_decimals.
    DATA(lo_list) = NEW zcl_gg_host_list( ).
    DATA(lo_writer) = lo_list->zif_gg_list_session_v1~get_writer( ).
    lo_writer->write_field( VALUE #( text = '12.34' write_format = VALUE #( decimals_set = abap_true decimals = 0 ) ) ).
    lo_writer->new_line( ).
    lo_writer->write_field( VALUE #( text = '12.34' ) ).
    DATA(lt_lines) = lo_list->finish_output( ).
    cl_abap_unit_assert=>assert_equals( act = lt_lines[ 1 ]
                                        exp = '12' ).
    cl_abap_unit_assert=>assert_equals( act = lt_lines[ 2 ]
                                        exp = '12.34' ).
  ENDMETHOD.

  METHOD typed_dates_and_times.
    DATA(lo_list) = NEW zcl_gg_host_list( ).
    DATA(lo_writer) = lo_list->zif_gg_list_session_v1~get_writer( ).
    DATA lv_date TYPE d VALUE '20260830'.
    DATA lv_time TYPE t VALUE '123456'.
    cl_abap_unit_assert=>assert_equals( act = lo_writer->format_value( lv_date )
                                        exp = |{ lv_date DATE = USER }| ).
    cl_abap_unit_assert=>assert_equals( act = lo_writer->format_value( iv_value = lv_date iv_date_mask = 'DD/MM/YYYY' )
                                        exp = '30/08/2026' ).
    cl_abap_unit_assert=>assert_equals( act = lo_writer->format_value( lv_time )
                                        exp = '12:34:56' ).
  ENDMETHOD.

  METHOD format_preserves_options.
    DATA(lo_list) = NEW zcl_gg_host_list( ).
    DATA(lo_writer) = lo_list->zif_gg_list_session_v1~get_writer( ).
    lo_writer->set_format( VALUE #( color = 1 ) ).
    lo_writer->set_format( VALUE #( BASE lo_writer->get_format( ) intensified = abap_true ) ).
    cl_abap_unit_assert=>assert_equals( act = lo_writer->get_format( )-color
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_true( lo_writer->get_format( )-intensified ).
    lo_writer->reset_format( ).
    cl_abap_unit_assert=>assert_initial( lo_writer->get_format( ) ).
  ENDMETHOD.
ENDCLASS.
