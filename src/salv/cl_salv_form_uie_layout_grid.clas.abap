CLASS cl_salv_form_uie_layout_grid DEFINITION PUBLIC INHERITING FROM cl_salv_form_uie.
  PUBLIC SECTION.
    METHODS add_row
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_form_layout_flow.
  PROTECTED SECTION.
    TYPES: BEGIN OF ty_cell,
             row     TYPE i,
             column  TYPE i,
             colspan TYPE i,
             rowspan TYPE i,
             element TYPE REF TO cl_salv_form_element,
           END OF ty_cell.
    DATA mt_cells TYPE STANDARD TABLE OF ty_cell WITH DEFAULT KEY.
    METHODS add_cell
      IMPORTING
        row     TYPE i
        column  TYPE i
        colspan TYPE i
        rowspan TYPE i DEFAULT 1
        element TYPE REF TO cl_salv_form_element.
    METHODS render_html REDEFINITION.
ENDCLASS.

CLASS cl_salv_form_uie_layout_grid IMPLEMENTATION.
  METHOD add_row.
    DATA lv_row TYPE i.

    LOOP AT mt_cells INTO DATA(ls_cell).
      lv_row = nmax( val1 = lv_row
                     val2 = ls_cell-row ).
    ENDLOOP.
    value = NEW #( ).
    add_cell( row     = lv_row + 1
              column  = 1
              colspan = 0
              element = value ).
  ENDMETHOD.

  METHOD add_cell.
    DATA(lv_row) = nmax( val1 = row
                         val2 = 1 ).
    DATA(lv_column) = nmax( val1 = column
                            val2 = 1 ).
    DELETE mt_cells WHERE row = lv_row AND column = lv_column.
    APPEND VALUE #( row     = lv_row
                    column  = lv_column
                    colspan = colspan
                    rowspan = rowspan
                    element = element ) TO mt_cells.
    SORT mt_cells BY row column.
  ENDMETHOD.

  METHOD render_html.
    DATA lv_row TYPE i.
    DATA lv_align TYPE string.
    DATA lo_uie TYPE REF TO cl_salv_form_uie.
    DATA lo_layout TYPE REF TO cl_salv_form_layout_data_grid.
    DATA lv_h_align TYPE i.

    LOOP AT mt_cells INTO DATA(ls_cell).
      IF ls_cell-row <> lv_row.
        IF lv_row <> 0.
          result = result && '</tr>'.
        ENDIF.
        lv_row = ls_cell-row.
        result = result && '<tr>'.
      ENDIF.
      DATA(lv_colspan) = COND string( WHEN ls_cell-colspan > 1 THEN | colspan="{ ls_cell-colspan }"| ).
      DATA(lv_rowspan) = COND string( WHEN ls_cell-rowspan > 1 THEN | rowspan="{ ls_cell-rowspan }"| ).

      CLEAR lv_align.
      CLEAR: lo_uie, lo_layout.
      TRY.
          lo_uie ?= ls_cell-element.
          IF lo_uie IS BOUND.
            lo_layout ?= lo_uie->get_layout_data( ).
          ENDIF.
          IF lo_layout IS BOUND.
            lv_h_align = lo_layout->get_h_align( ).
            lv_align = SWITCH #( lv_h_align WHEN 2 THEN 'center' WHEN 3 THEN 'right' ELSE 'left' ).
          ENDIF.
        CATCH cx_sy_move_cast_error.
          CLEAR lv_align.
      ENDTRY.
      result = result && |<td{ lv_colspan }{ lv_rowspan }{ COND string( WHEN lv_align IS NOT INITIAL THEN | style="text-align:{ lv_align }"| ) }>{ ls_cell-element->render_html( ) }</td>|.
    ENDLOOP.
    IF lv_row <> 0.
      result = result && '</tr>'.
    ENDIF.
    result = |<table class="gg-salv-form-grid" role="presentation">{ result }</table>|.
  ENDMETHOD.
ENDCLASS.
