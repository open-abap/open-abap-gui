CLASS cl_gui_splitter_container DEFINITION PUBLIC INHERITING FROM cl_gui_container.
  PUBLIC SECTION.

    CONSTANTS mode_absolute TYPE i VALUE 0.
    CONSTANTS mode_relative TYPE i VALUE 1.

    CONSTANTS type_movable TYPE i VALUE 0.
    CONSTANTS type_sashvisible TYPE i VALUE 1.

    CONSTANTS true TYPE i VALUE 1.
    CONSTANTS false TYPE i VALUE 0.

    METHODS constructor
      IMPORTING
        parent                  TYPE REF TO cl_gui_container OPTIONAL
        rows                    TYPE i OPTIONAL
        align                   TYPE i OPTIONAL
        no_autodef_progid_dynnr TYPE c OPTIONAL
        link_dynnr              TYPE sy-dynnr OPTIONAL
        link_repid              TYPE sy-repid OPTIONAL
        columns                 TYPE i OPTIONAL.

    METHODS get_row_height
      IMPORTING
        id     TYPE i
      EXPORTING
        result TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS get_column_width
      IMPORTING
        id     TYPE i
      EXPORTING
        result TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_column_mode
      IMPORTING
        mode   TYPE i
      EXPORTING
        result TYPE i.

    METHODS set_row_sash
      IMPORTING
        id     TYPE i
        type   TYPE i
        value  TYPE i
      EXPORTING
        result TYPE i.

    METHODS set_row_height
      IMPORTING
        id     TYPE i
        height TYPE i
      EXPORTING
        result TYPE i.

    METHODS set_column_sash
      IMPORTING
        id     TYPE i
        type   TYPE i
        value  TYPE i
      EXPORTING
        result TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_row_mode
      IMPORTING
        mode   TYPE   i
      EXPORTING
        result TYPE i.

    METHODS set_column_width
      IMPORTING
        id     TYPE i
        width  TYPE i
      EXPORTING
        result TYPE i
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS set_border
      IMPORTING
        border TYPE abap_bool
      EXCEPTIONS
        cntl_error
        cntl_system_error.

    METHODS get_container
      IMPORTING
        row              TYPE i
        column           TYPE i
      RETURNING
        VALUE(container) TYPE REF TO cl_gui_container.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_cell,
             row       TYPE i,
             column    TYPE i,
             container TYPE REF TO cl_gui_container,
           END OF ty_cell.
    TYPES ty_cells TYPE STANDARD TABLE OF ty_cell WITH DEFAULT KEY.
    DATA mv_rows TYPE i.
    DATA mv_columns TYPE i.
    DATA mv_row_mode TYPE i.
    DATA mv_column_mode TYPE i.
    DATA mv_border TYPE abap_bool.
    DATA mt_row_heights TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA mt_column_widths TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA mt_row_minimums TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA mt_column_minimums TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA mt_cells TYPE ty_cells.
ENDCLASS.

