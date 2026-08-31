CLASS cl_gui_control DEFINITION PUBLIC INHERITING FROM cl_gui_object.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_snapshot,
             control_id TYPE string,
             parent_id  TYPE string,
             kind       TYPE string,
             left       TYPE i,
             top        TYPE i,
             width      TYPE i,
             height     TYPE i,
             enabled    TYPE abap_bool,
             visible    TYPE abap_bool,
             focused    TYPE abap_bool,
             payload    TYPE string,
             html       TYPE string,
             buttons    TYPE ttb_button,
           END OF ty_snapshot.
    TYPES ty_snapshots TYPE STANDARD TABLE OF ty_snapshot WITH DEFAULT KEY.

    DATA parent TYPE REF TO cl_gui_container.
    DATA control_id TYPE string.
    DATA mv_width TYPE i.
    DATA mv_height TYPE i.
    DATA mv_left TYPE i.
    DATA mv_top TYPE i.
    DATA mv_enabled TYPE abap_bool.
    DATA mv_visible TYPE abap_bool.
    DATA mv_alive TYPE abap_bool.
    DATA mv_kind TYPE string.

    CONSTANTS align_at_bottom TYPE i VALUE 8.
    CONSTANTS align_at_left TYPE i VALUE 1.
    CONSTANTS align_at_right TYPE i VALUE 2.
    CONSTANTS align_at_top TYPE i VALUE 4.
    CONSTANTS ws_clipsiblings TYPE i VALUE 67108864.
    CONSTANTS lifetime_default TYPE i VALUE 0.
    CONSTANTS lifetime_dynpro TYPE i VALUE 1.
    CONSTANTS lifetime_imode TYPE i VALUE 2.
    CONSTANTS mode_run TYPE i VALUE 0.
    CONSTANTS mode_design TYPE i VALUE 1.
    CONSTANTS metric_default TYPE i VALUE 0.
    CONSTANTS metric_pixel TYPE i VALUE 1.
    CONSTANTS metric_mm TYPE i VALUE 2.
    CONSTANTS state_alive TYPE i VALUE 0.
    CONSTANTS state_alive_on_other_screen TYPE i VALUE 1.
    CONSTANTS state_dead TYPE i VALUE -1.

    CLASS-METHODS initialize
      IMPORTING
        control TYPE REF TO cl_gui_control
        parent  TYPE REF TO cl_gui_container OPTIONAL
        kind    TYPE string DEFAULT 'CONTROL'.

    CLASS-METHODS get_snapshots
      RETURNING
        VALUE(result) TYPE ty_snapshots.

    CLASS-METHODS render_html
      IMPORTING
        iv_document   TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS has_content
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS clear.

    CLASS-METHODS set_external_html
      IMPORTING
        html TYPE string.

    CLASS-METHODS clear_external_html.

    CLASS-METHODS escape_html
      IMPORTING
        text          TYPE string
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS set_focus
      IMPORTING
        control TYPE REF TO cl_gui_control.

    METHODS get_width
      EXPORTING
        width TYPE i
      EXCEPTIONS
        cntl_error.

    METHODS set_width
      IMPORTING
        width TYPE i
      EXCEPTIONS
        cntl_error.

    METHODS set_height
      IMPORTING
        height TYPE i
      EXCEPTIONS
        cntl_error.

    METHODS set_enable
      IMPORTING
        enable TYPE c.

    METHODS set_visible
      IMPORTING
        visible TYPE c.

    METHODS set_registered_events
      IMPORTING
        events TYPE any.

    CLASS-METHODS get_focus
      EXPORTING
        control TYPE REF TO cl_gui_control.

    METHODS free.

    METHODS set_alignment
      IMPORTING
        alignment TYPE i.

    METHODS get_height
      EXPORTING
        height TYPE i
      EXCEPTIONS
        cntl_error.

    METHODS set_position
      IMPORTING
        height TYPE i OPTIONAL
        left   TYPE i OPTIONAL
        top    TYPE i OPTIONAL
        width  TYPE i OPTIONAL
      EXCEPTIONS
        cntl_error
        cntl_system_error.

  PROTECTED SECTION.
    CLASS-METHODS set_payload
      IMPORTING
        control TYPE REF TO cl_gui_control
        payload TYPE string.
    CLASS-METHODS set_html
      IMPORTING
        control TYPE REF TO cl_gui_control
        html    TYPE string.
    CLASS-METHODS set_buttons
      IMPORTING
        control TYPE REF TO cl_gui_control
        buttons TYPE ttb_button.

  PRIVATE SECTION.
    CLASS-DATA mv_next_id TYPE i.
    CLASS-DATA mo_focus TYPE REF TO cl_gui_control.
    CLASS-DATA mt_snapshots TYPE ty_snapshots.
    CLASS-DATA mv_external_html TYPE string.
    CLASS-METHODS sync
      IMPORTING
        control TYPE REF TO cl_gui_control.
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
ENDCLASS.

