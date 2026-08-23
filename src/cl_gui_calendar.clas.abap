CLASS cl_gui_calendar DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.

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

ENDCLASS.

CLASS cl_gui_calendar IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD go_to_date.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_selection.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_selection.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_day_info.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD reset_day_info.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD reset_selection.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
