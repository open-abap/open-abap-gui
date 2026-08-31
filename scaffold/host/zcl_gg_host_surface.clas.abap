CLASS zcl_gg_host_surface DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_surface_action,
             transport TYPE string,
             value     TYPE string,
             label     TYPE string,
             disabled  TYPE abap_bool,
           END OF ty_surface_action.
    TYPES ty_surface_actions TYPE STANDARD TABLE OF ty_surface_action WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_surface_row,
             cell1      TYPE string,
             cell2      TYPE string,
             cell3      TYPE string,
             row_header TYPE abap_bool,
           END OF ty_surface_row.
    TYPES ty_surface_rows TYPE STANDARD TABLE OF ty_surface_row WITH DEFAULT KEY.
    TYPES ty_surface_columns TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_surface_node,
             text     TYPE string,
             level    TYPE i,
             node_key TYPE string,
             expanded TYPE abap_bool,
             hidden   TYPE abap_bool,
           END OF ty_surface_node.
    TYPES ty_surface_nodes TYPE STANDARD TABLE OF ty_surface_node WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_surface,
             kind          TYPE string,
             aria_label    TYPE string,
             title         TYPE string,
             text          TYPE string,
             criteria      TYPE string,
             link_label    TYPE string,
             link_href     TYPE string,
             input_label   TYPE string,
             input_name    TYPE string,
             input_value   TYPE string,
             table_caption TYPE string,
             columns       TYPE ty_surface_columns,
             rows          TYPE ty_surface_rows,
             nodes         TYPE ty_surface_nodes,
             token_label   TYPE string,
             token_value   TYPE string,
             data_value    TYPE string,
             control_id    TYPE string,
             payload       TYPE string,
             actions       TYPE ty_surface_actions,
           END OF ty_surface.
    TYPES ty_surfaces TYPE STANDARD TABLE OF ty_surface WITH DEFAULT KEY.

    CONSTANTS surface_document      TYPE string VALUE 'DOCUMENT'.
    CONSTANTS surface_event_document TYPE string VALUE 'EVENT_DOCUMENT'.
    CONSTANTS surface_alert          TYPE string VALUE 'ALERT'.
    CONSTANTS surface_table          TYPE string VALUE 'TABLE'.
    CONSTANTS surface_tree           TYPE string VALUE 'TREE'.
    CONSTANTS surface_caption        TYPE string VALUE 'CAPTION'.
    CONSTANTS surface_chart          TYPE string VALUE 'CHART'.
    CONSTANTS surface_salv_layout    TYPE string VALUE 'SALV_LAYOUT'.
    CONSTANTS surface_cockpit        TYPE string VALUE 'COCKPIT'.
    CONSTANTS surface_action_ucomm   TYPE string VALUE 'UCOMM'.
    CONSTANTS surface_action_command TYPE string VALUE 'COMMAND'.

    CLASS-METHODS set_surface
      IMPORTING
        is_surface TYPE ty_surface.

    CLASS-METHODS clear.

  PRIVATE SECTION.
    CLASS-DATA mt_surfaces TYPE ty_surfaces.

    CLASS-METHODS escape
      IMPORTING
        text          TYPE string
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS safe_url
      IMPORTING
        text          TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS render_surfaces
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS render_surface
      IMPORTING
        is_surface    TYPE ty_surface
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS render_actions
      IMPORTING
        it_actions    TYPE ty_surface_actions
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS render_rows
      IMPORTING
        it_rows       TYPE ty_surface_rows
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS render_table
      IMPORTING
        is_surface    TYPE ty_surface
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS render_tree
      IMPORTING
        is_surface    TYPE ty_surface
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS render_chart
      IMPORTING
        is_surface    TYPE ty_surface
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS render_salv_layout
      IMPORTING
        is_surface    TYPE ty_surface
      RETURNING
        VALUE(result) TYPE string.
ENDCLASS.

