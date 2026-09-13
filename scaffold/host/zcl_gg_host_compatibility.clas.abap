CLASS zcl_gg_host_compatibility DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_compatibility_v1.

    TYPES: BEGIN OF ty_selection_list,
             id     TYPE string,
             values TYPE vrm_values,
           END OF ty_selection_list.
    TYPES ty_selection_lists TYPE STANDARD TABLE OF ty_selection_list WITH DEFAULT KEY.

    CLASS-METHODS clear_selection_list_values.
    CLASS-METHODS get_selection_list_values
      RETURNING VALUE(rt_lists) TYPE ty_selection_lists.

  PRIVATE SECTION.
    CLASS-DATA mt_selection_lists TYPE ty_selection_lists.
    DATA mv_context_report TYPE string.
    DATA mt_context_values TYPE zif_gg_selection_screen_types=>ty_values.
    DATA mt_context_states TYPE zif_gg_selection_screen_types=>ty_states.
    DATA mv_context_screen TYPE zif_gg_selection_screen_types=>ty_screen_number.
    DATA mv_dynamic_action TYPE string.
    DATA mt_dynamic_input TYPE zif_gg_selection_screen_types=>ty_values.
    DATA ms_dynamic_selection TYPE zif_gg_compatibility_v1=>ty_dynamic_selection.
    DATA mv_popup_action TYPE string.
    DATA mt_popup_input TYPE zif_gg_dynpro_types_v1=>ty_values.
    DATA ms_popup TYPE zif_gg_compatibility_v1=>ty_popup.
    DATA mt_value_help_values TYPE zif_gg_dynpro_types_v1=>ty_values.

    METHODS append_parameter
      IMPORTING
        iv_name   TYPE string
        iv_kind   TYPE string
        iv_sign   TYPE string
        iv_option TYPE string
        iv_low    TYPE string
        iv_high   TYPE string
      CHANGING
        ct_table  TYPE zif_gg_compatibility_v1=>ty_variant_parameters.

    METHODS values_to_table
      IMPORTING
        it_values TYPE zif_gg_selection_screen_types=>ty_values
      CHANGING
        ct_table  TYPE zif_gg_compatibility_v1=>ty_variant_parameters.

    METHODS table_to_values
      IMPORTING
        it_table         TYPE zif_gg_compatibility_v1=>ty_variant_parameters
      RETURNING
        VALUE(rt_values) TYPE zif_gg_selection_screen_types=>ty_values.

    METHODS capture_dynamic_fields
      IMPORTING it_fields TYPE STANDARD TABLE.

    METHODS load_dynamic_ranges
      IMPORTING it_ranges TYPE any.

    METHODS write_dynamic_ranges
      CHANGING ct_ranges TYPE any.

    METHODS write_dynamic_where
      CHANGING ct_where TYPE any.

    METHODS capture_popup_fields
      IMPORTING it_fields TYPE STANDARD TABLE.
ENDCLASS.

