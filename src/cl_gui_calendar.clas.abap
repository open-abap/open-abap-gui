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
    DATA mt_selection TYPE cnca_itab_selection.

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
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD reset_day_info.
    RETURN.
  ENDMETHOD.

  METHOD reset_selection.
    CLEAR mv_date_begin.
    CLEAR mv_date_end.
    CLEAR mt_selection.
    refresh_html( ).
  ENDMETHOD.

  METHOD refresh_html.
    DATA lv_focus_date TYPE string.

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
    cl_gui_control=>set_html(
      control = me
      html    = |<label for="{ control_id }-date">Focus date</label><input type="date" id="{ control_id }-date" name="{ control_id }-date" value="{ escape_html( lv_focus_date ) }">| ).
    cl_gui_control=>set_payload(
      control = me
      payload = |{ CONV string( mv_date_begin ) }/{ CONV string( mv_date_end ) }| ).
  ENDMETHOD.

ENDCLASS.
