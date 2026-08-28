CLASS zcl_gg_ex_60 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 60, GET LATE. Counterpart of zgg_ex_60.prog.abap.
* Logical-database traversal remains blocked by gap #11.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.

ENDCLASS.

CLASS zcl_gg_ex_60 IMPLEMENTATION.

  METHOD zif_gg_report_v1~get_logical_database.
    rv_logical_database = 'F1S'.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_get.
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text      = to_lower( iv_node )
      placement = VALUE #( new_line = abap_true ) ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_get_late.
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text      = |{ to_lower( iv_node ) } late|
      placement = VALUE #( new_line = abap_true ) ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~load_of_program.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_list_processing.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
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

  METHOD zif_gg_report_v1~start_of_selection.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~end_of_selection.
    RETURN.
  ENDMETHOD.

ENDCLASS.