CLASS cl_gui_control IMPLEMENTATION.

  METHOD initialize.
    DATA ls_snapshot TYPE ty_snapshot.

    IF control->control_id IS INITIAL.
      mv_next_id = mv_next_id + 1.
      control->control_id = |GUI-{ mv_next_id }|.
      control->mv_enabled = abap_true.
      control->mv_visible = abap_true.
      control->mv_alive = abap_true.
    ENDIF.
    control->parent = parent.
    control->mv_kind = kind.
    ls_snapshot-control_id = control->control_id.
    IF parent IS BOUND.
      ls_snapshot-parent_id = parent->control_id.
    ENDIF.
    ls_snapshot-kind = kind.
    ls_snapshot-width = control->mv_width.
    ls_snapshot-height = control->mv_height.
    ls_snapshot-left = control->mv_left.
    ls_snapshot-top = control->mv_top.
    ls_snapshot-enabled = control->mv_enabled.
    ls_snapshot-visible = control->mv_visible.
    DELETE mt_snapshots WHERE control_id = control->control_id.
    APPEND ls_snapshot TO mt_snapshots.
  ENDMETHOD.

  METHOD sync.
    READ TABLE mt_snapshots INTO DATA(ls_snapshot)
      WITH KEY control_id = control->control_id.
    IF sy-subrc = 0.
      ls_snapshot-width = control->mv_width.
      ls_snapshot-height = control->mv_height.
      ls_snapshot-left = control->mv_left.
      ls_snapshot-top = control->mv_top.
      ls_snapshot-enabled = control->mv_enabled.
      ls_snapshot-visible = control->mv_visible.
      ls_snapshot-focused = xsdbool( mo_focus = control ).
      MODIFY mt_snapshots FROM ls_snapshot INDEX sy-tabix.
    ENDIF.
  ENDMETHOD.

  METHOD set_payload.
    READ TABLE mt_snapshots INTO DATA(ls_snapshot)
      WITH KEY control_id = control->control_id.
    IF sy-subrc = 0.
      ls_snapshot-payload = payload.
      MODIFY mt_snapshots FROM ls_snapshot INDEX sy-tabix.
    ENDIF.
  ENDMETHOD.

  METHOD set_html.
    READ TABLE mt_snapshots INTO DATA(ls_snapshot)
      WITH KEY control_id = control->control_id.
    IF sy-subrc = 0.
      ls_snapshot-html = html.
      MODIFY mt_snapshots FROM ls_snapshot INDEX sy-tabix.
    ENDIF.
  ENDMETHOD.

  METHOD escape_html.
    result = escape( text ).
  ENDMETHOD.

  METHOD set_buttons.
    READ TABLE mt_snapshots INTO DATA(ls_snapshot)
      WITH KEY control_id = control->control_id.
    IF sy-subrc = 0.
      ls_snapshot-buttons = buttons.
      MODIFY mt_snapshots FROM ls_snapshot INDEX sy-tabix.
    ENDIF.
  ENDMETHOD.

  METHOD get_snapshots.
    result = mt_snapshots.
  ENDMETHOD.

  METHOD has_content.
    result = xsdbool( mt_snapshots IS NOT INITIAL
      OR mv_external_html IS NOT INITIAL ).
  ENDMETHOD.

  METHOD clear.
    CLEAR: mv_next_id, mo_focus, mt_snapshots, mv_external_html.
  ENDMETHOD.

  METHOD set_external_html.
    mv_external_html = html.
  ENDMETHOD.

  METHOD clear_external_html.
    CLEAR mv_external_html.
  ENDMETHOD.

  METHOD render_html.
    IF iv_document = abap_true.
      result = |<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>GUI controls</title><style>.gg-control\{position:absolute;box-sizing:border-box\}.gg-controls\{position:relative;min-height:240px\}.gg-control[hidden]\{display:none\}button:focus-visible,input:focus-visible,select:focus-visible,textarea:focus-visible,a:focus-visible,[tabindex="0"]:focus-visible\{outline:2px solid #2668a3;outline-offset:2px\}</style></head><body><main class="gg-controls" aria-label="GUI controls">|.
    ELSE.
      result = |<section class="gg-controls" aria-label="GUI controls">|.
    ENDIF.
    LOOP AT mt_snapshots INTO DATA(ls_snapshot).
      DATA(lv_style) = |left:{ ls_snapshot-left }px;top:{ ls_snapshot-top }px;|.
      IF ls_snapshot-width > 0.
        lv_style = lv_style && |width:{ ls_snapshot-width }px;|.
      ENDIF.
      IF ls_snapshot-height > 0.
        lv_style = lv_style && |height:{ ls_snapshot-height }px;|.
      ENDIF.
      DATA(lv_hidden) = COND string( WHEN ls_snapshot-visible = abap_false THEN ' hidden' ELSE '' ).
      DATA(lv_disabled) = COND string( WHEN ls_snapshot-enabled = abap_false THEN ' disabled' ELSE '' ).
      CASE ls_snapshot-kind.
        WHEN 'CUSTOM_CONTAINER' OR 'DOCKING_CONTAINER' OR 'DIALOGBOX_CONTAINER'
            OR 'SPLITTER_CONTAINER' OR 'EASY_SPLITTER'.
          result = result && |<section class="gg-control gg-container" style="{ lv_style }" id="{ escape( ls_snapshot-control_id ) }" data-control-kind="{ escape( ls_snapshot-kind ) }" role="region" aria-label="{ escape( ls_snapshot-kind ) }"{ lv_hidden }>{ escape( ls_snapshot-payload ) }{ ls_snapshot-html }</section>|.
        WHEN 'ALV_GRID' OR 'ALV_TREE' OR 'SIMPLE_TREE' OR 'LIST_TREE' OR 'COLUMN_TREE'.
          result = result && |<div class="gg-control" style="{ lv_style }" id="{ escape( ls_snapshot-control_id ) }" data-control-kind="{ escape( ls_snapshot-kind ) }"{ lv_hidden }{ lv_disabled }>{ ls_snapshot-html }{ escape( ls_snapshot-payload ) }</div>|.
        WHEN 'TOOLBAR'.
          result = result && |<div class="gg-control" style="{ lv_style }" id="{ escape( ls_snapshot-control_id ) }" role="toolbar"{ lv_hidden }>|.
          LOOP AT ls_snapshot-buttons INTO DATA(ls_button).
            result = result && |<button type="submit" name="gg_action" value="COMMAND:{ escape( CONV string( ls_button-function ) ) }" title="{ escape( CONV string( ls_button-quickinfo ) ) }"{ COND string( WHEN ls_button-disabled IS NOT INITIAL THEN ' disabled' ELSE '' ) }>{ escape( CONV string( ls_button-text ) ) }</button>|.
          ENDLOOP.
          result = result && |</div>|.
        WHEN 'TEXTEDIT'.
          result = result && |<textarea class="gg-control" style="{ lv_style }" id="{ escape( ls_snapshot-control_id ) }" name="{ escape( ls_snapshot-control_id ) }" data-control-kind="TEXTEDIT" aria-label="Text editor"{ lv_hidden }{ lv_disabled }>{ escape( ls_snapshot-payload ) }</textarea>|.
        WHEN 'PICTURE'.
          DATA(lv_url) = COND string( WHEN safe_url( ls_snapshot-payload ) = abap_true THEN escape( ls_snapshot-payload ) ELSE '' ).
          result = result && |<div class="gg-control" style="{ lv_style }" id="{ escape( ls_snapshot-control_id ) }" data-control-kind="PICTURE" role="img" aria-label="Picture"{ lv_hidden }><img src="{ lv_url }" alt="Picture"></div>|.
        WHEN 'HTML_VIEWER'.
          result = result && |<iframe class="gg-control" style="{ lv_style }" id="{ escape( ls_snapshot-control_id ) }" title="HTML viewer" sandbox=""{ lv_hidden } srcdoc="{ escape( ls_snapshot-payload ) }"></iframe>|.
        WHEN 'CALENDAR'.
          result = result && |<section class="gg-control" style="{ lv_style }" id="{ escape( ls_snapshot-control_id ) }" data-control-kind="CALENDAR" role="group" aria-label="Calendar"{ lv_hidden }>{ ls_snapshot-html }{ escape( ls_snapshot-payload ) }</section>|.
        WHEN 'SELECTOR'.
          result = result && |<select class="gg-control" style="{ lv_style }" id="{ escape( ls_snapshot-control_id ) }" name="{ escape( ls_snapshot-control_id ) }" data-control-kind="SELECTOR" aria-label="Selector"{ lv_hidden }{ lv_disabled }>{ COND string( WHEN ls_snapshot-html IS INITIAL THEN |<option>{ escape( ls_snapshot-payload ) }</option>| ELSE ls_snapshot-html ) }</select>|.
        WHEN 'BARCHART' OR 'CHART_ENGINE' OR 'GP_PRES'.
          result = result && |<figure class="gg-control gg-graphic" style="{ lv_style }" id="{ escape( ls_snapshot-control_id ) }" data-control-kind="{ escape( ls_snapshot-kind ) }" role="img" aria-label="{ escape( ls_snapshot-kind ) }"{ lv_hidden }>{ ls_snapshot-html }<figcaption>{ escape( ls_snapshot-payload ) }</figcaption></figure>|.
        WHEN OTHERS.
          result = result && |<div class="gg-control" style="{ lv_style }" id="{ escape( ls_snapshot-control_id ) }" data-control-kind="{ escape( ls_snapshot-kind ) }"{ lv_hidden }{ lv_disabled }>{ escape( ls_snapshot-payload ) }</div>|.
      ENDCASE.
    ENDLOOP.
    IF mv_external_html IS NOT INITIAL.
      result = result && |<section class="gg-external" aria-label="External GUI content">{ mv_external_html }</section>|.
    ENDIF.
    IF iv_document = abap_true.
      result = result && |</main></body></html>|.
    ELSE.
      result = result && |</section>|.
    ENDIF.
  ENDMETHOD.

  METHOD set_focus.
    mo_focus = control.
    LOOP AT mt_snapshots INTO DATA(ls_snapshot).
      ls_snapshot-focused = xsdbool( ls_snapshot-control_id = control->control_id ).
      MODIFY mt_snapshots FROM ls_snapshot INDEX sy-tabix.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_focus.
    control = mo_focus.
  ENDMETHOD.

  METHOD get_width.
    width = mv_width.
  ENDMETHOD.

  METHOD set_width.
    mv_width = width.
    sync( me ).
  ENDMETHOD.

  METHOD set_height.
    mv_height = height.
    sync( me ).
  ENDMETHOD.

  METHOD get_height.
    height = mv_height.
  ENDMETHOD.

  METHOD set_enable.
    mv_enabled = xsdbool( enable IS NOT INITIAL ).
    sync( me ).
  ENDMETHOD.

  METHOD set_visible.
    mv_visible = xsdbool( visible IS NOT INITIAL ).
    sync( me ).
  ENDMETHOD.

  METHOD set_registered_events.
    RETURN.
  ENDMETHOD.

  METHOD free.
    mv_alive = abap_false.
    mv_visible = abap_false.
    sync( me ).
  ENDMETHOD.

  METHOD set_alignment.
    RETURN.
  ENDMETHOD.

  METHOD set_position.
    IF height IS SUPPLIED.
      mv_height = height.
    ENDIF.
    IF left IS SUPPLIED.
      mv_left = left.
    ENDIF.
    IF top IS SUPPLIED.
      mv_top = top.
    ENDIF.
    IF width IS SUPPLIED.
      mv_width = width.
    ENDIF.
    sync( me ).
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

ENDCLASS.
