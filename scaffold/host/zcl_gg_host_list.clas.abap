CLASS zcl_gg_host_list DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Classic list processor model. Text lines remain available for compatibility,
* while fragments retain enough information for an HTML page renderer.
*
* What is modelled: placement, the gap between fields, justification, page
* breaks with top_of_page and end_of_page, and reading or replacing a line.
*
* What is only recorded, having no meaning in text: FORMAT, the title and the
* GUI status, and SET BLANK LINES. Tests reach them through the getters.
*
* Interactive list processing is driven explicitly by the host and retains
* hidden fields, cursor context, list levels, and line formats.

  PUBLIC SECTION.
    INTERFACES zif_gg_list_session_v1.
    INTERFACES zif_gg_list_writer_v1.

    TYPES ty_text_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    TYPES ty_line_formats TYPE STANDARD TABLE OF zif_gg_list_processing_types_v1=>ty_format
      WITH DEFAULT KEY.
    TYPES ty_hidden_lines TYPE STANDARD TABLE OF zif_gg_list_processing_types_v1=>ty_hidden_fields
      WITH DEFAULT KEY.
    TYPES: BEGIN OF ty_fragment,
             kind     TYPE string,
             text     TYPE string,
             position TYPE i,
             length   TYPE i,
             format   TYPE zif_gg_list_processing_types_v1=>ty_format,
             hidden   TYPE zif_gg_list_processing_types_v1=>ty_hidden_fields,
           END OF ty_fragment.
    TYPES ty_fragments TYPE STANDARD TABLE OF ty_fragment WITH DEFAULT KEY.
    TYPES: BEGIN OF ty_render_line,
             level     TYPE i,
             page      TYPE i,
             index     TYPE i,
             token     TYPE string,
             text      TYPE string,
             format    TYPE zif_gg_list_processing_types_v1=>ty_format,
             fields    TYPE zif_gg_list_processing_types_v1=>ty_hidden_fields,
             fragments TYPE ty_fragments,
           END OF ty_render_line.
    TYPES ty_render_lines TYPE STANDARD TABLE OF ty_render_line WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_model_event,
             kind       TYPE string,
             level      TYPE i,
             page       TYPE i,
             line       TYPE i,
             position   TYPE i,
             text       TYPE string,
             line_count TYPE i,
           END OF ty_model_event.
    TYPES ty_model_events TYPE STANDARD TABLE OF ty_model_event WITH DEFAULT KEY.

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

    METHODS get_settings
      RETURNING
        VALUE(rs_settings) TYPE zif_gg_list_processing_types_v1=>ty_settings.

    METHODS get_line_formats
      RETURNING
        VALUE(rt_formats) TYPE ty_line_formats.

    METHODS get_blank_lines
      RETURNING
        VALUE(rv_enabled) TYPE abap_bool.

    METHODS get_render_lines
      RETURNING
        VALUE(rt_lines) TYPE ty_render_lines.

    METHODS get_model_events
      RETURNING
        VALUE(rt_events) TYPE ty_model_events.

    METHODS select_line
      IMPORTING
        iv_index TYPE i
        iv_field TYPE zif_gg_session_types_v1=>ty_name OPTIONAL
        iv_value TYPE string OPTIONAL.

    METHODS begin_line_selection
      IMPORTING
        iv_level TYPE i.

  PRIVATE SECTION.
    DATA mo_session   TYPE REF TO zif_gg_session_v1.
    DATA mo_handler   TYPE REF TO zif_gg_list_processing_v1.
    DATA ms_settings  TYPE zif_gg_list_processing_types_v1=>ty_settings.
    DATA ms_format    TYPE zif_gg_list_processing_types_v1=>ty_format.
    DATA ms_status    TYPE zif_gg_session_types_v1=>ty_gui_status.
    DATA mt_lines     TYPE ty_text_lines.
    DATA mt_line_formats TYPE ty_line_formats.
    DATA mt_hidden_lines TYPE ty_hidden_lines.
    DATA mt_current_hidden TYPE zif_gg_list_processing_types_v1=>ty_hidden_fields.
    DATA mt_render_lines TYPE ty_render_lines.
    DATA mt_model_events TYPE ty_model_events.
    DATA mt_current_fragments TYPE ty_fragments.
    DATA mv_title     TYPE string.
    DATA mv_current   TYPE string.
    DATA mv_column    TYPE i.
    DATA mv_page      TYPE i.
    DATA mv_line      TYPE i.
    DATA mv_list_level TYPE i.
    DATA mv_no_gap    TYPE abap_bool.
    DATA mv_blank     TYPE abap_bool.
    DATA mv_in_event  TYPE abap_bool.
    DATA mv_breaking  TYPE abap_bool.
    DATA mv_selected_line TYPE i.
    DATA mv_cursor_field TYPE zif_gg_session_types_v1=>ty_name.
    DATA mv_cursor_value TYPE string.

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
        iv_text      TYPE string
        iv_kind      TYPE string DEFAULT 'TEXT'
        it_hidden    TYPE zif_gg_list_processing_types_v1=>ty_hidden_fields OPTIONAL.

    METHODS fit
      IMPORTING
        iv_text          TYPE string
        iv_length        TYPE i
        iv_justification TYPE zif_gg_list_processing_types_v1=>ty_justification OPTIONAL
      RETURNING
        VALUE(rv_text)   TYPE string.

    METHODS format_write
      IMPORTING
        iv_text        TYPE string
        is_format      TYPE zif_gg_list_processing_types_v1=>ty_write_format
      RETURNING
        VALUE(rv_text) TYPE string.

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
    rs_context-level  = mv_list_level.
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

  METHOD get_settings.
    rs_settings = ms_settings.
  ENDMETHOD.

  METHOD get_line_formats.
    rt_formats = mt_line_formats.
  ENDMETHOD.

  METHOD get_blank_lines.
    rv_enabled = mv_blank.
  ENDMETHOD.

  METHOD get_render_lines.
    rt_lines = mt_render_lines.
  ENDMETHOD.

  METHOD get_model_events.
    rt_events = mt_model_events.
  ENDMETHOD.

  METHOD select_line.
    mv_selected_line = iv_index.
    mv_cursor_field = iv_field.
    mv_cursor_value = iv_value.
    IF mv_cursor_field IS INITIAL AND iv_index > 0
        AND iv_index <= lines( mt_hidden_lines )
        AND lines( mt_hidden_lines[ iv_index ] ) > 0.
      mv_cursor_field = mt_hidden_lines[ iv_index ][ 1 ]-name.
      mv_cursor_value = mt_hidden_lines[ iv_index ][ 1 ]-value.
    ENDIF.
  ENDMETHOD.

  METHOD begin_line_selection.
    ensure_page( ).
    IF mo_handler IS BOUND.
      mv_in_event = abap_true.
      mo_handler->top_of_page_during_line_sel(
        iv_level = iv_level
        iv_page  = mv_page
        io_session = mo_session ).
      mv_in_event = abap_false.
      end_line( ).
    ENDIF.
  ENDMETHOD.

  METHOD ensure_page.
    IF mv_page = 0.
      begin_page( ).
    ENDIF.
  ENDMETHOD.

  METHOD begin_page.
    mv_page = mv_page + 1.
    mv_line = 0.
    APPEND VALUE #( kind = 'PAGE_BEGIN'
                    level = mv_list_level
                    page = mv_page ) TO mt_model_events.
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
    DATA lv_page TYPE i.
    DATA lv_line TYPE i.
    IF mv_current IS INITIAL AND mv_column <= 1.
      RETURN.
    ENDIF.
    lv_page = mv_page.
    lv_line = mv_line.
    flush( ).
    APPEND VALUE #( kind = 'LINE_BREAK'
                    level = mv_list_level
                    page = lv_page
                    line = lv_line ) TO mt_model_events.
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
    APPEND ms_format TO mt_line_formats.
    APPEND mt_current_hidden TO mt_hidden_lines.
    APPEND VALUE #( level     = mv_list_level
                    page      = mv_page
                    index     = lines( mt_lines )
                    token     = |H-{ mv_page }-{ lines( mt_lines ) }|
                    text      = substring( val = mv_current
                                           off = 0
                                           len = lv_length )
                    format    = ms_format
                    fields    = mt_current_hidden
                    fragments = mt_current_fragments ) TO mt_render_lines.
    CLEAR mv_current.
    CLEAR mt_current_hidden.
    CLEAR mt_current_fragments.
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
    APPEND VALUE #( kind = 'PAGE_END'
                    level = mv_list_level
                    page = mv_page
                    line = mv_line ) TO mt_model_events.
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
    DATA(lv_position) = mv_column.
    place( iv_text ).
    APPEND VALUE #( kind     = iv_kind
                    text     = iv_text
                    position = lv_position
                    length   = strlen( iv_text )
                    format   = ms_format
                    hidden   = it_hidden ) TO mt_current_fragments.
    APPEND LINES OF it_hidden TO mt_current_hidden.
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

  METHOD format_write.
    DATA lv_integer TYPE string.
    DATA lv_fraction TYPE string.
    DATA lv_offset TYPE i.

    rv_text = iv_text.
    IF is_format-edit_mask IS NOT INITIAL.
      rv_text = is_format-edit_mask.
      REPLACE FIRST OCCURRENCE OF '*' IN rv_text WITH iv_text.
    ENDIF.

    IF is_format-decimals > 0 AND rv_text CO '0123456789.-+'.
      FIND FIRST OCCURRENCE OF '.' IN rv_text MATCH OFFSET lv_offset.
      IF sy-subrc = 0.
        lv_integer = substring( val = rv_text off = 0 len = lv_offset ).
        lv_fraction = substring( val = rv_text off = lv_offset + 1 ).
      ELSE.
        lv_integer = rv_text.
      ENDIF.
      WHILE strlen( lv_fraction ) < is_format-decimals.
        lv_fraction = lv_fraction && `0`.
      ENDWHILE.
      IF strlen( lv_fraction ) > is_format-decimals.
        lv_fraction = substring( val = lv_fraction
                                 off = 0
                                 len = is_format-decimals ).
      ENDIF.
      rv_text = lv_integer && `.` && lv_fraction.
    ELSEIF is_format-decimals = 0 AND rv_text CO '0123456789.-+'.
      FIND FIRST OCCURRENCE OF '.' IN rv_text MATCH OFFSET lv_offset.
      IF sy-subrc = 0.
        rv_text = substring( val = rv_text off = 0 len = lv_offset ).
      ENDIF.
    ENDIF.

    IF is_format-no_zero = abap_true AND rv_text CO '0.-+'.
      rv_text = ``.
    ENDIF.
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
      iv_kind      = 'TEXT'
      iv_text      = fit( iv_text          = format_write(
                            iv_text   = is_field-text
                            is_format = is_field-write_format )
                          iv_length        = is_field-placement-length
                          iv_justification = is_field-write_format-justification )
      it_hidden    = is_field-hide ).
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
      iv_text      = lv_text
      iv_kind      = 'CHECKBOX' ).
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~write_icon.
    write_at(
      is_placement = is_icon-placement
      iv_text      = |@{ is_icon-name }@|
      iv_kind      = 'ICON' ).
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~write_symbol.
    write_at(
      is_placement = is_symbol-placement
      iv_text      = |@{ is_symbol-name }@|
      iv_kind      = 'SYMBOL' ).
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~new_line.
    ensure_page( ).
    end_line( ).
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~skip.
    ensure_page( ).
    end_line( ).
    DO iv_lines TIMES.
      APPEND VALUE #( kind = 'SKIP'
                      level = mv_list_level
                      page = mv_page
                      line_count = 1 ) TO mt_model_events.
      flush( ).
    ENDDO.
  ENDMETHOD.

  METHOD zif_gg_list_writer_v1~uline.
    DATA lv_length TYPE i.

    ensure_page( ).
    APPEND VALUE #( kind = 'ULINE'
                    level = mv_list_level
                    page = mv_page
                    position = is_uline-position
                    line_count = is_uline-length ) TO mt_model_events.
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
    mv_list_level = mv_list_level + 1.
  ENDMETHOD.

  METHOD zif_gg_list_session_v1~leave_list_processing.
    IF mv_list_level > 0.
      mv_list_level = mv_list_level - 1.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_list_session_v1~get_cursor.
    rs_cursor-page   = mv_page.
    rs_cursor-line   = mv_line.
    rs_cursor-column = mv_column.
    IF mv_selected_line > 0.
      rs_cursor-line  = mv_selected_line.
      rs_cursor-field = mv_cursor_field.
      rs_cursor-value = mv_cursor_value.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_list_session_v1~get_context.
    rs_context = get_context( ).
  ENDMETHOD.

  METHOD zif_gg_list_session_v1~read_line.
    IF iv_index < 1 OR iv_index > lines( mt_lines ).
      RETURN.
    ENDIF.
    rs_line-level = iv_level.
    rs_line-index = iv_index.
    rs_line-page  = mv_page.
    rs_line-text  = mt_lines[ iv_index ].
    IF iv_index <= lines( mt_hidden_lines ).
      rs_line-fields = mt_hidden_lines[ iv_index ].
    ENDIF.
    IF iv_index <= lines( mt_line_formats ).
      rs_line-format = mt_line_formats[ iv_index ].
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_list_session_v1~modify_line.
    IF is_line-index < 1 OR is_line-index > lines( mt_lines ).
      RETURN.
    ENDIF.
    mt_lines[ is_line-index ] = is_line-text.
    IF is_line-index <= lines( mt_render_lines ).
      mt_render_lines[ is_line-index ]-text = is_line-text.
      CLEAR mt_render_lines[ is_line-index ]-fragments.
      APPEND VALUE #( kind     = 'TEXT'
                      text     = is_line-text
                      position = 1
                      length   = strlen( is_line-text )
                      format   = is_line-format )
        TO mt_render_lines[ is_line-index ]-fragments.
    ENDIF.
    IF is_line-index <= lines( mt_line_formats ).
      mt_line_formats[ is_line-index ] = is_line-format.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_list_session_v1~set_title.
    mv_title = iv_title.
  ENDMETHOD.

  METHOD zif_gg_list_session_v1~set_status.
    ms_status = is_status.
  ENDMETHOD.

ENDCLASS.
