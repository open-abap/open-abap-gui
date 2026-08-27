CLASS zcl_gg_host_list DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Classic list processor rendering to plain text. Lines are trimmed on the
* right, so an expected list can be written down as an ordinary string table.
*
* What is modelled: placement, the gap between fields, justification, page
* breaks with top_of_page and end_of_page, and reading or replacing a line.
*
* What is only recorded, having no meaning in text: FORMAT, the title and the
* GUI status, and SET BLANK LINES. Tests reach them through the getters.
*
* Interactive list processing raises zcx_gg_control_flow rather than pretending
* to work; it arrives with phase 6 of examples/PLAN.md.

  PUBLIC SECTION.
    INTERFACES zif_gg_list_session_v1.
    INTERFACES zif_gg_list_writer_v1.

    TYPES ty_text_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    CONSTANTS default_line_size TYPE i VALUE 132.

    METHODS set_handler
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1
        io_handler TYPE REF TO zif_gg_list_processing_v1 OPTIONAL.

    METHODS apply_settings
      IMPORTING
        is_settings TYPE zif_gg_list_processing_types_v1=>ty_settings.

    METHODS finish_output
      RETURNING
        VALUE(rt_lines) TYPE ty_text_lines.

    METHODS get_context
      RETURNING
        VALUE(rs_context) TYPE zif_gg_session_types_v1=>ty_list_context.

    METHODS get_format
      RETURNING
        VALUE(rs_format) TYPE zif_gg_list_processing_types_v1=>ty_format.

    METHODS get_title
      RETURNING
        VALUE(rv_title) TYPE string.

    METHODS get_status
      RETURNING
        VALUE(rs_status) TYPE zif_gg_session_types_v1=>ty_gui_status.

    METHODS get_blank_lines
      RETURNING
        VALUE(rv_enabled) TYPE abap_bool.

  PRIVATE SECTION.
    DATA mo_session   TYPE REF TO zif_gg_session_v1.
    DATA mo_handler   TYPE REF TO zif_gg_list_processing_v1.
    DATA ms_settings  TYPE zif_gg_list_processing_types_v1=>ty_settings.
    DATA ms_format    TYPE zif_gg_list_processing_types_v1=>ty_format.
    DATA ms_status    TYPE zif_gg_session_types_v1=>ty_gui_status.
    DATA mt_lines     TYPE ty_text_lines.
    DATA mv_title     TYPE string.
    DATA mv_current   TYPE string.
    DATA mv_column    TYPE i.
    DATA mv_page      TYPE i.
    DATA mv_line      TYPE i.
    DATA mv_no_gap    TYPE abap_bool.
    DATA mv_blank     TYPE abap_bool.
    DATA mv_in_event  TYPE abap_bool.
    DATA mv_breaking  TYPE abap_bool.

    METHODS ensure_page.

    METHODS begin_page
      IMPORTING
        iv_no_heading TYPE abap_bool DEFAULT abap_false.

    METHODS end_line.

    METHODS flush.

    METHODS check_page_full.

    METHODS trigger_page_break.

    METHODS place
      IMPORTING
        iv_text TYPE string.

    METHODS write_at
      IMPORTING
        is_placement TYPE zif_gg_list_processing_types_v1=>ty_placement
        iv_text      TYPE string.

    METHODS fit
      IMPORTING
        iv_text          TYPE string
        iv_length        TYPE i
        iv_justification TYPE zif_gg_list_processing_types_v1=>ty_justification OPTIONAL
      RETURNING
        VALUE(rv_text)   TYPE string.

    METHODS spaces
      IMPORTING
        iv_count       TYPE i
      RETURNING
        VALUE(rv_text) TYPE string.

    METHODS line_size
      RETURNING
        VALUE(rv_size) TYPE i.

    METHODS body_lines
      RETURNING
        VALUE(rv_lines) TYPE i.

ENDCLASS.

