CLASS zcl_gg_host_compatibility DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_compatibility_v1.

ENDCLASS.

CLASS zcl_gg_host_compatibility IMPLEMENTATION.

  METHOD zif_gg_compatibility_v1~popup_to_confirm.
    rv_answer = is_request-default_button.
    IF rv_answer IS INITIAL.
      rv_answer = '1'.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~popup_to_inform.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~popup_get_values.
    CLEAR rv_returncode.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~popup_with_table_display.
    CLEAR rv_choice.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~popup_to_select_month.
    CLEAR cv_return_code.
    cv_selected_month = is_request-actual_month.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~f4_table_value_request.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~set_selection_list_values.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~alpha_input.
    rv_output = iv_input.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~alpha_output.
    rv_output = iv_input.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~alv_fieldcatalog_merge.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~alv_display.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~alv_display_hierseq.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~alv_block_init.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~alv_block_append.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~alv_block_display.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~alv_popup_to_select.
    CLEAR cv_exit.
    CLEAR cs_selfield.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~alv_events_get.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~alv_variant_f4.
    CLEAR cv_exit.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~alv_commentary_write.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~select_options_restrict.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~free_selections_init.
    IF cv_selection_id IS INITIAL.
      cv_selection_id = 'GGSEL'.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~free_selections_dialog.
    CLEAR cv_active_fields.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~free_selections_range_to_where.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~variant_refresh.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~variant_catalog.
    CLEAR rv_variant.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~variant_contents.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~variant_create.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~variant_change.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~variant_delete.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~xstring_to_binary.
    CLEAR cv_output_length.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~create_url.
    cv_url = |gg-data:{ is_request-type }/{ is_request-subtype }|.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~publish_url.
    rv_url = |gg-published:{ iv_object }|.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~supports.
    rv_supported = abap_false.
    CASE to_upper( iv_family ).
      WHEN 'POPUP' OR 'DIALOG' OR 'ALV' OR 'DYNAMIC_SELECTION' OR 'F4'
          OR 'VARIANT' OR 'LIST_NAVIGATION' OR 'FRONTEND'.
        rv_supported = abap_true.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
