CLASS cl_gui_column_tree DEFINITION PUBLIC INHERITING FROM cl_item_tree_control.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        parent                TYPE REF TO cl_gui_container
        node_selection_mode   TYPE i
        item_selection        TYPE abap_bool
        hierarchy_column_name TYPE clike
        hierarchy_header      TYPE treev_hhdr.

    METHODS hierarchy_header_set_text
      IMPORTING
        text TYPE tv_heading
      EXCEPTIONS
        failed
        cntl_system_error.

    METHODS hierarchy_header_set_tooltip
      IMPORTING
        tooltip TYPE any
      EXCEPTIONS
        failed
        cntl_system_error.

    METHODS hierarchy_header_set_width
      IMPORTING
        width     TYPE i
        width_pix TYPE abap_bool OPTIONAL
      EXCEPTIONS
        failed
        cntl_system_error.

    METHODS column_set_hidden
      IMPORTING
        column_name TYPE tv_itmname
        hidden      TYPE abap_bool
      EXCEPTIONS
        failed
        column_not_found
        cntl_system_error.

    METHODS add_column
      IMPORTING
        name           TYPE clike
        hidden         TYPE abap_bool OPTIONAL
        disabled       TYPE abap_bool OPTIONAL
        alignment      TYPE i OPTIONAL
        width          TYPE i
        width_pix      TYPE abap_bool OPTIONAL
        header_image   TYPE clike OPTIONAL
        header_text    TYPE clike
        header_tooltip TYPE clike OPTIONAL
      EXCEPTIONS
        column_exists
        illegal_column_name
        too_many_columns
        illegal_alignment
        different_column_types
        cntl_system_error
        failed
        predecessor_column_not_found.

    METHODS hierarchy_header_get_width
      IMPORTING
        width_pix TYPE abap_bool DEFAULT abap_true
      EXPORTING
        width     TYPE i.

    METHODS column_get_width
      IMPORTING
        column_name TYPE any
        width_pix   TYPE abap_bool DEFAULT abap_true
      EXPORTING
        width       TYPE i.

    METHODS adjust_column_width
      IMPORTING
        start_column    TYPE any OPTIONAL
        end_column      TYPE any OPTIONAL
        all_columns     TYPE abap_bool OPTIONAL
        include_heading TYPE abap_bool OPTIONAL.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_column,
             name         TYPE string,
             hidden       TYPE abap_bool,
             disabled     TYPE abap_bool,
             alignment    TYPE i,
             width        TYPE i,
             header_image TYPE string,
             header_text  TYPE string,
             tooltip      TYPE string,
           END OF ty_column.
    TYPES ty_columns TYPE STANDARD TABLE OF ty_column WITH DEFAULT KEY.
    DATA mt_columns TYPE ty_columns.
    DATA ms_hierarchy_header TYPE treev_hhdr.

    METHODS refresh_column_html.
ENDCLASS.

