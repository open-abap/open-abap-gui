CLASS cl_gui_calendar DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.

    CONSTANTS m_id_ctxmenu_request TYPE i VALUE 1.
    CONSTANTS m_id_date_selected TYPE i VALUE 3.
    CONSTANTS m_id_info_request TYPE i VALUE 4.
    CONSTANTS m_id_pre_selection TYPE i VALUE 6.
    CONSTANTS m_id_f2 TYPE i VALUE 7.
    CONSTANTS m_id_f12 TYPE i VALUE 8.

    EVENTS date_selected
      EXPORTING
        VALUE(date_begin)      TYPE cnca_utc_date
        VALUE(date_end)        TYPE cnca_utc_date
        VALUE(selection_table) TYPE cnca_itab_selection.

    EVENTS info_request
      EXPORTING
        VALUE(date_begin) TYPE cnca_utc_date
        VALUE(date_end)   TYPE cnca_utc_date.

    METHODS constructor
      IMPORTING
        parent           TYPE REF TO cl_gui_container OPTIONAL
        name             TYPE string OPTIONAL
        lifetime         TYPE i OPTIONAL
        view_style       TYPE i OPTIONAL
        selection_style  TYPE i DEFAULT cnca_sel_day
        shellstyle       TYPE i OPTIONAL
        stand_alone      TYPE clike OPTIONAL
        focus_date       TYPE cnca_utc_date OPTIONAL
        display_months   TYPE i DEFAULT 3
        dtpicker_format  TYPE cnca_format OPTIONAL
        week_begin_day   TYPE i OPTIONAL
        week_end         TYPE clike OPTIONAL
        year_begin       TYPE i OPTIONAL
        year_end         TYPE i OPTIONAL
        cell_text_length TYPE i OPTIONAL
      EXCEPTIONS
        cntl_error
        cntl_system_error
        create_error
        lifetime_error.

    METHODS go_to_date
      IMPORTING
        focus_date TYPE cnca_utc_date
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_selection
      IMPORTING
        date_begin      TYPE cnca_utc_date OPTIONAL
        date_end        TYPE cnca_utc_date OPTIONAL
        selection_table TYPE cnca_itab_selection OPTIONAL
        no_scroll       TYPE clike OPTIONAL
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS get_selection
      EXPORTING
        date_begin      TYPE cnca_utc_date
        date_end        TYPE cnca_utc_date
        selection_table TYPE cnca_itab_selection
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_day_info
      IMPORTING
        day_info TYPE cnca_itab_day_info
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS reset_day_info
      EXCEPTIONS
        cntl_error.

    METHODS reset_selection
      EXCEPTIONS
        cntl_error.

  PRIVATE SECTION.
    DATA mv_focus_date TYPE cnca_utc_date.
    DATA mv_date_begin TYPE cnca_utc_date.
    DATA mv_date_end TYPE cnca_utc_date.
    DATA mv_week_begin_day TYPE i.
    DATA mv_selection_style TYPE i.
    DATA mt_selection TYPE cnca_itab_selection.
    DATA mt_day_info TYPE cnca_itab_day_info.

    METHODS refresh_html.

    METHODS render_week_navigator
      RETURNING
        VALUE(result) TYPE string.

    METHODS calendar_week_number
      IMPORTING
        iv_week_start     TYPE d
      RETURNING
        VALUE(rv_week_no) TYPE i.

    METHODS calendar_day_cell
      IMPORTING
        iv_date       TYPE d
        iv_weekday    TYPE i
      RETURNING
        VALUE(result) TYPE string.

    METHODS weekday_label
      IMPORTING
        iv_weekday      TYPE i
      RETURNING
        VALUE(rv_label) TYPE string.

ENDCLASS.