CLASS zcl_gg_host_list IMPLEMENTATION.

  METHOD set_handler.
    mo_session = io_session.
    mo_handler = io_handler.
  ENDMETHOD.

  METHOD apply_settings.
    ms_settings = is_settings.
    IF is_settings-title IS NOT INITIAL.
      mv_title = is_settings-title.
    ENDIF.
    IF is_settings-status IS NOT INITIAL.
      ms_status-status = is_settings-status.
    ENDIF.
  ENDMETHOD.

  METHOD finish_output.
    end_line( ).
    rt_lines = mt_lines.
  ENDMETHOD.

  METHOD get_context.
    rs_context-active = abap_true.
    rs_context-page   = mv_page.
    rs_context-line   = mv_line.
    rs_context-column = mv_column.
  ENDMETHOD.

  METHOD get_format.
    rs_format = ms_format.
  ENDMETHOD.

  METHOD get_title.
    rv_title = mv_title.
  ENDMETHOD.

  METHOD get_status.
    rs_status = ms_status.
  ENDMETHOD.

  METHOD get_blank_lines.
    rv_enabled = mv_blank.
  ENDMETHOD.

  METHOD ensure_page.
    IF mv_page = 0.
      begin_page( ).
    ENDIF.
  ENDMETHOD.

  METHOD begin_page.
    mv_page = mv_page + 1.
    mv_line = 0.
    IF iv_no_heading = abap_true OR mo_handler IS NOT BOUND.
      RETURN.
    ENDIF.
    mv_in_event = abap_true.
    mo_handler->top_of_page(
      iv_page    = mv_page
      io_session = mo_session ).
    mv_in_event = abap_false.
    end_line( ).
  ENDMETHOD.

  METHOD end_line.
    IF mv_current IS INITIAL AND mv_column <= 1.
      RETURN.
    ENDIF.
    flush( ).
  ENDMETHOD.

  METHOD flush.
    DATA lv_length TYPE i.
    DATA lv_last   TYPE string.

    lv_length = strlen( mv_current ).
    WHILE lv_length > 0.
      lv_last = substring( val = mv_current
                           off = lv_length - 1
                           len = 1 ).
      IF lv_last <> ` `.
        EXIT.
      ENDIF.
      lv_length = lv_length - 1.
    ENDWHILE.

    APPEND substring( val = mv_current
                      off = 0
                      len = lv_length ) TO mt_lines.
    CLEAR mv_current.
    mv_column = 1.
    mv_no_gap = abap_false.
    mv_line   = mv_line + 1.
    check_page_full( ).
  ENDMETHOD.

  METHOD check_page_full.
    IF mv_in_event = abap_true OR ms_settings-line_count <= 0.
      RETURN.
    ENDIF.
    IF mv_line < body_lines( ).
      RETURN.
    ENDIF.
    trigger_page_break( ).
  ENDMETHOD.

  METHOD trigger_page_break.
    IF mv_breaking = abap_true.
      RETURN.
    ENDIF.
    mv_breaking = abap_true.
    IF mo_handler IS BOUND.
      mv_in_event = abap_true.
      mo_handler->end_of_page(
        iv_page    = mv_page
        io_session = mo_session ).
      mv_in_event = abap_false.
      end_line( ).
    ENDIF.
    begin_page( ).
    mv_breaking = abap_false.
  ENDMETHOD.

  METHOD place.
    DATA lv_pad TYPE i.

    ensure_page( ).
    lv_pad = mv_column - 1 - strlen( mv_current ).
    IF lv_pad > 0.
      mv_current = mv_current && spaces( lv_pad ).
    ENDIF.
    mv_current = mv_current && iv_text.
    mv_column  = strlen( mv_current ) + 1.
  ENDMETHOD.

  METHOD write_at.
    ensure_page( ).
    IF is_placement-new_line = abap_true.
      end_line( ).
    ENDIF.
    IF is_placement-position > 0.
      mv_column = is_placement-position.
    ELSEIF mv_column > 1 AND mv_no_gap = abap_false.
      mv_column = mv_column + 1.
    ENDIF.
    place( iv_text ).
    mv_no_gap = is_placement-no_gap.
  ENDMETHOD.

  METHOD fit.
    DATA lv_pad TYPE i.

    rv_text = iv_text.
    IF iv_length <= 0.
      RETURN.
    ENDIF.
    IF strlen( rv_text ) > iv_length.
      rv_text = substring( val = rv_text
                           off = 0
                           len = iv_length ).
      RETURN.
    ENDIF.

    lv_pad = iv_length - strlen( rv_text ).
    CASE iv_justification.
      WHEN zif_gg_list_processing_types_v1=>justify_right.
        rv_text = spaces( lv_pad ) && rv_text.
      WHEN zif_gg_list_processing_types_v1=>justify_center.
        rv_text = spaces( lv_pad DIV 2 ) && rv_text && spaces( lv_pad - lv_pad DIV 2 ).
      WHEN OTHERS.
        rv_text = rv_text && spaces( lv_pad ).
    ENDCASE.
  ENDMETHOD.

  METHOD spaces.
    IF iv_count <= 0.
      RETURN.
    ENDIF.
    rv_text = repeat( val = ` `
                      occ = iv_count ).
  ENDMETHOD.

  METHOD line_size.
    rv_size = ms_settings-line_size.
    IF rv_size <= 0.
      rv_size = default_line_size.
    ENDIF.
  ENDMETHOD.

  METHOD body_lines.
    rv_lines = ms_settings-line_count - ms_settings-footer_lines.
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~write_field.
    write_at(
      is_placement = is_field-placement
      iv_text      = fit( iv_text          = is_field-text
                          iv_length        = is_field-placement-length
                          iv_justification = is_field-write_format-justification ) ).
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~write_checkbox.
    DATA lv_text TYPE string.

    IF is_checkbox-value = abap_true.
      lv_text = '[X]'.
    ELSE.
      lv_text = '[ ]'.
    ENDIF.
    write_at(
      is_placement = is_checkbox-placement
      iv_text      = lv_text ).
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~write_icon.
    write_at(
      is_placement = is_icon-placement
      iv_text      = |@{ is_icon-name }@| ).
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~write_symbol.
    write_at(
      is_placement = is_symbol-placement
      iv_text      = |@{ is_symbol-name }@| ).
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~new_line.
    ensure_page( ).
    end_line( ).
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~skip.
    ensure_page( ).
    end_line( ).
    DO iv_lines TIMES.
      flush( ).
    ENDDO.
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~uline.
    DATA lv_length TYPE i.

    ensure_page( ).
    end_line( ).
    lv_length = is_uline-length.
    IF lv_length <= 0.
      lv_length = line_size( ).
    ENDIF.
    IF is_uline-position > 0.
      mv_column = is_uline-position.
    ENDIF.
    place( repeat( val = '-'
                   occ = lv_length ) ).
    end_line( ).
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~set_position.
    mv_column = iv_position.
    mv_no_gap = abap_true.
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~reserve.
    ensure_page( ).
    end_line( ).
    IF ms_settings-line_count > 0 AND mv_line + iv_lines > body_lines( ).
      trigger_page_break( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~set_blank_lines.
    mv_blank = iv_enabled.
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~new_page.
    ensure_page( ).
    end_line( ).
    IF is_new_page-line_size > 0.
      ms_settings-line_size = is_new_page-line_size.
    ENDIF.
    IF is_new_page-line_count > 0.
      ms_settings-line_count = is_new_page-line_count.
    ENDIF.
    IF is_new_page-no_title = abap_true.
      CLEAR mv_title.
    ENDIF.
    begin_page( is_new_page-no_heading ).
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~set_format.
    ms_format = is_format.
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~reset_format.
    CLEAR ms_format.
  ENDMETHOD.

  METHOD zif_gg_list_session_v1~get_writer.
    ro_writer = me.
  ENDMETHOD.

  METHOD zif_gg_list_session_v1~enter_list_processing.
    RAISE EXCEPTION NEW zcx_gg_control_flow(
      iv_kind      = zcx_gg_control_flow=>kind_unsupported
      iv_operation = 'LEAVE TO LIST-PROCESSING' ).
  ENDMETHOD.

  METHOD zif_gg_list_session_v1~leave_list_processing.
    RAISE EXCEPTION NEW zcx_gg_control_flow(
      iv_kind      = zcx_gg_control_flow=>kind_unsupported
      iv_operation = 'LEAVE LIST-PROCESSING' ).
  ENDMETHOD.

  METHOD zif_gg_list_session_v1~get_cursor.
    rs_cursor-page   = mv_page.
    rs_cursor-line   = mv_line.
    rs_cursor-column = mv_column.
  ENDMETHOD.

  METHOD zif_gg_list_session_v1~read_line.
    IF iv_index < 1 OR iv_index > lines( mt_lines ).
      RETURN.
    ENDIF.
    rs_line-level = iv_level.
    rs_line-index = iv_index.
    rs_line-page  = mv_page.
    rs_line-text  = mt_lines[ iv_index ].
  ENDMETHOD.

  METHOD zif_gg_list_session_v1~modify_line.
    IF is_line-index < 1 OR is_line-index > lines( mt_lines ).
      RETURN.
    ENDIF.
    mt_lines[ is_line-index ] = is_line-text.
  ENDMETHOD.

  METHOD zif_gg_list_session_v1~set_title.
    mv_title = iv_title.
  ENDMETHOD.

  METHOD zif_gg_list_session_v1~set_status.
    ms_status = is_status.
  ENDMETHOD.

ENDCLASS.
