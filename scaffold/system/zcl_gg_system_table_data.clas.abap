CLASS zcl_gg_system_table_data DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_table_data_service_v1.

ENDCLASS.

CLASS zcl_gg_system_table_data IMPLEMENTATION.

  METHOD zif_gg_table_data_service_v1~get_capabilities.
    rs_capabilities = VALUE #(
      display_only = abap_true
      can_change   = abap_false
      can_create   = abap_false
      can_save     = abap_false
      can_activate = abap_false
      can_release  = abap_false
      can_export   = abap_false
      can_debug    = abap_false
      explanation  = 'Read-only Data Browser: table mutation and arbitrary SQL are unavailable.' ).
  ENDMETHOD.

  METHOD zif_gg_table_data_service_v1~get_fields.
    DATA(lo_dictionary) = NEW zcl_gg_system_dictionary( ).
    DATA(ls_object) = lo_dictionary->zif_gg_dictionary_service_v1~get_object(
      iv_object_type = 'TABLE'
      iv_name        = iv_table_name ).
    rt_fields = ls_object-fields.
  ENDMETHOD.

  METHOD zif_gg_table_data_service_v1~read.
    DATA lv_table_name TYPE string.
    DATA lv_low TYPE zsflight-carrid.
    DATA lv_high TYPE zsflight-carrid.
    DATA lv_limit TYPE i.
    DATA lt_rows TYPE zif_gg_system_types_v1=>ty_flights.

    lv_table_name = is_criteria-table_name.
    SHIFT lv_table_name LEFT DELETING LEADING space.
    TRANSLATE lv_table_name TO UPPER CASE.
    IF lv_table_name <> 'ZSFLIGHT'.
      rs_result-error = 'Table is unknown or not permitted by the data-access policy.'.
      RETURN.
    ENDIF.
    rs_result-table_name = lv_table_name.
    lv_limit = is_criteria-max_rows.
    IF lv_limit <= 0 OR lv_limit > 100.
      lv_limit = 100.
    ENDIF.
    lv_low = is_criteria-carrid_low.
    lv_high = is_criteria-carrid_high.
    IF lv_low IS INITIAL AND lv_high IS INITIAL.
      SELECT * FROM zsflight
        INTO TABLE @lt_rows
        ORDER BY carrid, connid, fldate.
    ELSEIF lv_high IS INITIAL.
      IF is_criteria-exclude_carrid = abap_true.
        SELECT * FROM zsflight
          INTO TABLE @lt_rows
          WHERE carrid <> @lv_low
          ORDER BY carrid, connid, fldate.
      ELSE.
        SELECT * FROM zsflight
          INTO TABLE @lt_rows
          WHERE carrid = @lv_low
          ORDER BY carrid, connid, fldate.
      ENDIF.
    ELSEIF is_criteria-exclude_carrid = abap_true.
      SELECT * FROM zsflight
        INTO TABLE @lt_rows
        WHERE carrid <> @lv_low AND carrid <> @lv_high
        ORDER BY carrid, connid, fldate.
    ELSE.
      SELECT * FROM zsflight
        INTO TABLE @lt_rows
        WHERE carrid BETWEEN @lv_low AND @lv_high
        ORDER BY carrid, connid, fldate.
    ENDIF.
    rs_result-total_rows = lines( lt_rows ).
    LOOP AT lt_rows INTO DATA(ls_row).
      IF lines( rs_result-rows ) >= lv_limit.
        rs_result-truncated = abap_true.
        EXIT.
      ENDIF.
      APPEND ls_row TO rs_result-rows.
    ENDLOOP.
    rs_result-returned_rows = lines( rs_result-rows ).
  ENDMETHOD.

ENDCLASS.