CLASS cl_gui_calendar IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'CALENDAR' ).
    mv_focus_date = focus_date.
    mv_week_begin_day = COND #( WHEN week_begin_day > 0 THEN week_begin_day ELSE 1 ).
    mv_selection_style = selection_style.
    refresh_html( ).
    IF parent IS BOUND.
      parent->add_child( me ).
    ENDIF.
  ENDMETHOD.

  METHOD go_to_date.
    mv_focus_date = focus_date.
    refresh_html( ).
  ENDMETHOD.

  METHOD set_selection.
    IF date_begin IS SUPPLIED.
      mv_date_begin = date_begin.
    ENDIF.
    IF date_end IS SUPPLIED.
      mv_date_end = date_end.
    ENDIF.
    IF selection_table IS SUPPLIED.
      mt_selection = selection_table.
    ENDIF.
    refresh_html( ).
  ENDMETHOD.

  METHOD get_selection.
    date_begin = mv_date_begin.
    date_end = mv_date_end.
    selection_table = mt_selection.
  ENDMETHOD.

  METHOD set_day_info.
    mt_day_info = day_info.
    refresh_html( ).
  ENDMETHOD.

  METHOD reset_day_info.
    CLEAR mt_day_info.
    refresh_html( ).
  ENDMETHOD.

  METHOD reset_selection.
    CLEAR mv_date_begin.
    CLEAR mv_date_end.
    CLEAR mt_selection.
    refresh_html( ).
  ENDMETHOD.

  METHOD refresh_html.
    DATA lv_info_html TYPE string.

    LOOP AT mt_day_info INTO DATA(ls_day_info).
      lv_info_html = lv_info_html && |<span class="gg-calendar-day-info" data-date="{ CONV string( ls_day_info-date ) }" data-color="{ ls_day_info-color }">{ cl_gui_control=>escape_html( CONV string( ls_day_info-text ) ) }</span>|.
    ENDLOOP.
    cl_gui_control=>set_html(
      control = me
      html    = |<section class="gg-calendar-surface" aria-label="Calendar">{ render_week_navigator( ) }{ lv_info_html }</section>| ).
    cl_gui_control=>set_payload(
      control = me
      payload = COND string(
        WHEN mv_date_begin IS INITIAL AND mv_date_end IS INITIAL THEN ``
        ELSE |{ CONV string( mv_date_begin ) }/{ CONV string( mv_date_end ) }| ) ).
  ENDMETHOD.

  METHOD render_week_navigator.
    DATA lv_focus_text TYPE string.
    DATA lv_focus_year TYPE i.
    DATA lv_focus_month TYPE i.
    DATA lv_start_year TYPE i.
    DATA lv_start_month TYPE i.
    DATA lv_end_year TYPE i.
    DATA lv_end_month TYPE i.
    DATA lv_year TYPE i.
    DATA lv_month TYPE i.
    DATA lv_delta TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_month_span TYPE i.
    DATA lv_week_count TYPE i.
    DATA lv_week_index TYPE i.
    DATA lv_weekday TYPE i.
    DATA lv_actual_weekday TYPE i.
    DATA lv_row_index TYPE i.
    DATA lv_first_date TYPE d.
    DATA lv_next_first TYPE d.
    DATA lv_last_date TYPE d.
    DATA lv_week_start TYPE d.
    DATA lv_week_end_start TYPE d.
    DATA lv_week_date TYPE d.
    DATA lv_thursday TYPE d.
    DATA lv_cell_date TYPE d.
    DATA lv_month_text TYPE string.
    DATA lv_year_text TYPE string.
    DATA lv_month_label TYPE string.
    DATA lv_previous_month_label TYPE string.
    DATA lv_month_header TYPE string.
    DATA lv_week_header TYPE string.
    DATA lv_day_row TYPE string.
    DATA lt_day_rows TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    lv_focus_text = CONV string( mv_focus_date ).
    IF strlen( lv_focus_text ) < 8.
      RETURN.
    ENDIF.
    lv_focus_year = CONV i( substring(
      val = lv_focus_text
      off = 0
      len = 4 ) ).
    lv_focus_month = CONV i( substring(
      val = lv_focus_text
      off = 4
      len = 2 ) ).
    lv_start_year = lv_focus_year.
    lv_start_month = lv_focus_month - 4.
    IF lv_start_month <= 0.
      lv_start_month = lv_start_month + 12.
      lv_start_year = lv_start_year - 1.
    ENDIF.
    lv_end_year = lv_start_year.
    lv_end_month = lv_start_month + 9.
    IF lv_end_month > 12.
      lv_end_month = lv_end_month - 12.
      lv_end_year = lv_end_year + 1.
    ENDIF.
    lv_year_text = |{ lv_start_year WIDTH = 4 PAD = '0' }|.
    lv_month_text = |{ lv_start_month WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
    lv_first_date = CONV d( |{ lv_year_text }{ lv_month_text }01| ).
    IF lv_end_month = 12.
      lv_next_first = CONV d( |{ lv_end_year + 1 WIDTH = 4 PAD = '0' }0101| ).
    ELSE.
      lv_next_first = CONV d( |{ lv_end_year WIDTH = 4 PAD = '0' }{ lv_end_month + 1 WIDTH = 2 ALIGN = RIGHT PAD = '0' }01| ).
    ENDIF.
    lv_last_date = lv_next_first - 1.
    lv_delta = lv_first_date - CONV d( '20240101' ).
    lv_offset = lv_delta MOD 7.
    IF lv_offset < 0.
      lv_offset = lv_offset + 7.
    ENDIF.
    lv_offset = ( lv_offset - mv_week_begin_day + 1 + 7 ) MOD 7.
    lv_week_start = lv_first_date - lv_offset.
    lv_delta = lv_last_date - CONV d( '20240101' ).
    lv_offset = lv_delta MOD 7.
    IF lv_offset < 0.
      lv_offset = lv_offset + 7.
    ENDIF.
    lv_offset = ( lv_offset - mv_week_begin_day + 1 + 7 ) MOD 7.
    lv_week_end_start = lv_last_date - lv_offset.
    lv_week_count = ( lv_week_end_start - lv_week_start ) DIV 7 + 1.

    DO 7 TIMES.
      lv_weekday = sy-index - 1.
      APPEND |<tr><th class="gg-calendar-weekday" scope="row">{ weekday_label( lv_weekday ) }</th>| TO lt_day_rows.
    ENDDO.
    DO lv_week_count TIMES.
      lv_week_index = sy-index - 1.
      lv_week_date = lv_week_start + ( lv_week_index * 7 ).
      lv_thursday = lv_week_date + 3.
      lv_year = CONV i( substring(
        val = CONV string( lv_thursday )
        off = 0
        len = 4 ) ).
      lv_month = CONV i( substring(
        val = CONV string( lv_thursday )
        off = 4
        len = 2 ) ).
      lv_month_label = |{ lv_year }/{ lv_month }|.
      IF lv_month_label <> lv_previous_month_label.
        IF lv_month_span > 0.
          lv_month_header = lv_month_header && |<th class="gg-calendar-month-heading" scope="colgroup" colspan="{ lv_month_span }">{ lv_previous_month_label }</th>|.
        ENDIF.
        lv_previous_month_label = lv_month_label.
        lv_month_span = 1.
      ELSE.
        lv_month_span = lv_month_span + 1.
      ENDIF.
      lv_week_header = lv_week_header && |<th class="gg-calendar-week-number" scope="col">{ calendar_week_number( lv_week_date ) }</th>|.
      DO 7 TIMES.
        lv_weekday = sy-index - 1.
        lv_actual_weekday = ( mv_week_begin_day - 1 + lv_weekday ) MOD 7.
        lv_row_index = lv_weekday + 1.
        READ TABLE lt_day_rows INTO lv_day_row INDEX lv_row_index.
        IF sy-subrc = 0.
          lv_cell_date = lv_week_date + lv_weekday.
          lv_day_row = lv_day_row && calendar_day_cell(
            iv_date    = lv_cell_date
            iv_weekday = lv_actual_weekday ).
          MODIFY lt_day_rows FROM lv_day_row INDEX lv_row_index.
        ENDIF.
      ENDDO.
    ENDDO.
    IF lv_month_span > 0.
      lv_month_header = lv_month_header && |<th class="gg-calendar-month-heading" scope="colgroup" colspan="{ lv_month_span }">{ lv_previous_month_label }</th>|.
    ENDIF.
    result = |<div class="gg-calendar-week-scroll" role="region" aria-label="Calendar weeks" data-month-count="10" data-week-count="{ lv_week_count }" data-selection-style="{ mv_selection_style }"><table class="gg-calendar-week-grid" aria-label="Calendar by week"><thead><tr><th scope="col" rowspan="2">WN</th>{ lv_month_header }</tr><tr>{ lv_week_header }</tr></thead><tbody>|.
    LOOP AT lt_day_rows INTO lv_day_row.
      result = result && |{ lv_day_row }</tr>|.
    ENDLOOP.
    result = result && '</tbody></table></div>'.
  ENDMETHOD.

  METHOD calendar_week_number.
    DATA lv_thursday TYPE d.
    DATA lv_week_year TYPE i.
    DATA lv_week_year_text TYPE string.
    DATA lv_january_fourth TYPE d.
    DATA lv_week_one_start TYPE d.
    DATA lv_delta TYPE i.
    DATA lv_offset TYPE i.

    lv_thursday = iv_week_start + 3.
    lv_week_year = CONV i( substring(
      val = CONV string( lv_thursday )
      off = 0
      len = 4 ) ).
    lv_week_year_text = |{ lv_week_year WIDTH = 4 PAD = '0' }|.
    lv_january_fourth = CONV d( |{ lv_week_year_text }0104| ).
    lv_delta = lv_january_fourth - CONV d( '20240101' ).
    lv_offset = lv_delta MOD 7.
    IF lv_offset < 0.
      lv_offset = lv_offset + 7.
    ENDIF.
    lv_offset = ( lv_offset - mv_week_begin_day + 1 + 7 ) MOD 7.
    lv_week_one_start = lv_january_fourth - lv_offset.
    rv_week_no = ( iv_week_start - lv_week_one_start ) DIV 7 + 1.
  ENDMETHOD.

  METHOD calendar_day_cell.
    DATA lv_date_text TYPE string.
    DATA lv_day_text TYPE string.
    DATA lv_day TYPE i.
    DATA lv_day_title TYPE string.
    DATA lv_day_class TYPE string.
    DATA lv_selected TYPE abap_bool.

    lv_date_text = CONV string( iv_date ).
    lv_day = CONV i( substring(
      val = lv_date_text
      off = 6
      len = 2 ) ).
    lv_day_text = |{ lv_day }|.
    lv_selected = xsdbool( iv_date = mv_focus_date ).
    IF mv_date_begin IS NOT INITIAL AND iv_date >= mv_date_begin
        AND ( mv_date_end IS INITIAL OR iv_date <= mv_date_end ).
      lv_selected = abap_true.
    ENDIF.
    READ TABLE mt_day_info INTO DATA(ls_day_info)
      WITH KEY date = iv_date.
    IF sy-subrc = 0.
      lv_day_title = CONV string( ls_day_info-text ).
    ENDIF.
    lv_day_class = COND string(
      WHEN lv_selected = abap_true THEN 'gg-calendar-date gg-calendar-selected'
      WHEN lv_day_title IS NOT INITIAL THEN 'gg-calendar-date gg-calendar-marked'
      ELSE 'gg-calendar-date' ).
    IF iv_weekday >= 5.
      lv_day_class = lv_day_class && ' gg-calendar-weekend'.
    ENDIF.
    result = |<td class="{ lv_day_class }" data-date="{ lv_date_text }" aria-selected="{ COND string( WHEN lv_selected = abap_true THEN 'true' ELSE 'false' ) }" title="{ cl_gui_control=>escape_html( lv_day_title ) }"><span>{ lv_day_text }</span></td>|.
  ENDMETHOD.

  METHOD weekday_label.
    DATA lv_day TYPE i.

    lv_day = ( mv_week_begin_day - 1 + iv_weekday ) MOD 7.
    CASE lv_day.
      WHEN 0.
        rv_label = 'MO'.
      WHEN 1.
        rv_label = 'TU'.
      WHEN 2.
        rv_label = 'WE'.
      WHEN 3.
        rv_label = 'TH'.
      WHEN 4.
        rv_label = 'FR'.
      WHEN 5.
        rv_label = 'SA'.
      WHEN 6.
        rv_label = 'SU'.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