CLASS cl_gui_column_tree IMPLEMENTATION.
  METHOD hierarchy_header_set_width.
    ms_hierarchy_header-width = width.
    ms_hierarchy_header-width_pix = COND #( WHEN width_pix = abap_true THEN 'X' ELSE ' ' ).
    READ TABLE mt_columns ASSIGNING FIELD-SYMBOL(<column>) INDEX 1.
    IF sy-subrc = 0.
      <column>-width = width.
    ENDIF.
    refresh_column_html( ).
  ENDMETHOD.

  METHOD hierarchy_header_set_tooltip.
    ms_hierarchy_header-tooltip = CONV #( tooltip ).
    READ TABLE mt_columns ASSIGNING FIELD-SYMBOL(<column>) INDEX 1.
    IF sy-subrc = 0.
      <column>-tooltip = CONV string( tooltip ).
    ENDIF.
    refresh_column_html( ).
  ENDMETHOD.

  METHOD hierarchy_header_set_text.
    ms_hierarchy_header-heading = text.
    READ TABLE mt_columns ASSIGNING FIELD-SYMBOL(<column>) INDEX 1.
    IF sy-subrc = 0.
      <column>-header_text = CONV string( text ).
    ENDIF.
    refresh_column_html( ).
  ENDMETHOD.

  METHOD column_set_hidden.
    READ TABLE mt_columns ASSIGNING FIELD-SYMBOL(<column>)
      WITH KEY name = CONV string( column_name ).
    IF sy-subrc = 0.
      <column>-hidden = hidden.
      refresh_column_html( ).
    ENDIF.
  ENDMETHOD.

  METHOD adjust_column_width.
    FIELD-SYMBOLS <column> TYPE ty_column.
    LOOP AT mt_columns ASSIGNING <column>.
      IF all_columns = abap_true
          OR ( start_column IS SUPPLIED AND <column>-name >= CONV string( start_column ) )
          OR ( end_column IS SUPPLIED AND <column>-name <= CONV string( end_column ) ).
        <column>-width = COND #( WHEN include_heading = abap_true
                                  AND strlen( <column>-header_text ) > 0
                                 THEN strlen( <column>-header_text ) * 8
                                 ELSE COND #( WHEN <column>-width > 0 THEN <column>-width ELSE 80 ) ).
      ENDIF.
    ENDLOOP.
    refresh_column_html( ).
  ENDMETHOD.

  METHOD column_get_width.
    READ TABLE mt_columns INTO DATA(ls_column)
      WITH KEY name = CONV string( column_name ).
    IF sy-subrc = 0.
      width = ls_column-width.
    ENDIF.
  ENDMETHOD.

  METHOD hierarchy_header_get_width.
    width = ms_hierarchy_header-width.
  ENDMETHOD.

  METHOD constructor.
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'COLUMN_TREE' ).
    ms_hierarchy_header = hierarchy_header.
    APPEND VALUE #( name         = CONV string( hierarchy_column_name )
                    width        = hierarchy_header-width
                    header_image = hierarchy_header-t_image
                    header_text  = hierarchy_header-heading
                    tooltip      = hierarchy_header-tooltip ) TO mt_columns.
    refresh_column_html( ).
    parent->add_child( me ).
  ENDMETHOD.

  METHOD free.
    super->free( ).
  ENDMETHOD.

  METHOD add_column.
    READ TABLE mt_columns TRANSPORTING NO FIELDS
      WITH KEY name = CONV string( name ).
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    APPEND VALUE #( name         = CONV string( name )
                    hidden       = hidden
                    disabled     = disabled
                    alignment    = alignment
                    width        = width
                    header_image = CONV string( header_image )
                    header_text  = CONV string( header_text )
                    tooltip      = CONV string( header_tooltip ) ) TO mt_columns.
    refresh_column_html( ).
  ENDMETHOD.

  METHOD set_registered_events.
    super->set_registered_events( events ).
  ENDMETHOD.

  METHOD refresh_column_html.
    DATA lv_heading TYPE string.
    DATA lv_width TYPE string.
    DATA lv_html TYPE string.

    lv_heading = ms_hierarchy_header-heading.
    IF lv_heading IS INITIAL.
      lv_heading = 'Hierarchy'.
    ENDIF.
    lv_html = |<table class="gg-column-tree" aria-label="Column tree"><thead><tr>|.
    LOOP AT mt_columns INTO DATA(ls_column) WHERE hidden = abap_false.
      DATA(lv_column_heading) = ls_column-header_text.
      IF lv_column_heading IS INITIAL.
        lv_column_heading = ls_column-name.
      ENDIF.
      lv_width = COND string( WHEN ls_column-width > 0 THEN | style="width:{ ls_column-width }px"| ELSE `` ).
      lv_html = lv_html && |<th scope="col" data-column-name="{ escape_html( ls_column-name ) }"{ lv_width } title="{ escape_html( ls_column-tooltip ) }">{ escape_html( lv_column_heading ) }</th>|.
    ENDLOOP.
    lv_html = lv_html && |</tr></thead><tbody>|.
    LOOP AT mt_html_nodes INTO DATA(ls_node).
      lv_html = lv_html && |<tr data-node-key="{ escape_html( ls_node-node_key ) }"><th scope="row">{ escape_html( ls_node-text ) }</th>|.
      LOOP AT mt_columns INTO DATA(ls_extra_column) FROM 2 WHERE hidden = abap_false.
        lv_html = lv_html && |<td data-column-name="{ escape_html( ls_extra_column-name ) }"></td>|.
      ENDLOOP.
      lv_html = lv_html && |</tr>|.
    ENDLOOP.
    lv_html = lv_html && |</tbody></table>|.
    cl_gui_control=>set_html(
      control = me
      html    = lv_html ).
  ENDMETHOD.

ENDCLASS.