CLASS zcl_gg_host_compatibility IMPLEMENTATION.

  METHOD zif_gg_compatibility_v1~popup_to_confirm.
    DATA lv_action TYPE string.
    DATA lv_answer TYPE string.

    SPLIT mv_popup_action AT ':' INTO lv_action lv_answer.
    IF lv_action = 'CONFIRM'.
      rv_answer = CONV #( lv_answer ).
      sy-subrc = 0.
      RETURN.
    ENDIF.
    ms_popup = VALUE #(
      kind         = 'CONFIRM'
      title        = is_request-titlebar
      text_lines   = VALUE #( ( is_request-text_question ) )
      buttons      = VALUE #(
        ( value = '1' text = COND string( WHEN is_request-text_button_1 IS INITIAL THEN 'OK' ELSE is_request-text_button_1 ) )
        ( value = '2' text = COND string( WHEN is_request-text_button_2 IS INITIAL THEN 'Cancel' ELSE is_request-text_button_2 ) ) )
      start_column = is_request-start_column
      start_row    = is_request-start_row ).
    RAISE EXCEPTION NEW zcx_gg_control_flow(
      iv_kind      = zcx_gg_control_flow=>kind_popup
      iv_operation = 'POPUP TO CONFIRM' ).
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~popup_to_inform.
    DATA lv_action TYPE string.
    DATA lv_disposition TYPE string.

    SPLIT mv_popup_action AT ':' INTO lv_action lv_disposition.
    IF lv_action = 'INFORM'.
      RETURN.
    ENDIF.
    ms_popup = VALUE #(
      kind       = 'INFORM'
      title      = is_request-title
      text_lines = VALUE #( ( is_request-text1 ) ( is_request-text2 ) ( is_request-text3 ) ( is_request-text4 ) )
      buttons    = VALUE #( ( value = 'CLOSE' text = 'Close' ) ) ).
    DELETE ms_popup-text_lines WHERE table_line IS INITIAL.
    RAISE EXCEPTION NEW zcx_gg_control_flow(
      iv_kind      = zcx_gg_control_flow=>kind_popup
      iv_operation = 'POPUP TO INFORM' ).
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~popup_get_values.
    DATA lv_action TYPE string.
    DATA lv_disposition TYPE string.

    SPLIT mv_popup_action AT ':' INTO lv_action lv_disposition.
    IF lv_action = 'VALUE'.
      IF lv_disposition = 'CANCEL'.
        rv_returncode = '1'.
        sy-subrc = 1.
        RETURN.
      ENDIF.
      LOOP AT ct_fields ASSIGNING FIELD-SYMBOL(<ls_field>).
        DATA(lv_index) = sy-tabix.
        ASSIGN COMPONENT 'FIELDNAME' OF STRUCTURE <ls_field> TO FIELD-SYMBOL(<lv_field_name>).
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        READ TABLE mt_popup_input INTO DATA(ls_popup_value)
          WITH KEY name = CONV zif_gg_dynpro_types_v1=>ty_name( <lv_field_name> ).
        IF sy-subrc <> 0.
          READ TABLE mt_popup_input INTO ls_popup_value INDEX lv_index.
        ENDIF.
        IF sy-subrc = 0.
          ASSIGN COMPONENT 'VALUE' OF STRUCTURE <ls_field> TO FIELD-SYMBOL(<lv_value>).
          IF sy-subrc = 0.
            <lv_value> = ls_popup_value-value.
          ENDIF.
        ENDIF.
      ENDLOOP.
      CLEAR rv_returncode.
      sy-subrc = 0.
      RETURN.
    ENDIF.
    capture_popup_fields( it_fields = ct_fields ).
    ms_popup-kind = 'VALUES'.
    ms_popup-title = is_request-title.
    ms_popup-buttons = VALUE #( ( value = 'APPLY' text = 'Apply' ) ( value = 'CANCEL' text = 'Cancel' ) ).
    ms_popup-start_column = is_request-start_column.
    ms_popup-start_row = is_request-start_row.
    RAISE EXCEPTION NEW zcx_gg_control_flow(
      iv_kind      = zcx_gg_control_flow=>kind_popup
      iv_operation = 'POPUP GET VALUES' ).
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~popup_with_table_display.
    CLEAR rv_choice.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~popup_to_select_month.
    CLEAR cv_return_code.
    cv_selected_month = is_request-actual_month.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~f4_table_value_request.
    CLEAR mt_value_help_values.
    LOOP AT ct_value_tab ASSIGNING FIELD-SYMBOL(<lv_value>).
      DATA(lv_value) = ``.
      ASSIGN COMPONENT 'FIELDVAL' OF STRUCTURE <lv_value> TO FIELD-SYMBOL(<lv_fieldval>).
      IF sy-subrc = 0.
        lv_value = CONV string( <lv_fieldval> ).
      ELSE.
        lv_value = CONV string( <lv_value> ).
      ENDIF.
      IF lv_value IS NOT INITIAL.
        APPEND VALUE #(
          name  = CONV zif_gg_dynpro_types_v1=>ty_name( is_request-dynprofield )
          value = lv_value ) TO mt_value_help_values.
      ENDIF.
    ENDLOOP.
    sy-subrc = 0.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~set_popup_request.
    mv_popup_action = iv_action.
    mt_popup_input = it_values.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~get_popup.
    rs_popup = ms_popup.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~get_value_help_values.
    rt_values = mt_value_help_values.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~set_selection_list_values.
    READ TABLE mt_selection_lists ASSIGNING FIELD-SYMBOL(<ls_list>)
      WITH KEY id = iv_id.
    IF sy-subrc = 0.
      <ls_list>-values = it_values.
    ELSE.
      APPEND VALUE #( id = iv_id values = it_values ) TO mt_selection_lists.
    ENDIF.
  ENDMETHOD.

  METHOD clear_selection_list_values.
    CLEAR mt_selection_lists.
  ENDMETHOD.

  METHOD get_selection_list_values.
    rt_lists = mt_selection_lists.
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
    ms_dynamic_selection-selection_id = CONV string( cv_selection_id ).
    capture_dynamic_fields( ct_fields ).
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~free_selections_dialog.
    ms_dynamic_selection-open = abap_true.
    ms_dynamic_selection-as_window = is_request-as_window.
    ms_dynamic_selection-title = COND string(
      WHEN is_request-title IS INITIAL THEN 'Dynamic selections'
      ELSE is_request-title ).
    ms_dynamic_selection-selection_id = is_request-selection_id.
    capture_dynamic_fields( ct_fields ).
    load_dynamic_ranges( ct_field_ranges ).

    IF mv_dynamic_action = 'CANCEL'.
      ms_dynamic_selection-open = abap_false.
      sy-subrc = 2.
      RETURN.
    ENDIF.

    IF mv_dynamic_action = 'APPLY'.
      LOOP AT ms_dynamic_selection-fields ASSIGNING FIELD-SYMBOL(<ls_field>).
        READ TABLE mt_dynamic_input INTO DATA(ls_input)
          WITH KEY name = CONV zif_gg_selection_screen_types=>ty_name( <ls_field>-name ).
        <ls_field>-active = xsdbool(
          sy-subrc = 0 AND ( ls_input-value = 'X' OR ls_input-value = '1'
            OR ls_input-ranges IS NOT INITIAL ) ).
        CLEAR: <ls_field>-sign, <ls_field>-option,
               <ls_field>-low, <ls_field>-high.
        IF sy-subrc = 0 AND ls_input-ranges IS NOT INITIAL.
          READ TABLE ls_input-ranges INTO DATA(ls_range) INDEX 1.
          IF sy-subrc = 0.
            <ls_field>-sign = COND string( WHEN ls_range-sign IS INITIAL THEN 'I' ELSE ls_range-sign ).
            <ls_field>-option = COND string( WHEN ls_range-option IS INITIAL THEN 'EQ' ELSE ls_range-option ).
            <ls_field>-low = ls_range-low.
            <ls_field>-high = ls_range-high.
          ENDIF.
        ENDIF.
      ENDLOOP.
      write_dynamic_ranges( CHANGING ct_ranges = ct_field_ranges ).
      ms_dynamic_selection-open = abap_false.
      sy-subrc = 0.
      RETURN.
    ENDIF.

    cv_active_fields = ms_dynamic_selection-active_fields.
    sy-subrc = 0.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~free_selections_range_to_where.
    load_dynamic_ranges( it_field_ranges ).
    write_dynamic_where( CHANGING ct_where = ct_where_clauses ).
    sy-subrc = 0.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~set_dynamic_selection_request.
    mv_dynamic_action = iv_action.
    TRANSLATE mv_dynamic_action TO UPPER CASE.
    mt_dynamic_input = it_values.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~get_dynamic_selection.
    rs_selection = ms_dynamic_selection.
  ENDMETHOD.

  METHOD capture_dynamic_fields.
    CLEAR ms_dynamic_selection-fields.
    LOOP AT it_fields ASSIGNING FIELD-SYMBOL(<ls_input_field>).
      DATA(lv_table_name) = ``.
      DATA(lv_field_name) = ``.
      ASSIGN COMPONENT 'TABLENAME' OF STRUCTURE <ls_input_field> TO FIELD-SYMBOL(<lv_table_name>).
      IF sy-subrc = 0.
        lv_table_name = CONV string( <lv_table_name> ).
      ENDIF.
      ASSIGN COMPONENT 'FIELDNAME' OF STRUCTURE <ls_input_field> TO FIELD-SYMBOL(<lv_field_name>).
      IF sy-subrc = 0.
        lv_field_name = CONV string( <lv_field_name> ).
      ENDIF.
      IF lv_field_name IS INITIAL.
        CONTINUE.
      ENDIF.
      APPEND VALUE #(
        table_name = lv_table_name
        name       = lv_field_name
        text       = |{ lv_table_name }-{ lv_field_name }|
        sign       = 'I'
        option     = 'EQ' ) TO ms_dynamic_selection-fields.
    ENDLOOP.
    IF ms_dynamic_selection-fields IS INITIAL.
      APPEND VALUE #( table_name = 'T100' name = 'SPRAS' text = 'T100-SPRAS' sign = 'I' option = 'EQ' ) TO ms_dynamic_selection-fields.
      APPEND VALUE #( table_name = 'T100' name = 'ARBGB' text = 'T100-ARBGB' sign = 'I' option = 'EQ' ) TO ms_dynamic_selection-fields.
      APPEND VALUE #( table_name = 'T100' name = 'MSGNR' text = 'T100-MSGNR' sign = 'I' option = 'EQ' ) TO ms_dynamic_selection-fields.
    ENDIF.
  ENDMETHOD.

  METHOD capture_popup_fields.
    CLEAR ms_popup-fields.
    LOOP AT it_fields ASSIGNING FIELD-SYMBOL(<ls_field>).
      DATA(lv_name) = ``.
      DATA(lv_text) = ``.
      DATA(lv_value) = ``.
      ASSIGN COMPONENT 'FIELDNAME' OF STRUCTURE <ls_field> TO FIELD-SYMBOL(<lv_name>).
      IF sy-subrc = 0.
        lv_name = CONV string( <lv_name> ).
      ENDIF.
      ASSIGN COMPONENT 'FIELDTEXT' OF STRUCTURE <ls_field> TO FIELD-SYMBOL(<lv_text>).
      IF sy-subrc = 0.
        lv_text = CONV string( <lv_text> ).
      ENDIF.
      ASSIGN COMPONENT 'VALUE' OF STRUCTURE <ls_field> TO FIELD-SYMBOL(<lv_value>).
      IF sy-subrc = 0.
        lv_value = CONV string( <lv_value> ).
      ENDIF.
      APPEND VALUE #( name = lv_name text = lv_text value = lv_value ) TO ms_popup-fields.
    ENDLOOP.
  ENDMETHOD.

  METHOD load_dynamic_ranges.
    FIELD-SYMBOLS <lt_ranges> TYPE ANY TABLE.
    FIELD-SYMBOLS <ls_range_group> TYPE any.
    FIELD-SYMBOLS <lt_field_ranges> TYPE ANY TABLE.
    FIELD-SYMBOLS <ls_field_range> TYPE any.
    FIELD-SYMBOLS <lt_selopts> TYPE ANY TABLE.
    FIELD-SYMBOLS <ls_selopt> TYPE any.
    FIELD-SYMBOLS <ls_field> TYPE zif_gg_compatibility_v1=>ty_dynamic_selection_field.
    FIELD-SYMBOLS <lv_table_name> TYPE any.
    FIELD-SYMBOLS <lv_field_name> TYPE any.
    FIELD-SYMBOLS <lv_sign> TYPE any.
    FIELD-SYMBOLS <lv_option> TYPE any.
    FIELD-SYMBOLS <lv_low> TYPE any.
    FIELD-SYMBOLS <lv_high> TYPE any.
    ASSIGN it_ranges TO <lt_ranges>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    LOOP AT <lt_ranges> ASSIGNING <ls_range_group>.
      DATA(lv_table_name) = ``.
      ASSIGN COMPONENT 'TABLENAME' OF STRUCTURE <ls_range_group> TO <lv_table_name>.
      IF sy-subrc = 0.
        lv_table_name = CONV string( <lv_table_name> ).
      ENDIF.
      ASSIGN COMPONENT 'FRANGE_T' OF STRUCTURE <ls_range_group> TO <lt_field_ranges>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      LOOP AT <lt_field_ranges> ASSIGNING <ls_field_range>.
        DATA(lv_field_name) = ``.
        ASSIGN COMPONENT 'FIELDNAME' OF STRUCTURE <ls_field_range> TO <lv_field_name>.
        IF sy-subrc = 0.
          lv_field_name = CONV string( <lv_field_name> ).
        ENDIF.
        ASSIGN COMPONENT 'SELOPT_T' OF STRUCTURE <ls_field_range> TO <lt_selopts>.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        UNASSIGN <ls_selopt>.
        LOOP AT <lt_selopts> ASSIGNING <ls_selopt>.
          EXIT.
        ENDLOOP.
        IF <ls_selopt> IS NOT ASSIGNED.
          CONTINUE.
        ENDIF.
        READ TABLE ms_dynamic_selection-fields ASSIGNING <ls_field>
          WITH KEY table_name = lv_table_name name = lv_field_name.
        IF sy-subrc <> 0.
          APPEND VALUE #( table_name = lv_table_name name = lv_field_name text = |{ lv_table_name }-{ lv_field_name }| )
            TO ms_dynamic_selection-fields.
          READ TABLE ms_dynamic_selection-fields ASSIGNING <ls_field>
            WITH KEY table_name = lv_table_name name = lv_field_name.
        ENDIF.
        <ls_field>-active = abap_true.
        ASSIGN COMPONENT 'SIGN' OF STRUCTURE <ls_selopt> TO <lv_sign>.
        IF sy-subrc = 0.
          <ls_field>-sign = CONV string( <lv_sign> ).
        ENDIF.
        ASSIGN COMPONENT 'OPTION' OF STRUCTURE <ls_selopt> TO <lv_option>.
        IF sy-subrc = 0.
          <ls_field>-option = CONV string( <lv_option> ).
        ENDIF.
        ASSIGN COMPONENT 'LOW' OF STRUCTURE <ls_selopt> TO <lv_low>.
        IF sy-subrc = 0.
          <ls_field>-low = CONV string( <lv_low> ).
        ENDIF.
        ASSIGN COMPONENT 'HIGH' OF STRUCTURE <ls_selopt> TO <lv_high>.
        IF sy-subrc = 0.
          <ls_field>-high = CONV string( <lv_high> ).
        ENDIF.
      ENDLOOP.
    ENDLOOP.
    ms_dynamic_selection-active_fields = 0.
    LOOP AT ms_dynamic_selection-fields INTO DATA(ls_active_field) WHERE active = abap_true.
      ms_dynamic_selection-active_fields = ms_dynamic_selection-active_fields + 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD write_dynamic_ranges.
    FIELD-SYMBOLS <lt_ranges> TYPE ANY TABLE.
    FIELD-SYMBOLS <ls_group> TYPE any.
    FIELD-SYMBOLS <lt_franges> TYPE ANY TABLE.
    FIELD-SYMBOLS <ls_frange> TYPE any.
    FIELD-SYMBOLS <lt_options> TYPE ANY TABLE.
    FIELD-SYMBOLS <ls_option> TYPE any.
    FIELD-SYMBOLS <lv_group_table> TYPE any.
    FIELD-SYMBOLS <lv_frange_field> TYPE any.
    FIELD-SYMBOLS <lv_option_sign> TYPE any.
    FIELD-SYMBOLS <lv_option_option> TYPE any.
    FIELD-SYMBOLS <lv_option_low> TYPE any.
    FIELD-SYMBOLS <lv_option_high> TYPE any.
    ASSIGN ct_ranges TO <lt_ranges>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    CLEAR <lt_ranges>.
    LOOP AT ms_dynamic_selection-fields INTO DATA(ls_field) WHERE active = abap_true.
      APPEND INITIAL LINE TO <lt_ranges> ASSIGNING <ls_group>.
      ASSIGN COMPONENT 'TABLENAME' OF STRUCTURE <ls_group> TO <lv_group_table>.
      IF sy-subrc = 0.
        <lv_group_table> = ls_field-table_name.
      ENDIF.
      ASSIGN COMPONENT 'FRANGE_T' OF STRUCTURE <ls_group> TO <lt_franges>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      APPEND INITIAL LINE TO <lt_franges> ASSIGNING <ls_frange>.
      ASSIGN COMPONENT 'FIELDNAME' OF STRUCTURE <ls_frange> TO <lv_frange_field>.
      IF sy-subrc = 0.
        <lv_frange_field> = ls_field-name.
      ENDIF.
      ASSIGN COMPONENT 'SELOPT_T' OF STRUCTURE <ls_frange> TO <lt_options>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      APPEND INITIAL LINE TO <lt_options> ASSIGNING <ls_option>.
      ASSIGN COMPONENT 'SIGN' OF STRUCTURE <ls_option> TO <lv_option_sign>.
      IF sy-subrc = 0.
        <lv_option_sign> = COND string( WHEN ls_field-sign IS INITIAL THEN 'I' ELSE ls_field-sign ).
      ENDIF.
      ASSIGN COMPONENT 'OPTION' OF STRUCTURE <ls_option> TO <lv_option_option>.
      IF sy-subrc = 0.
        <lv_option_option> = COND string( WHEN ls_field-option IS INITIAL THEN 'EQ' ELSE ls_field-option ).
      ENDIF.
      ASSIGN COMPONENT 'LOW' OF STRUCTURE <ls_option> TO <lv_option_low>.
      IF sy-subrc = 0.
        <lv_option_low> = ls_field-low.
      ENDIF.
      ASSIGN COMPONENT 'HIGH' OF STRUCTURE <ls_option> TO <lv_option_high>.
      IF sy-subrc = 0.
        <lv_option_high> = ls_field-high.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD write_dynamic_where.
    FIELD-SYMBOLS <lt_where> TYPE ANY TABLE.
    FIELD-SYMBOLS <ls_where> TYPE any.
    FIELD-SYMBOLS <lt_where_lines> TYPE ANY TABLE.
    FIELD-SYMBOLS <ls_where_line> TYPE any.
    FIELD-SYMBOLS <lv_where_table> TYPE any.
    FIELD-SYMBOLS <lv_where_line> TYPE any.
    ASSIGN ct_where TO <lt_where>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    CLEAR <lt_where>.
    LOOP AT ms_dynamic_selection-fields INTO DATA(ls_field) WHERE active = abap_true.
      IF ls_field-low IS INITIAL AND ls_field-high IS INITIAL.
        CONTINUE.
      ENDIF.
      APPEND INITIAL LINE TO <lt_where> ASSIGNING <ls_where>.
      ASSIGN COMPONENT 'TABLENAME' OF STRUCTURE <ls_where> TO <lv_where_table>.
      IF sy-subrc = 0.
        <lv_where_table> = ls_field-table_name.
      ENDIF.
      ASSIGN COMPONENT 'WHERE_TAB' OF STRUCTURE <ls_where> TO <lt_where_lines>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      APPEND INITIAL LINE TO <lt_where_lines> ASSIGNING <ls_where_line>.
      ASSIGN COMPONENT 'LINE' OF STRUCTURE <ls_where_line> TO <lv_where_line>.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      DATA(lv_expression) = COND string(
        WHEN ls_field-high IS INITIAL
        THEN |{ ls_field-name } { COND string( WHEN ls_field-option = 'EQ' OR ls_field-option IS INITIAL THEN '=' ELSE ls_field-option ) } '{ ls_field-low }'|
        ELSE |{ ls_field-name } BETWEEN '{ ls_field-low }' AND '{ ls_field-high }'| ).
      IF ls_field-sign = 'E'.
        lv_expression = |NOT ( { lv_expression } )|.
      ENDIF.
      <lv_where_line> = lv_expression.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~set_selection_context.
    mv_context_report = iv_report.
    mt_context_values = it_values.
    mt_context_states = it_states.
    mv_context_screen = iv_screen.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~selection_table_to_values.
    rt_values = table_to_values( it_table = it_selection ).
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~variant_refresh.
    CLEAR ct_selection.
    IF mv_context_report IS INITIAL OR mt_context_values IS INITIAL.
      sy-subrc = 4.
      RETURN.
    ENDIF.
    values_to_table(
      EXPORTING
        it_values = mt_context_values
      CHANGING
        ct_table  = ct_selection ).
    sy-subrc = 0.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~variant_catalog.
    DATA(lv_report) = is_request-report.
    IF lv_report IS INITIAL.
      lv_report = mv_context_report.
    ENDIF.
    rv_variant = zcl_gg_host_variant=>first_name(
      iv_report = lv_report
      iv_owner  = 'GG_BROWSER' ).
    sy-subrc = COND #( WHEN rv_variant IS INITIAL THEN 4 ELSE 0 ).
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~variant_contents.
    DATA(lv_report) = is_request-report.
    IF lv_report IS INITIAL.
      lv_report = mv_context_report.
    ENDIF.
    DATA(ls_record) = zcl_gg_host_variant=>load_record(
      iv_name   = CONV zif_gg_session_types_v1=>ty_variant( is_request-variant )
      iv_report = lv_report
      iv_owner  = 'GG_BROWSER' ).
    IF ls_record-name IS INITIAL.
      CLEAR ct_contents.
      sy-subrc = 4.
      RETURN.
    ENDIF.
    values_to_table(
      EXPORTING
        it_values = ls_record-values
      CHANGING
        ct_table  = ct_contents ).
    sy-subrc = 0.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~variant_create.
    DATA(lv_report) = is_request-report.
    IF lv_report IS INITIAL.
      lv_report = mv_context_report.
    ENDIF.
    IF zcl_gg_host_variant=>exists(
        iv_name   = CONV zif_gg_session_types_v1=>ty_variant( is_request-variant )
        iv_report = lv_report
        iv_owner  = 'GG_BROWSER' ) = abap_true.
      sy-subrc = 7.
      RETURN.
    ENDIF.
    DATA(lt_values) = mt_context_values.
    IF lt_values IS INITIAL.
      lt_values = table_to_values( it_table = ct_contents ).
    ENDIF.
    zcl_gg_host_variant=>save(
      iv_name   = CONV zif_gg_session_types_v1=>ty_variant( is_request-variant )
      it_values = lt_values
      iv_report = lv_report
      iv_owner  = 'GG_BROWSER'
      it_states = mt_context_states
      iv_screen = mv_context_screen ).
    sy-subrc = 0.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~variant_change.
    DATA(lv_report) = is_request-report.
    IF lv_report IS INITIAL.
      lv_report = mv_context_report.
    ENDIF.
    IF zcl_gg_host_variant=>exists(
        iv_name   = CONV zif_gg_session_types_v1=>ty_variant( is_request-variant )
        iv_report = lv_report
        iv_owner  = 'GG_BROWSER' ) = abap_false.
      sy-subrc = 7.
      RETURN.
    ENDIF.
    DATA(lt_values) = mt_context_values.
    IF lt_values IS INITIAL.
      lt_values = table_to_values( it_table = ct_contents ).
    ENDIF.
    zcl_gg_host_variant=>save(
      iv_name   = CONV zif_gg_session_types_v1=>ty_variant( is_request-variant )
      it_values = lt_values
      iv_report = lv_report
      iv_owner  = 'GG_BROWSER'
      it_states = mt_context_states
      iv_screen = mv_context_screen ).
    sy-subrc = 0.
  ENDMETHOD.

  METHOD zif_gg_compatibility_v1~variant_delete.
    DATA(lv_report) = is_request-report.
    IF lv_report IS INITIAL.
      lv_report = mv_context_report.
    ENDIF.
    IF zcl_gg_host_variant=>exists(
        iv_name   = CONV zif_gg_session_types_v1=>ty_variant( is_request-variant )
        iv_report = lv_report
        iv_owner  = 'GG_BROWSER' ) = abap_false.
      sy-subrc = 6.
      RETURN.
    ENDIF.
    zcl_gg_host_variant=>delete(
      iv_name   = CONV zif_gg_session_types_v1=>ty_variant( is_request-variant )
      iv_report = lv_report
      iv_owner  = 'GG_BROWSER' ).
    sy-subrc = 0.
  ENDMETHOD.

  METHOD append_parameter.
    APPEND VALUE #( selname = iv_name
                    kind    = iv_kind
                    sign    = iv_sign
                    option  = iv_option
                    low     = iv_low
                    high    = iv_high ) TO ct_table.
  ENDMETHOD.

  METHOD values_to_table.
    CLEAR ct_table.
    LOOP AT it_values INTO DATA(ls_value).
      IF ls_value-ranges IS INITIAL.
        APPEND VALUE #( selname = CONV string( ls_value-name )
                        kind    = 'P'
                        sign    = 'I'
                        option  = 'EQ'
                        low     = ls_value-value
                        high    = '' ) TO ct_table.
      ELSE.
        LOOP AT ls_value-ranges INTO DATA(ls_range).
          APPEND VALUE #( selname = CONV string( ls_value-name )
                          kind    = 'S'
                          sign    = CONV string( ls_range-sign )
                          option  = CONV string( ls_range-option )
                          low     = ls_range-low
                          high    = ls_range-high ) TO ct_table.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD table_to_values.
    DATA lv_name TYPE string.
    DATA lv_kind TYPE string.
    DATA lv_sign TYPE string.
    DATA lv_option TYPE string.
    DATA lv_low TYPE string.
    DATA lv_high TYPE string.

    LOOP AT it_table INTO DATA(ls_row).
      CLEAR: lv_name, lv_kind, lv_sign, lv_option, lv_low, lv_high.
      lv_name = CONV string( ls_row-selname ).
      IF lv_name IS INITIAL.
        CONTINUE.
      ENDIF.
      lv_kind = to_upper( CONV string( ls_row-kind ) ).
      lv_sign = CONV string( ls_row-sign ).
      lv_option = CONV string( ls_row-option ).
      lv_low = CONV string( ls_row-low ).
      lv_high = CONV string( ls_row-high ).

      READ TABLE rt_values ASSIGNING FIELD-SYMBOL(<ls_value>)
        WITH KEY name = CONV zif_gg_selection_screen_types=>ty_name( lv_name ).
      IF sy-subrc <> 0.
        INSERT VALUE #( name = CONV zif_gg_selection_screen_types=>ty_name( lv_name ) )
          INTO TABLE rt_values.
        READ TABLE rt_values ASSIGNING <ls_value>
          WITH KEY name = CONV zif_gg_selection_screen_types=>ty_name( lv_name ).
      ENDIF.
      IF lv_kind = 'S'.
        APPEND VALUE #(
          sign   = CONV zif_gg_selection_screen_types=>ty_sign( lv_sign )
          option = CONV zif_gg_selection_screen_types=>ty_option( lv_option )
          low    = lv_low
          high   = lv_high ) TO <ls_value>-ranges.
      ELSE.
        <ls_value>-value = lv_low.
      ENDIF.
    ENDLOOP.
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
