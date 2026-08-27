CLASS lcl_report DEFINITION FINAL CREATE PUBLIC.

* One self contained report, switched by mode, standing in for the example
* classes until phase 1 of examples/PLAN.md creates them. It implements the
* interfaces directly and spells out every method, the shape the plan requires.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_list_processing_v1.

    METHODS constructor
      IMPORTING
        iv_mode TYPE string.

  PRIVATE SECTION.
    DATA mv_mode TYPE string.

    METHODS writer
      IMPORTING
        io_session       TYPE REF TO zif_gg_session_v1
      RETURNING
        VALUE(ro_writer) TYPE REF TO zif_gg_list_writer_v1.

ENDCLASS.

CLASS lcl_report IMPLEMENTATION.

  METHOD constructor.
    mv_mode = iv_mode.
  ENDMETHOD.

  METHOD writer.
    ro_writer = io_session->get_list( )->get_writer( ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    DATA(lo_writer) = writer( io_session ).

    CASE mv_mode.
      WHEN 'HELLO'.
        lo_writer->write_field( VALUE #( text = 'hello world' ) ).

      WHEN 'PLACE'.
        lo_writer->write_field( VALUE #(
          text      = 'abcdefgh'
          placement = VALUE #( position = 10 length = 5 ) ) ).
        lo_writer->write_field( VALUE #(
          text      = 'x'
          placement = VALUE #( no_gap = abap_true ) ) ).
        lo_writer->write_field( VALUE #( text = 'y' ) ).

      WHEN 'SKIP'.
        lo_writer->write_field( VALUE #( text = 'first' ) ).
        lo_writer->skip( 2 ).
        lo_writer->uline( VALUE #( position = 1 length = 20 ) ).
        lo_writer->new_line( ).
        lo_writer->write_field( VALUE #( text = 'second' ) ).

      WHEN 'STOP'.
        lo_writer->write_field( VALUE #( text = 'before' ) ).
        io_session->stop( ).
        lo_writer->write_field( VALUE #( text = 'unreachable' ) ).

      WHEN 'PAGE'.
        lo_writer->write_field( VALUE #( text = 'body' ) ).

      WHEN 'DEFAULT'.
        lo_writer->write_field( VALUE #( text = it_values[ name = 'P_CARR' ]-value ) ).

      WHEN 'MESSAGE'.
        io_session->message( VALUE #(
          type = zif_gg_session_types_v1=>message_type_error
          text = 'bad input' ) ).

      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_report_v1~end_of_selection.
    IF mv_mode = 'STOP'.
      writer( io_session )->write_field( VALUE #(
        text      = 'end'
        placement = VALUE #( new_line = abap_true ) ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_list_processing.
    IF mv_mode = 'PAGE'.
      ro_list_processing = me.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    IF mv_mode = 'DEFAULT'.
      io_builder->add_parameter( VALUE #(
        name      = 'P_CARR'
        text      = 'Carrier'
        data_type = VALUE #( typ = 'C' length = 3 )
        default   = 'LH' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~initialization.
    IF mv_mode = 'DEFAULT'.
      ct_values[ name = 'P_CARR' ]-value = 'AA'.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~top_of_page.
    writer( io_session )->write_field( VALUE #( text = 'header' ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~load_of_program.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_logical_database.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_output.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_field.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_end_of.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_block.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_radio.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_value_req.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_help_req.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_exit.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_get.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_get_late.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~get_settings.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~end_of_page.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~top_of_page_during_line_sel.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_line_selection.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_user_command.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_pf.
    RETURN.
  ENDMETHOD.

ENDCLASS.


CLASS ltcl_host DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS write_literal FOR TESTING.
    METHODS placement_and_gap FOR TESTING.
    METHODS skip_and_uline FOR TESTING.
    METHODS stop_reaches_end FOR TESTING.
    METHODS top_of_page_first FOR TESTING.
    METHODS default_then_initialization FOR TESTING.
    METHODS error_message_recorded FOR TESTING.

ENDCLASS.

CLASS ltcl_host IMPLEMENTATION.

  METHOD write_literal.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'HELLO' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `hello world` ) ) ).
  ENDMETHOD.

  METHOD placement_and_gap.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'PLACE' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `         abcde xy` ) ) ).
  ENDMETHOD.

  METHOD skip_and_uline.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'SKIP' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `first` )
        ( `` )
        ( `` )
        ( `--------------------` )
        ( `second` ) ) ).
  ENDMETHOD.

  METHOD stop_reaches_end.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'STOP' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `before` )
        ( `end` ) ) ).
  ENDMETHOD.

  METHOD top_of_page_first.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'PAGE' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines(
        ( `header` )
        ( `body` ) ) ).
  ENDMETHOD.

  METHOD default_then_initialization.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'DEFAULT' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = ls_result-lines
      exp = VALUE zcl_gg_host_list=>ty_text_lines( ( `AA` ) ) ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-values[ name = 'P_CARR' ]-value
      exp = 'AA' ).
  ENDMETHOD.

  METHOD error_message_recorded.
    DATA(ls_result) = zcl_gg_host=>run( NEW lcl_report( 'MESSAGE' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( ls_result-messages )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-messages[ 1 ]-text
      exp = 'bad input' ).
    cl_abap_unit_assert=>assert_initial( ls_result-lines ).
  ENDMETHOD.

ENDCLASS.
