CLASS zcl_gg_ex_27 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 27, selection-screen BEGIN OF SCREEN. Counterpart of
* zgg_ex_27.prog.abap. The host records named-screen metadata for inspection.
* Self contained: no superclass, every callback present.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.

ENDCLASS.

CLASS zcl_gg_ex_27 IMPLEMENTATION.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->begin_screen( VALUE #( number = '0500' as_window = abap_true ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_B'
      text      = 'B'
      data_type = VALUE #( typ = 'C' length = 1 ) ) ).
    io_builder->end_screen( ).
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

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_list( )->set_title( 'ZCL_GG_EX_27' ).
    RETURN.
  ENDMETHOD.

ENDCLASS.