CLASS cl_gui_splitter_container IMPLEMENTATION.
  METHOD get_row_height.
    READ TABLE mt_row_heights INTO result INDEX id.
  ENDMETHOD.

  METHOD get_column_width.
    READ TABLE mt_column_widths INTO result INDEX id.
  ENDMETHOD.

  METHOD set_row_sash.
    result = value.
    set_row_height(
      id     = id
      height = value ).
  ENDMETHOD.

  METHOD set_column_sash.
    result = value.
    set_column_width(
      id    = id
      width = value ).
  ENDMETHOD.

  METHOD set_row_mode.
    mv_row_mode = mode.
    result = mode.
    cl_gui_control=>set_payload( control = me
                                 payload = |rows={ mv_rows }; columns={ mv_columns }; row_mode={ mv_row_mode }; column_mode={ mv_column_mode }; border={ mv_border }| ).
  ENDMETHOD.

  METHOD set_row_height.
    DATA lv_minimum TYPE i.
    DATA lv_height TYPE i.
    IF id < 1 OR id > mv_rows.
      result = 0.
      RETURN.
    ENDIF.
    READ TABLE mt_row_minimums INTO lv_minimum INDEX id.
    lv_height = COND #( WHEN height < lv_minimum THEN lv_minimum ELSE height ).
    MODIFY mt_row_heights FROM lv_height INDEX id.
    result = lv_height.
    cl_gui_control=>set_payload( control = me
                                 payload = |rows={ mv_rows }; columns={ mv_columns }; row_mode={ mv_row_mode }; column_mode={ mv_column_mode }; border={ mv_border }| ).
  ENDMETHOD.

  METHOD constructor.
    DATA lv_row TYPE i.
    DATA lv_column TYPE i.
    DATA ls_cell TYPE ty_cell.

    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'SPLITTER_CONTAINER' ).
    IF parent IS BOUND.
      parent->add_child( me ).
    ENDIF.
    mv_rows = COND #( WHEN rows > 0 THEN rows ELSE 1 ).
    mv_columns = COND #( WHEN columns > 0 THEN columns ELSE 1 ).
    mv_row_mode = mode_relative.
    mv_column_mode = mode_relative.
    mv_border = abap_true.
    DO mv_rows TIMES.
      APPEND 100 TO mt_row_heights.
      APPEND 24 TO mt_row_minimums.
    ENDDO.
    DO mv_columns TIMES.
      APPEND 100 TO mt_column_widths.
      APPEND 24 TO mt_column_minimums.
    ENDDO.
    DO mv_rows TIMES.
      lv_row = sy-index.
      DO mv_columns TIMES.
        lv_column = sy-index.
        ls_cell = VALUE #(
          row       = lv_row
          column    = lv_column
          container = NEW cl_gui_custom_container(
            container_name = |SPLITTER-{ control_id }-{ lv_row }-{ lv_column }|
            parent         = me ) ).
        APPEND ls_cell TO mt_cells.
      ENDDO.
    ENDDO.
    cl_gui_control=>set_payload( control = me
                                 payload = |rows={ mv_rows }; columns={ mv_columns }; row_mode={ mv_row_mode }; column_mode={ mv_column_mode }; border={ mv_border }| ).
  ENDMETHOD.

  METHOD set_column_mode.
    mv_column_mode = mode.
    result = mode.
    cl_gui_control=>set_payload( control = me
                                 payload = |rows={ mv_rows }; columns={ mv_columns }; row_mode={ mv_row_mode }; column_mode={ mv_column_mode }; border={ mv_border }| ).
  ENDMETHOD.

  METHOD free.
    super->free( ).
  ENDMETHOD.

  METHOD get_container.
    READ TABLE mt_cells INTO DATA(ls_cell)
      WITH KEY row = row column = column.
    IF sy-subrc = 0.
      container = ls_cell-container.
    ENDIF.
  ENDMETHOD.

  METHOD set_column_width.
    DATA lv_minimum TYPE i.
    DATA lv_width TYPE i.
    IF id < 1 OR id > mv_columns.
      result = 0.
      RETURN.
    ENDIF.
    READ TABLE mt_column_minimums INTO lv_minimum INDEX id.
    lv_width = COND #( WHEN width < lv_minimum THEN lv_minimum ELSE width ).
    MODIFY mt_column_widths FROM lv_width INDEX id.
    result = lv_width.
    cl_gui_control=>set_payload( control = me
                                 payload = |rows={ mv_rows }; columns={ mv_columns }; row_mode={ mv_row_mode }; column_mode={ mv_column_mode }; border={ mv_border }| ).
  ENDMETHOD.

  METHOD set_border.
    mv_border = border.
    cl_gui_control=>set_payload( control = me
                                 payload = |rows={ mv_rows }; columns={ mv_columns }; row_mode={ mv_row_mode }; column_mode={ mv_column_mode }; border={ mv_border }| ).
  ENDMETHOD.

ENDCLASS.
