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
    DATA mv_display_months TYPE i.
    DATA mv_week_begin_day TYPE i.
    DATA mv_selection_style TYPE i.
    DATA mt_selection TYPE cnca_itab_selection.
    DATA mt_day_info TYPE cnca_itab_day_info.

    METHODS refresh_html.

ENDCLASS.

CLASS cl_gui_calendar IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'CALENDAR' ).
    mv_focus_date = focus_date.
    mv_display_months = COND #( WHEN display_months > 0 THEN display_months ELSE 1 ).
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
    DATA lv_focus_date TYPE string.
    DATA lv_info_html TYPE string.
    DATA lv_calendar_html TYPE string.
    DATA lv_month_html TYPE string.
    DATA lv_year TYPE i.
    DATA lv_month TYPE i.
    DATA lv_start_year TYPE i.
    DATA lv_start_month TYPE i.
    DATA lv_month_index TYPE i.
    DATA lv_months TYPE i.
    DATA lv_first_date TYPE d.
    DATA lv_next_first TYPE d.
    DATA lv_last_date TYPE d.
    DATA lv_delta TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_days TYPE i.
    DATA lv_day TYPE i.
    DATA lv_cell TYPE i.
    DATA lv_column TYPE i.
    DATA lv_week TYPE i.
    DATA lv_weekday TYPE string.
    DATA lv_month_name TYPE string.
    DATA lv_date TYPE cnca_utc_date.
    DATA lv_day_class TYPE string.
    DATA lv_day_title TYPE string.
    DATA lv_month_text TYPE string.
    DATA lv_selected TYPE abap_bool.
    DATA lv_year_text TYPE string.
    DATA ls_mark_info TYPE cnca_s_day_info.

    lv_focus_date = CONV string( mv_focus_date ).
    IF strlen( lv_focus_date ) = 8.
      lv_focus_date = |{ substring( val = lv_focus_date
                                    off = 0
                                    len = 4 ) }-{ substring( val = lv_focus_date
                                                             off = 4
                                                             len = 2 ) }-{ substring( val = lv_focus_date
                                                                                      off = 6
                                                                                      len = 2 ) }|.
    ENDIF.
    LOOP AT mt_day_info INTO DATA(ls_day_info).
      lv_info_html = lv_info_html && |<span class="gg-calendar-day-info" data-date="{ CONV string( ls_day_info-date ) }" data-color="{ ls_day_info-color }">{ cl_gui_control=>escape_html( CONV string( ls_day_info-text ) ) }</span>|.
    ENDLOOP.

    lv_year = CONV i( substring(
      val = lv_focus_date
      off = 0
      len = 4 ) ).
    lv_month = CONV i( substring(
      val = lv_focus_date
      off = 4
      len = 2 ) ).
    lv_start_year = lv_year.
    lv_start_month = lv_month.
    lv_months = COND #( WHEN mv_display_months > 0 THEN mv_display_months ELSE 1 ).
    IF lv_months > 9.
      lv_months = 9.
    ENDIF.
    lv_calendar_html = |<div class="gg-calendar-grid" data-month-count="{ lv_months }" data-selection-style="{ mv_selection_style }">|.
    DO lv_months TIMES.
      lv_month_index = sy-index - 1.
      lv_year = lv_start_year + ( lv_start_month + lv_month_index - 1 ) DIV 12.
      lv_month = ( lv_start_month + lv_month_index - 1 ) MOD 12 + 1.
      lv_month_text = |{ lv_month WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
      lv_year_text = |{ lv_year WIDTH = 4 PAD = '0' }|.
      lv_first_date = CONV d( |{ lv_year_text }{ lv_month_text }01| ).
      IF lv_month = 12.
        lv_next_first = CONV d( |{ lv_year + 1 WIDTH = 4 PAD = '0' }01| && '01' ).
      ELSE.
        lv_next_first = CONV d( |{ lv_year WIDTH = 4 PAD = '0' }{ lv_month + 1 WIDTH = 2 ALIGN = RIGHT PAD = '0' }01| ).
      ENDIF.
      lv_last_date = lv_next_first - 1.
      lv_days = CONV i( substring(
        val = lv_last_date
        off = 6
        len = 2 ) ).
      lv_delta = lv_first_date - CONV d( '20240101' ).
      lv_offset = lv_delta MOD 7.
      IF lv_offset < 0.
        lv_offset = lv_offset + 7.
      ENDIF.
      CASE lv_month.
        WHEN 1.
          lv_month_name = 'January'.
        WHEN 2.
          lv_month_name = 'February'.
        WHEN 3.
          lv_month_name = 'March'.
        WHEN 4.
          lv_month_name = 'April'.
        WHEN 5.
          lv_month_name = 'May'.
        WHEN 6.
          lv_month_name = 'June'.
        WHEN 7.
          lv_month_name = 'July'.
        WHEN 8.
          lv_month_name = 'August'.
        WHEN 9.
          lv_month_name = 'September'.
        WHEN 10.
          lv_month_name = 'October'.
        WHEN 11.
          lv_month_name = 'November'.
        WHEN 12.
          lv_month_name = 'December'.
      ENDCASE.
      lv_month_html = |<table class="gg-calendar-month" aria-label="{ lv_month_name } { lv_year }"><caption>{ lv_month_name } { lv_year }</caption><thead><tr><th scope="col">Wk</th>|.
      DO 7 TIMES.
        lv_column = sy-index - 1.
        CASE lv_column.
          WHEN 0.
            lv_weekday = 'Mon'.
          WHEN 1.
            lv_weekday = 'Tue'.
          WHEN 2.
            lv_weekday = 'Wed'.
          WHEN 3.
            lv_weekday = 'Thu'.
          WHEN 4.
            lv_weekday = 'Fri'.
          WHEN 5.
            lv_weekday = 'Sat'.
          WHEN 6.
            lv_weekday = 'Sun'.
        ENDCASE.
        lv_month_html = lv_month_html && |<th scope="col">{ lv_weekday }</th>|.
      ENDDO.
      lv_month_html = lv_month_html && '</tr></thead><tbody>'.
      DO 42 TIMES.
        lv_cell = sy-index - 1.
        lv_column = lv_cell - ( lv_cell DIV 7 ) * 7.
        IF lv_column = 0.
          lv_week = lv_cell DIV 7 + 1.
          lv_month_html = lv_month_html && |<tr><th scope="row">{ lv_week }</th>|.
        ENDIF.
        lv_day = lv_cell - lv_offset + 1.
        IF lv_day < 1 OR lv_day > lv_days.
          lv_month_html = lv_month_html && '<td class="gg-calendar-empty"></td>'.
        ELSE.
          lv_date = |{ lv_year_text }{ lv_month_text }{ lv_day WIDTH = 2 ALIGN = RIGHT PAD = '0' }|.
          CLEAR lv_selected.
          IF mv_date_begin IS NOT INITIAL AND lv_date >= mv_date_begin
              AND ( mv_date_end IS INITIAL OR lv_date <= mv_date_end ).
            lv_selected = abap_true.
          ENDIF.
          CLEAR lv_day_title.
          READ TABLE mt_day_info INTO ls_mark_info
            WITH KEY date = CONV d( lv_date ).
          IF sy-subrc = 0.
            lv_day_title = CONV string( ls_mark_info-text ).
          ENDIF.
          lv_day_class = COND string(
            WHEN lv_selected = abap_true THEN 'gg-calendar-day gg-calendar-selected'
            WHEN lv_day_title IS NOT INITIAL THEN 'gg-calendar-day gg-calendar-marked'
            ELSE 'gg-calendar-day' ).
          lv_month_html = lv_month_html && |<td><span class="{ lv_day_class }" data-date="{ lv_date }" title="{ cl_gui_control=>escape_html( lv_day_title ) }">{ lv_day }</span></td>|.
        ENDIF.
        IF lv_column = 6.
          lv_month_html = lv_month_html && '</tr>'.
        ENDIF.
      ENDDO.
      lv_month_html = lv_month_html && '</tbody></table>'.
      lv_calendar_html = lv_calendar_html && lv_month_html.
    ENDDO.
    lv_calendar_html = lv_calendar_html && '</div>'.
    cl_gui_control=>set_html(
      control = me
      html    = |<section class="gg-calendar-surface" aria-label="Calendar"><label for="{ control_id }-date">Focus date</label><input type="date" id="{ control_id }-date" name="{ control_id }-date" value="{ escape_html( lv_focus_date ) }">{ lv_calendar_html }{ lv_info_html }</section>| ).
    cl_gui_control=>set_payload(
      control = me
      payload = |{ CONV string( mv_date_begin ) }/{ CONV string( mv_date_end ) }| ).
  ENDMETHOD.

ENDCLASS.