CLASS zcl_gg_host_surface IMPLEMENTATION.

  METHOD set_surface.
    CASE is_surface-kind.
      WHEN surface_document OR surface_event_document OR surface_alert
          OR surface_table OR surface_tree OR surface_caption OR surface_chart
          OR surface_salv_layout OR surface_cockpit.
        APPEND is_surface TO mt_surfaces.
        cl_gui_control=>set_external_html( render_surfaces( ) ).
      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD clear.
    CLEAR mt_surfaces.
    cl_gui_control=>clear_external_html( ).
  ENDMETHOD.

  METHOD escape.
    result = text.
    REPLACE ALL OCCURRENCES OF '&' IN result WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<' IN result WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>' IN result WITH '&gt;'.
    REPLACE ALL OCCURRENCES OF '"' IN result WITH '&quot;'.
    REPLACE ALL OCCURRENCES OF '''' IN result WITH '&#39;'.
  ENDMETHOD.

  METHOD safe_url.
    DATA(lv_text) = to_lower( text ).
    IF lv_text CP '//*'.
      result = abap_false.
      RETURN.
    ENDIF.
    result = xsdbool( lv_text CP 'http://*'
      OR lv_text CP 'https://*'
      OR lv_text CP '/*' ).
  ENDMETHOD.

  METHOD render_surfaces.
    LOOP AT mt_surfaces INTO DATA(ls_surface).
      result = result && render_surface( ls_surface ).
    ENDLOOP.
  ENDMETHOD.

  METHOD render_actions.
    LOOP AT it_actions INTO DATA(ls_action).
      DATA(lv_name) = 'gg_action'.
      DATA(lv_value) = |COMMAND:{ ls_action-value }|.
      DATA(lv_disabled) = COND string(
        WHEN ls_action-disabled = abap_true THEN ' disabled' ELSE '' ).
      result = result && |<button type="submit" name="{ escape( lv_name ) }" value="{ escape( lv_value ) }"{ lv_disabled }>{ escape( ls_action-label ) }</button>|.
    ENDLOOP.
  ENDMETHOD.

  METHOD render_rows.
    LOOP AT it_rows INTO DATA(ls_row).
      result = result && '<tr>'.
      IF ls_row-row_header = abap_true.
        result = result && |<th scope="row">{ escape( ls_row-cell1 ) }</th>|.
      ELSE.
        result = result && |<td>{ escape( ls_row-cell1 ) }</td>|.
      ENDIF.
      IF ls_row-cell2 IS NOT INITIAL.
        result = result && |<td>{ escape( ls_row-cell2 ) }</td>|.
      ENDIF.
      IF ls_row-cell3 IS NOT INITIAL.
        result = result && |<td>{ escape( ls_row-cell3 ) }</td>|.
      ENDIF.
      result = result && '</tr>'.
    ENDLOOP.
  ENDMETHOD.

  METHOD render_table.
    result = |<section class="gg-structured-table" aria-label="{ escape( is_surface-aria_label ) }"><table><caption>{ escape( is_surface-table_caption ) }</caption><thead><tr>|.
    LOOP AT is_surface-columns INTO DATA(lv_column).
      result = result && |<th scope="col">{ escape( lv_column ) }</th>|.
    ENDLOOP.
    result = result && |</tr></thead><tbody>{ render_rows( is_surface-rows ) }</tbody></table>|.
    IF is_surface-input_name IS NOT INITIAL.
      result = result && |<label>{ escape( is_surface-input_label ) } <input name="{ escape( is_surface-input_name ) }" value="{ escape( is_surface-input_value ) }" inputmode="numeric"></label>|.
    ENDIF.
    IF is_surface-text IS NOT INITIAL.
      result = result && |<p>{ escape( is_surface-text ) }</p>|.
    ENDIF.
    IF is_surface-criteria IS NOT INITIAL.
      result = result && |<p data-criteria="server-owned">{ escape( is_surface-criteria ) }</p>|.
    ENDIF.
    IF is_surface-data_value IS NOT INITIAL.
      result = result && |<p data-aggregation="total">{ escape( is_surface-data_value ) }</p>|.
    ENDIF.
    IF is_surface-token_value IS NOT INITIAL.
      result = result && |<p>{ escape( is_surface-token_label ) }: <code>{ escape( is_surface-token_value ) }</code></p>|.
    ENDIF.
    result = result && render_actions( is_surface-actions ) && '</section>'.
  ENDMETHOD.

  METHOD render_tree.
    result = |<section class="gg-tree-fallback" aria-label="{ escape( is_surface-aria_label ) }"><ul role="tree" aria-label="{ escape( is_surface-aria_label ) }">|.
    LOOP AT is_surface-nodes INTO DATA(ls_node).
      DATA(lv_level) = COND string(
        WHEN ls_node-level > 0 THEN | aria-level="{ ls_node-level }"| ELSE '' ).
      DATA(lv_key) = COND string(
        WHEN ls_node-node_key IS NOT INITIAL THEN | data-node-key="{ escape( ls_node-node_key ) }"| ELSE '' ).
      DATA(lv_expanded) = COND string(
        WHEN ls_node-expanded = abap_true THEN ' aria-expanded="true"' ELSE '' ).
      DATA(lv_hidden) = COND string(
        WHEN ls_node-hidden = abap_true THEN ' hidden' ELSE '' ).
      DATA(lv_tabindex) = COND string(
        WHEN ls_node-hidden = abap_true THEN '' ELSE ' tabindex="0"' ).
      result = result && |<li role="treeitem"{ lv_level }{ lv_key }{ lv_expanded }{ lv_hidden }{ lv_tabindex }>{ escape( ls_node-text ) }</li>|.
    ENDLOOP.
    result = result && |</ul>{ render_actions( is_surface-actions ) }|.
    IF is_surface-token_value IS NOT INITIAL.
      result = result && |<p>{ escape( is_surface-token_label ) }: <code>{ escape( is_surface-token_value ) }</code></p>|.
    ENDIF.
    result = result && '</section>'.
  ENDMETHOD.

  METHOD render_chart.
    result = |<section class="gg-chart-fallback" aria-label="{ escape( is_surface-aria_label ) }"><figure><figcaption>{ escape( is_surface-title ) }</figcaption><table><thead><tr>|.
    LOOP AT is_surface-columns INTO DATA(lv_column).
      result = result && |<th scope="col">{ escape( lv_column ) }</th>|.
    ENDLOOP.
    result = result && |</tr></thead><tbody>{ render_rows( is_surface-rows ) }</tbody></table>|.
    IF is_surface-payload IS NOT INITIAL.
      result = result && |<p data-chart-payload="{ escape( is_surface-payload ) }">Chart payload retained server-side.</p>|.
    ENDIF.
    result = result && '</figure></section>'.
  ENDMETHOD.

  METHOD render_surface.
    CASE is_surface-kind.
      WHEN surface_document OR surface_event_document.
        result = |<article aria-label="{ escape( is_surface-aria_label ) }"><h2>{ escape( is_surface-title ) }</h2>|.
        IF is_surface-text IS NOT INITIAL.
          result = result && |<p>{ escape( is_surface-text ) }</p>|.
        ENDIF.
        IF is_surface-link_href IS NOT INITIAL AND safe_url( is_surface-link_href ) = abap_true.
          result = result && |<a href="{ escape( is_surface-link_href ) }">{ escape( is_surface-link_label ) }</a>|.
        ENDIF.
        IF is_surface-input_name IS NOT INITIAL.
          result = result && |<label>{ escape( is_surface-input_label ) }<input aria-label="{ escape( is_surface-input_label ) }" name="{ escape( is_surface-input_name ) }" value="{ escape( is_surface-input_value ) }"></label>|.
        ENDIF.
        IF is_surface-rows IS NOT INITIAL.
          DATA(ls_document_table) = is_surface.
          ls_document_table-kind = surface_table.
          result = result && render_table( ls_document_table ).
        ENDIF.
        result = result && render_actions( is_surface-actions ) && '</article>'.
      WHEN surface_alert.
        result = |<div role="alert" data-control-id="{ escape( is_surface-control_id ) }">{ escape( is_surface-text ) }</div>|.
      WHEN surface_table.
        result = render_table( is_surface ).
      WHEN surface_tree.
        result = render_tree( is_surface ).
      WHEN surface_caption.
        result = |<p class="gg-alv-tree-caption">{ escape( is_surface-text ) }</p>|.
      WHEN surface_chart.
        result = render_chart( is_surface ).
      WHEN surface_salv_layout.
        result = render_salv_layout( is_surface ).
      WHEN surface_cockpit.
        result = |<section class="gg-cockpit" aria-label="{ escape( is_surface-aria_label ) }"><header><h2>{ escape( is_surface-title ) }</h2><p data-filter-carrier="{ escape( is_surface-data_value ) }">Carrier: { escape( is_surface-data_value ) }</p><p>As-of: { escape( is_surface-payload ) }</p></header><p>{ escape( is_surface-text ) }</p>{ render_actions( is_surface-actions ) }</section>|.
      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD render_salv_layout.
    DATA ls_table TYPE ty_surface.
    ls_table = is_surface.
    ls_table-kind = surface_table.
    result = |<section class="gg-salv-layout" aria-label="{ escape( is_surface-aria_label ) }"><header><h2>{ escape( is_surface-title ) }</h2><p>{ escape( is_surface-text ) }</p></header><div class="gg-salv-grid">{ render_table( ls_table ) }</div></section>|.
  ENDMETHOD.

ENDCLASS.
