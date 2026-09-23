CLASS zcl_gg_system_table_data DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Bounded read-only data access. A criterion addresses a field by Dictionary
* position, so no SQL fragment, field name, sort or filter expression can be
* supplied by a browser. Every value is compared and formatted here, and the
* hard row maximum is applied before any row reaches a renderer.

  PUBLIC SECTION.
    INTERFACES zif_gg_table_data_service_v1.

    CONSTANTS max_rows TYPE i VALUE 100.

  PRIVATE SECTION.
    METHODS internal_values
      IMPORTING
        is_row           TYPE zsflight
      RETURNING
        VALUE(rt_values) TYPE string_table.
    METHODS display_value
      IMPORTING
        is_field       TYPE zif_gg_system_types_v1=>ty_ddic_field
        iv_internal    TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.
    METHODS matches
      IMPORTING
        is_criterion    TYPE zif_gg_system_types_v1=>ty_table_criterion
        iv_value        TYPE string
      RETURNING
        VALUE(rv_match) TYPE abap_bool.
    METHODS normalized
      IMPORTING
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.
    METHODS output_fields
      IMPORTING
        is_criteria      TYPE zif_gg_system_types_v1=>ty_table_criteria
        it_fields        TYPE zif_gg_system_types_v1=>ty_ddic_fields
      RETURNING
        VALUE(rt_fields) TYPE zif_gg_system_types_v1=>ty_ddic_fields.

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

  METHOD zif_gg_table_data_service_v1~get_table_names.
    rt_names = VALUE string_table( ( `ZSFLIGHT` ) ).
  ENDMETHOD.

  METHOD zif_gg_table_data_service_v1~get_fields.
    DATA(lo_dictionary) = NEW zcl_gg_system_dictionary( ).
    DATA lt_names TYPE string_table.
    DATA lv_table_name TYPE string.

    lv_table_name = normalized( iv_table_name ).
    lt_names = zif_gg_table_data_service_v1~get_table_names( ).
    IF NOT line_exists( lt_names[ table_line = lv_table_name ] ).
      RETURN.
    ENDIF.
    DATA(ls_object) = lo_dictionary->zif_gg_dictionary_service_v1~get_object(
      iv_object_type = zif_gg_system_types_v1=>ddic_table
      iv_name        = lv_table_name ).
    rt_fields = ls_object-fields.
  ENDMETHOD.

  METHOD zif_gg_table_data_service_v1~validate.
    DATA lt_fields TYPE zif_gg_system_types_v1=>ty_ddic_fields.
    DATA lt_names TYPE string_table.
    DATA lv_table_name TYPE string.

    lv_table_name = normalized( is_criteria-table_name ).
    lt_names = zif_gg_table_data_service_v1~get_table_names( ).
    IF NOT line_exists( lt_names[ table_line = lv_table_name ] ).
      rv_error = 'Table is unknown or not permitted by the data-access policy.'.
      RETURN.
    ENDIF.
    IF is_criteria-max_rows <= 0.
      rv_error = 'Maximum hits must be greater than zero.'.
      RETURN.
    ENDIF.
    lt_fields = zif_gg_table_data_service_v1~get_fields( lv_table_name ).
    LOOP AT is_criteria-rows INTO DATA(ls_criterion).
      READ TABLE lt_fields INTO DATA(ls_field)
        WITH KEY position = ls_criterion-position.
      IF sy-subrc <> 0.
        rv_error = 'A selection criterion does not address a field of this table.'.
        RETURN.
      ENDIF.
      IF ls_criterion-operator <> zif_gg_system_types_v1=>operator_eq
          AND ls_criterion-operator <> zif_gg_system_types_v1=>operator_bt
          AND ls_criterion-operator <> zif_gg_system_types_v1=>operator_ne
          AND ls_criterion-operator <> zif_gg_system_types_v1=>operator_nb.
        rv_error = |Operator for { ls_field-name } is not a supported comparison.|.
        RETURN.
      ENDIF.
      IF ls_criterion-low IS INITIAL AND ls_criterion-high IS NOT INITIAL.
        rv_error = |Enter a low value for { ls_field-name } before an upper limit.|.
        RETURN.
      ENDIF.
      IF ls_criterion-low IS INITIAL.
        CONTINUE.
      ENDIF.
      IF ( ls_criterion-operator = zif_gg_system_types_v1=>operator_bt
          OR ls_criterion-operator = zif_gg_system_types_v1=>operator_nb )
          AND ls_criterion-high IS INITIAL.
        rv_error = |A range on { ls_field-name } needs both a low and a high value.|.
        RETURN.
      ENDIF.
      IF ( ls_field-int_type = 'N' OR ls_field-int_type = 'D' OR ls_field-int_type = 'P' )
          AND ( ls_criterion-low CN '0123456789'
          OR ( ls_criterion-high IS NOT INITIAL AND ls_criterion-high CN '0123456789' ) ).
        rv_error = |{ ls_field-name } is a { ls_field-data_type } field and only accepts digits.|.
        RETURN.
      ENDIF.
      IF strlen( ls_criterion-low ) > ls_field-length
          OR strlen( ls_criterion-high ) > ls_field-length.
        rv_error = |A value for { ls_field-name } is longer than { ls_field-length } characters.|.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_gg_table_data_service_v1~read.
    DATA lt_rows TYPE STANDARD TABLE OF zsflight WITH DEFAULT KEY.
    DATA lt_fields TYPE zif_gg_system_types_v1=>ty_ddic_fields.
    DATA lt_internal TYPE string_table.
    DATA lv_limit TYPE i.
    DATA lv_row TYPE i.
    DATA lv_selected TYPE abap_bool.

    rs_result-error = zif_gg_table_data_service_v1~validate( is_criteria ).
    IF rs_result-error IS NOT INITIAL.
      RETURN.
    ENDIF.
    rs_result-table_name = normalized( is_criteria-table_name ).
    lt_fields = zif_gg_table_data_service_v1~get_fields( rs_result-table_name ).
    rs_result-fields = output_fields( is_criteria = is_criteria
                                      it_fields   = lt_fields ).
    lv_limit = is_criteria-max_rows.
    IF lv_limit <= 0 OR lv_limit > max_rows.
      lv_limit = max_rows.
    ENDIF.

    SELECT * FROM zsflight
      INTO TABLE @lt_rows
      ORDER BY carrid, connid, fldate.

    LOOP AT lt_rows INTO DATA(ls_row).
      lt_internal = internal_values( ls_row ).
      lv_selected = abap_true.
      LOOP AT is_criteria-rows INTO DATA(ls_criterion) WHERE low IS NOT INITIAL.
        READ TABLE lt_internal INTO DATA(lv_internal) INDEX ls_criterion-position.
        IF sy-subrc <> 0.
          lv_selected = abap_false.
          EXIT.
        ENDIF.
        IF matches( is_criterion = ls_criterion
                    iv_value     = lv_internal ) = abap_false.
          lv_selected = abap_false.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF lv_selected = abap_false.
        CONTINUE.
      ENDIF.
      rs_result-total_rows = rs_result-total_rows + 1.
      IF rs_result-returned_rows >= lv_limit.
        rs_result-truncated = abap_true.
        CONTINUE.
      ENDIF.
      rs_result-returned_rows = rs_result-returned_rows + 1.
      lv_row = rs_result-returned_rows.
      LOOP AT rs_result-fields INTO DATA(ls_field).
        READ TABLE lt_internal INTO lv_internal INDEX ls_field-position.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        APPEND VALUE #( row      = lv_row
                        position = ls_field-position
                        value    = display_value( is_field    = ls_field
                                                  iv_internal = lv_internal ) ) TO rs_result-cells.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD output_fields.
    DATA lv_chosen TYPE abap_bool.

    LOOP AT is_criteria-rows INTO DATA(ls_criterion) WHERE output = abap_true.
      lv_chosen = abap_true.
      READ TABLE it_fields INTO DATA(ls_field)
        WITH KEY position = ls_criterion-position.
      IF sy-subrc = 0.
        APPEND ls_field TO rt_fields.
      ENDIF.
    ENDLOOP.
    IF lv_chosen = abap_false.
      rt_fields = it_fields.
    ENDIF.
    SORT rt_fields BY position.
  ENDMETHOD.

  METHOD internal_values.
    rt_values = VALUE string_table(
      ( CONV string( is_row-carrid ) )
      ( CONV string( is_row-connid ) )
      ( CONV string( is_row-fldate ) )
      ( CONV string( is_row-price ) )
      ( CONV string( is_row-currency ) )
      ( CONV string( is_row-planetype ) )
      ( CONV string( is_row-cityfrom ) )
      ( CONV string( is_row-cityto ) ) ).
  ENDMETHOD.

  METHOD display_value.
    DATA lv_amount TYPE p LENGTH 8 DECIMALS 2.
    DATA lv_date TYPE c LENGTH 8.

    CASE is_field-int_type.
      WHEN 'D'.
        IF strlen( iv_internal ) = 8.
          lv_date = iv_internal.
          rv_text = |{ lv_date(4) }-{ lv_date+4(2) }-{ lv_date+6(2) }|.
        ELSE.
          rv_text = iv_internal.
        ENDIF.
      WHEN 'P'.
        lv_amount = iv_internal.
        rv_text = |{ lv_amount DECIMALS = 2 }|.
      WHEN OTHERS.
        rv_text = iv_internal.
    ENDCASE.
  ENDMETHOD.

  METHOD matches.
    CASE is_criterion-operator.
      WHEN zif_gg_system_types_v1=>operator_eq.
        rv_match = xsdbool( iv_value = is_criterion-low ).
      WHEN zif_gg_system_types_v1=>operator_ne.
        rv_match = xsdbool( iv_value <> is_criterion-low ).
      WHEN zif_gg_system_types_v1=>operator_bt.
        rv_match = xsdbool( iv_value >= is_criterion-low
                        AND iv_value <= is_criterion-high ).
      WHEN OTHERS.
        rv_match = xsdbool( iv_value < is_criterion-low
                         OR iv_value > is_criterion-high ).
    ENDCASE.
  ENDMETHOD.

  METHOD normalized.
    rv_text = iv_text.
    SHIFT rv_text LEFT DELETING LEADING space.
    TRANSLATE rv_text TO UPPER CASE.
  ENDMETHOD.

ENDCLASS.
