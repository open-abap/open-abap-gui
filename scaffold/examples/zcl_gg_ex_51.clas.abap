CLASS zcl_gg_ex_51 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 51, CALL SELECTION-SCREEN. Counterpart of zgg_ex_51.prog.abap.
* The host drives the nested selection screen and resumable continuation.
* Self contained: no superclass, every callback present.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_resumable_v1.

  PRIVATE SECTION.
    DATA mv_p_b TYPE c LENGTH 1.

ENDCLASS.

CLASS zcl_gg_ex_51 IMPLEMENTATION.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->begin_screen( VALUE #( number = '0500' as_window = abap_true ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_B'
      text      = 'B'
      data_type = VALUE #( typ = 'C' length = 1 ) ) ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_dialog( )->call_selection_screen(
      is_call         = VALUE #(
        screen = '0500'
        modal  = VALUE #( start_row = 10 start_column = 5 ) )
      is_continuation = VALUE #( id = 'AFTER_0500' ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen.
    IF iv_screen = '0500'.
      mv_p_b = ct_values[ name = 'P_B' ]-value.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_resumable_v1~resume.
    CASE is_resume-continuation-id.
      WHEN 'AFTER_0500'.
        IF is_resume-subrc = 0.
          io_session->get_list( )->get_writer( )->write_field( VALUE #( text = mv_p_b ) ).
        ENDIF.
      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_report_v1~initialization.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~load_of_program.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_logical_database.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_list_processing.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_output.
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

  METHOD zif_gg_report_v1~end_of_selection.
    RETURN.
  ENDMETHOD.

ENDCLASS.
