CLASS zcl_gg_integration_variants DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_resumable_v1.

    METHODS constructor
      IMPORTING
        iv_mode TYPE string DEFAULT 'PLAIN'.

  PRIVATE SECTION.
    DATA mv_mode TYPE string.

ENDCLASS.

CLASS zcl_gg_integration_variants IMPLEMENTATION.

  METHOD constructor.
    mv_mode = iv_mode.
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->add_parameter( VALUE #(
      name = 'P_CARR'
      text = 'Carrier'
      default = 'AA'
      data_type = VALUE #( typ = 'C' length = 3 ) ) ).
    io_builder->add_parameter( VALUE #(
      name = 'P_DATE'
      text = 'Date'
      default = '20260101'
      data_type = VALUE #( typ = 'D' length = 8 ) ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~initialization.
    IF mv_mode = 'LOAD'.
      DATA(lt_loaded) = zcl_gg_host_variant=>load( 'FLIGHT_VARIANT' ).
      LOOP AT lt_loaded INTO DATA(ls_loaded).
        IF line_exists( ct_values[ name = ls_loaded-name ] ).
          ct_values[ name = ls_loaded-name ] = ls_loaded.
        ENDIF.
      ENDLOOP.
      IF lt_loaded IS INITIAL.
        ct_values[ name = 'P_CARR' ]-value = ``.
        ct_values[ name = 'P_DATE' ]-value = ``.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    DATA(lo_writer) = io_session->get_list( )->get_writer( ).
    DATA(lv_carrid) = it_values[ name = 'P_CARR' ]-value.
    DATA(lv_date) = it_values[ name = 'P_DATE' ]-value.

    CASE mv_mode.
      WHEN 'MEMORY'.
        io_session->get_navigation( )->submit_and_return(
          is_submit = VALUE #(
            program = 'ZGG_EX_001'
            list_to_memory = abap_true )
          is_continuation = VALUE #( id = 'AFTER_MEMORY' ) ).
      WHEN 'SAVE' OR 'OVERWRITE'.
        zcl_gg_host_variant=>save(
          iv_name = 'FLIGHT_VARIANT'
          it_values = it_values ).
        lo_writer->write_field( VALUE #( text = |Saved { lv_carrid }/{ lv_date }| ) ).
      WHEN 'DELETE'.
        zcl_gg_host_variant=>delete( 'FLIGHT_VARIANT' ).
        lo_writer->write_field( VALUE #( text = 'Variant deleted' ) ).
      WHEN 'LOAD'.
        IF lv_carrid IS INITIAL.
          lo_writer->write_field( VALUE #( text = 'Variant missing' ) ).
        ELSE.
          lo_writer->write_field( VALUE #( text = |Loaded { lv_carrid }/{ lv_date }| ) ).
        ENDIF.
      WHEN 'PLAIN'.
        lo_writer->write_field( VALUE #( text = |Plain { lv_carrid }/{ lv_date }| ) ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_resumable_v1~resume.
    IF is_resume-continuation-id = 'AFTER_MEMORY'.
      DATA(lo_list) = io_session->get_list( ).
      DATA(lt_lines) = io_session->get_navigation( )->get_list_from_memory( ).
      lo_list->enter_list_processing( ).
      DATA(ls_context) = lo_list->get_context( ).
      lo_list->get_writer( )->write_field( VALUE #(
        text = |Memory level: { ls_context-level }|
        placement = VALUE #( new_line = abap_true ) ) ).
      LOOP AT lt_lines INTO DATA(lv_line).
        lo_list->get_writer( )->write_field( VALUE #(
          text = |Memory: { lv_line }|
          placement = VALUE #( new_line = abap_true ) ) ).
      ENDLOOP.
      lo_list->leave_list_processing( ).
      ls_context = lo_list->get_context( ).
      lo_list->get_writer( )->write_field( VALUE #(
        text = |Restored memory level: { ls_context-level }|
        placement = VALUE #( new_line = abap_true ) ) ).
    ENDIF.
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

  METHOD zif_gg_report_v1~end_of_selection.
    RETURN.
  ENDMETHOD.

ENDCLASS.
