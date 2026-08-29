CLASS zcl_gg_ex_54 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 54, SUBMIT AND RETURN with WITH and variant. Counterpart of
* zgg_ex_54.prog.abap. The host forwards selections and retains the variant.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_resumable_v1.

ENDCLASS.

CLASS zcl_gg_ex_54 IMPLEMENTATION.

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_list( )->set_title( 'ZCL_GG_EX_54' ).
    io_session->get_navigation( )->submit_and_return(
      is_submit       = VALUE #(
        program = 'ZGG_EX_20'
        variant = 'STANDARD'
        values  = VALUE #( ( name   = 'S_CARR'
                             ranges = VALUE #( (
                               sign   = zif_gg_selection_screen_types=>sign_include
                               option = zif_gg_selection_screen_types=>option_eq
                               low    = 'LH' ) ) ) ) )
      is_continuation = VALUE #( id = 'AFTER_SUBMIT' ) ).
  ENDMETHOD.

  METHOD zif_gg_resumable_v1~resume.
    IF is_resume-continuation-id = 'AFTER_SUBMIT'.
      io_session->get_list( )->get_writer( )->write_field( VALUE #( text = 'back' ) ).
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
