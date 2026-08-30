CLASS zcl_gg_ex_55 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 55, SUBMIT EXPORTING LIST TO MEMORY. Counterpart of
* zgg_ex_55.prog.abap. The host submits a supplied report and retains its list.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.
    INTERFACES zif_gg_resumable_v1.

ENDCLASS.

CLASS zcl_gg_ex_55 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_55' description = 'SUBMIT EXPORTING LIST TO MEMORY' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_list( )->set_title( 'ZCL_GG_EX_55' ).
    io_session->get_navigation( )->submit_and_return(
      is_submit       = VALUE #(
        program        = 'ZGG_EX_01'
        list_to_memory = abap_true )
      is_continuation = VALUE #( id = 'AFTER_SUBMIT' ) ).
  ENDMETHOD.

  METHOD zif_gg_resumable_v1~resume.
    IF is_resume-continuation-id = 'AFTER_SUBMIT'.
      DATA(lt_lines) = io_session->get_navigation( )->get_list_from_memory( ).
      LOOP AT lt_lines INTO DATA(lv_line).
        io_session->get_list( )->get_writer( )->write_field( VALUE #(
          text      = lv_line
          placement = VALUE #( new_line = abap_true ) ) ).
      ENDLOOP.
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
