CLASS zcl_gg_ex_069 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 69, a checkbox-controlled field group with retained server state.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_transaction_v1.
  PRIVATE SECTION.
    DATA mv_group_a TYPE string.
    DATA mv_group_b TYPE string.
ENDCLASS.

CLASS zcl_gg_ex_069 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #(
      tcode = 'ZGG_EX_069'
      description = 'Checkbox-controlled field group' ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    io_builder->add_checkbox( VALUE #(
      name    = 'P_ENABLE'
      text    = 'Enable group'
      default = abap_true ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_GROUP_A'
      text      = 'Group A'
      data_type = VALUE #( typ = 'C' length = 20 ) ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_GROUP_B'
      text      = 'Group B'
      data_type = VALUE #( typ = 'C' length = 20 ) ) ).
    io_builder->add_parameter( VALUE #(
      name      = 'P_REQUIRED'
      text      = 'Required value'
      data_type = VALUE #( typ = 'C' length = 20 )
      obligatory = abap_true ) ).
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_output.
    DATA(lv_enabled) = xsdbool( ct_values[ name = 'P_ENABLE' ]-value = 'X' ).
    ct_states[ name = 'P_GROUP_A' ]-enabled = lv_enabled.
    ct_states[ name = 'P_GROUP_B' ]-enabled = lv_enabled.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen.
    DATA lv_error TYPE abap_bool.

    IF ct_values[ name = 'P_ENABLE' ]-value = 'X'.
      mv_group_a = ct_values[ name = 'P_GROUP_A' ]-value.
      mv_group_b = ct_values[ name = 'P_GROUP_B' ]-value.
    ELSE.
      IF ct_values[ name = 'P_GROUP_A' ]-value IS NOT INITIAL
          AND ct_values[ name = 'P_GROUP_A' ]-value <> mv_group_a.
        lv_error = abap_true.
      ENDIF.
      IF ct_values[ name = 'P_GROUP_B' ]-value IS NOT INITIAL
          AND ct_values[ name = 'P_GROUP_B' ]-value <> mv_group_b.
        lv_error = abap_true.
      ENDIF.
      ct_values[ name = 'P_GROUP_A' ]-value = mv_group_a.
      ct_values[ name = 'P_GROUP_B' ]-value = mv_group_b.
      IF lv_error = abap_true.
        io_session->message( VALUE #(
          type = zif_gg_session_types_v1=>message_type_error
          text = 'Disabled Group A cannot be submitted' ) ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    io_session->get_list( )->set_title( 'ZCL_GG_EX_069' ).
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text = it_values[ name = 'P_GROUP_A' ]-value ) ).
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text = it_values[ name = 'P_GROUP_B' ]-value
      placement = VALUE #( new_line = abap_true ) ) ).
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
