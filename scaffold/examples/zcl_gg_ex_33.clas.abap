CLASS zcl_gg_ex_33 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 33, AT SELECTION-SCREEN ON BLOCK. Counterpart of
* zgg_ex_33.prog.abap. The host does not drive selection-screen events yet.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.

ENDCLASS.

CLASS zcl_gg_ex_33 IMPLEMENTATION.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->begin_block( VALUE #(
      name       = 'B1'
      with_frame = abap_true ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_A'
      text      = 'A'
      data_type = VALUE #( typ = 'C' length = 1 ) ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_B'
      text      = 'B'
      data_type = VALUE #( typ = 'C' length = 1 ) ) ).
    io_builder->end_block( ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_block.
    IF iv_block = 'B1'
        AND ct_values[ name = 'P_A' ]-value IS INITIAL
        AND ct_values[ name = 'P_B' ]-value IS INITIAL.
      io_session->message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = 'fill one of the two' ) ).
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

  METHOD zif_gg_report_v1~initialization.
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

  METHOD zif_gg_report_v1~start_of_selection.
    RETURN.
  ENDMETHOD.

ENDCLASS.
