CLASS zcl_gg_ex_29 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 29, AT SELECTION-SCREEN OUTPUT writing a parameter. Counterpart of
* zgg_ex_29.prog.abap. The host drives the output event before the run.
* Self contained: no superclass, every callback present.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.

ENDCLASS.

CLASS zcl_gg_ex_29 IMPLEMENTATION.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->add_parameter( VALUE #(
      name      = 'P_CNT'
      text      = 'Count'
      data_type = VALUE #( typ = 'I' ) ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_output.
    ct_values[ name = 'P_CNT' ]-value =
      |{ ct_values[ name = 'P_CNT' ]-value + 1 }|.
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
    io_session->get_list( )->set_title( 'ZCL_GG_EX_29' ).
    RETURN.
  ENDMETHOD.

ENDCLASS.
