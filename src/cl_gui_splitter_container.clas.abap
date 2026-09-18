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
    DATA mt_row_height_explicit TYPE STANDARD TABLE OF abap_bool WITH DEFAULT KEY.
    DATA mt_column_width_explicit TYPE STANDARD TABLE OF abap_bool WITH DEFAULT KEY.
    DATA mt_row_sash_movable TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA mt_row_sash_visible TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA mt_column_sash_movable TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA mt_column_sash_visible TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA mt_row_minimums TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA mt_column_minimums TYPE STANDARD TABLE OF i WITH DEFAULT KEY.
    DATA mt_cells TYPE ty_cells.
    METHODS normalize_row_heights.
    METHODS normalize_column_widths.
    METHODS sync_layout_payload.
ENDCLASS.

CLASS cl_gui_splitter_container IMPLEMENTATION.
  METHOD get_row_height.
    READ TABLE mt_row_heights INTO result INDEX id.
  ENDMETHOD.

  METHOD get_column_width.
    READ TABLE mt_column_widths INTO result INDEX id.
  ENDMETHOD.

  METHOD set_row_sash.
    IF id < 1 OR id > mv_rows.
      result = 0.
      RETURN.
    ENDIF.
    result = value.
    CASE type.
      WHEN type_movable.
        MODIFY mt_row_sash_movable FROM value INDEX id.
      WHEN type_sashvisible.
        MODIFY mt_row_sash_visible FROM value INDEX id.
    ENDCASE.
  ENDMETHOD.

  METHOD set_column_sash.
    IF id < 1 OR id > mv_columns.
      result = 0.
      RETURN.
    ENDIF.
    result = value.
    CASE type.
      WHEN type_movable.
        MODIFY mt_column_sash_movable FROM value INDEX id.
      WHEN type_sashvisible.
        MODIFY mt_column_sash_visible FROM value INDEX id.
    ENDCASE.
  ENDMETHOD.

  METHOD set_row_mode.
    DATA lv_default_height TYPE i VALUE 100.

    mv_row_mode = mode.
    IF mv_row_mode = mode_relative.
      normalize_row_heights( ).
    ELSE.
      LOOP AT mt_row_height_explicit INTO DATA(lv_explicit_height).
        IF lv_explicit_height = abap_false.
          MODIFY mt_row_heights FROM lv_default_height INDEX sy-tabix.
        ENDIF.
      ENDLOOP.
    ENDIF.
    result = mode.
    sync_layout_payload( ).
  ENDMETHOD.

  METHOD set_row_height.
    DATA lv_minimum TYPE i.
    DATA lv_height TYPE i.
    IF id < 1 OR id > mv_rows.
      result = 0.
      RETURN.
    ENDIF.
    READ TABLE mt_row_minimums INTO lv_minimum INDEX id.
    IF mv_row_mode = mode_relative.
      lv_height = COND #( WHEN height < 0 THEN 0
                          WHEN height > 100 THEN 100
                          ELSE height ).
    ELSE.
      lv_height = COND #( WHEN height < lv_minimum THEN lv_minimum ELSE height ).
    ENDIF.
    MODIFY mt_row_heights FROM lv_height INDEX id.
    IF mv_row_mode = mode_relative.
      MODIFY mt_row_height_explicit FROM abap_true INDEX id.
      normalize_row_heights( ).
    ENDIF.
    result = lv_height.
    sync_layout_payload( ).
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
      APPEND abap_false TO mt_row_height_explicit.
      APPEND true TO mt_row_sash_movable.
      APPEND true TO mt_row_sash_visible.
    ENDDO.
    DO mv_columns TIMES.
      APPEND 100 TO mt_column_widths.
      APPEND 24 TO mt_column_minimums.
      APPEND abap_false TO mt_column_width_explicit.
      APPEND true TO mt_column_sash_movable.
      APPEND true TO mt_column_sash_visible.
    ENDDO.
    normalize_row_heights( ).
    normalize_column_widths( ).
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
    sync_layout_payload( ).
  ENDMETHOD.

  METHOD set_column_mode.
    DATA lv_default_width TYPE i VALUE 100.

    mv_column_mode = mode.
    IF mv_column_mode = mode_relative.
      normalize_column_widths( ).
    ELSE.
      LOOP AT mt_column_width_explicit INTO DATA(lv_explicit_width).
        IF lv_explicit_width = abap_false.
          MODIFY mt_column_widths FROM lv_default_width INDEX sy-tabix.
        ENDIF.
      ENDLOOP.
    ENDIF.
    result = mode.
    sync_layout_payload( ).
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
    IF mv_column_mode = mode_relative.
      lv_width = COND #( WHEN width < 0 THEN 0
                         WHEN width > 100 THEN 100
                         ELSE width ).
    ELSE.
      lv_width = COND #( WHEN width < lv_minimum THEN lv_minimum ELSE width ).
    ENDIF.
    MODIFY mt_column_widths FROM lv_width INDEX id.
    IF mv_column_mode = mode_relative.
      MODIFY mt_column_width_explicit FROM abap_true INDEX id.
      normalize_column_widths( ).
    ENDIF.
    result = lv_width.
    sync_layout_payload( ).
  ENDMETHOD.

  METHOD set_border.
    mv_border = border.
    sync_layout_payload( ).
  ENDMETHOD.

  METHOD normalize_row_heights.
    DATA lv_fixed_total TYPE i.
    DATA lv_unset_weight_total TYPE i.
    DATA lv_unset_count TYPE i.
    DATA lv_last_unset TYPE i.
    DATA lv_remaining TYPE i.
    DATA lv_assigned TYPE i.

    LOOP AT mt_row_heights INTO DATA(lv_height).
      DATA(lv_index) = sy-tabix.
      READ TABLE mt_row_height_explicit INTO DATA(lv_explicit) INDEX lv_index.
      IF lv_explicit = abap_true.
        lv_fixed_total = lv_fixed_total + lv_height.
      ELSE.
        lv_unset_count = lv_unset_count + 1.
        lv_unset_weight_total = lv_unset_weight_total + lv_height.
        lv_last_unset = lv_index.
      ENDIF.
    ENDLOOP.
    IF lv_unset_count = 0.
      RETURN.
    ENDIF.
    lv_remaining = 100 - lv_fixed_total.
    IF lv_remaining < 0.
      lv_remaining = 0.
    ENDIF.
    LOOP AT mt_row_height_explicit INTO lv_explicit.
      DATA(lv_current_index) = sy-tabix.
      IF lv_explicit = abap_false.
        READ TABLE mt_row_heights INTO DATA(lv_old_height) INDEX lv_current_index.
        DATA(lv_new_height) = 0.
        IF lv_current_index = lv_last_unset.
          lv_new_height = lv_remaining - lv_assigned.
        ELSEIF lv_unset_weight_total > 0.
          lv_new_height = lv_remaining * lv_old_height / lv_unset_weight_total.
        ELSE.
          lv_new_height = lv_remaining / lv_unset_count.
        ENDIF.
        lv_assigned = lv_assigned + lv_new_height.
        MODIFY mt_row_heights FROM lv_new_height INDEX lv_current_index.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD normalize_column_widths.
    DATA lv_fixed_total TYPE i.
    DATA lv_unset_weight_total TYPE i.
    DATA lv_unset_count TYPE i.
    DATA lv_last_unset TYPE i.
    DATA lv_remaining TYPE i.
    DATA lv_assigned TYPE i.

    LOOP AT mt_column_widths INTO DATA(lv_width).
      DATA(lv_index) = sy-tabix.
      READ TABLE mt_column_width_explicit INTO DATA(lv_explicit) INDEX lv_index.
      IF lv_explicit = abap_true.
        lv_fixed_total = lv_fixed_total + lv_width.
      ELSE.
        lv_unset_count = lv_unset_count + 1.
        lv_unset_weight_total = lv_unset_weight_total + lv_width.
        lv_last_unset = lv_index.
      ENDIF.
    ENDLOOP.
    IF lv_unset_count = 0.
      RETURN.
    ENDIF.
    lv_remaining = 100 - lv_fixed_total.
    IF lv_remaining < 0.
      lv_remaining = 0.
    ENDIF.
    LOOP AT mt_column_width_explicit INTO lv_explicit.
      DATA(lv_current_index) = sy-tabix.
      IF lv_explicit = abap_false.
        READ TABLE mt_column_widths INTO DATA(lv_old_width) INDEX lv_current_index.
        DATA(lv_new_width) = 0.
        IF lv_current_index = lv_last_unset.
          lv_new_width = lv_remaining - lv_assigned.
        ELSEIF lv_unset_weight_total > 0.
          lv_new_width = lv_remaining * lv_old_width / lv_unset_weight_total.
        ELSE.
          lv_new_width = lv_remaining / lv_unset_count.
        ENDIF.
        lv_assigned = lv_assigned + lv_new_width.
        MODIFY mt_column_widths FROM lv_new_width INDEX lv_current_index.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD sync_layout_payload.
    DATA lv_row_heights TYPE string.
    DATA lv_column_widths TYPE string.

    LOOP AT mt_row_heights INTO DATA(lv_height).
      IF lv_row_heights IS NOT INITIAL.
        lv_row_heights = lv_row_heights && ','.
      ENDIF.
      lv_row_heights = lv_row_heights && |{ lv_height }|.
    ENDLOOP.
    LOOP AT mt_column_widths INTO DATA(lv_width).
      IF lv_column_widths IS NOT INITIAL.
        lv_column_widths = lv_column_widths && ','.
      ENDIF.
      lv_column_widths = lv_column_widths && |{ lv_width }|.
    ENDLOOP.
    cl_gui_control=>set_payload(
      control = me
      payload = |rows={ mv_rows }; columns={ mv_columns }; row_mode={ mv_row_mode }; column_mode={ mv_column_mode }; border={ mv_border }; row_heights={ lv_row_heights }; column_widths={ lv_column_widths };| ).
  ENDMETHOD.

ENDCLASS.
