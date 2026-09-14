CLASS cl_gui_control DEFINITION PUBLIC INHERITING FROM cl_gui_object.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_field,
             name  TYPE string,
             value TYPE string,
           END OF ty_field.
    TYPES ty_fields TYPE STANDARD TABLE OF ty_field WITH DEFAULT KEY.

* How the caller wants a sapevent anchor inside an HTML viewer document to
* reach the server. SAP GUI turns such an anchor back into an ABAP event; a
* browser cannot, so the anchor is rewritten into a form that posts these
* fields plus the anchor's own action under action_field. The control framework
* knows nothing about the transport itself, only how to build the form.
    TYPES: BEGIN OF ty_sapevent,
             url          TYPE string,
             action_field TYPE string,
             fields       TYPE ty_fields,
           END OF ty_sapevent.

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

    CLASS-METHODS is_alive
      IMPORTING
        control       TYPE REF TO cl_gui_control
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS render_html
      IMPORTING
        iv_document       TYPE abap_bool DEFAULT abap_true
        iv_container_name TYPE string OPTIONAL
        is_sapevent       TYPE ty_sapevent OPTIONAL
      RETURNING
        VALUE(result)     TYPE string.

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

    METHODS is_valid REDEFINITION.

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
    CLASS-METHODS state_class
      IMPORTING
        iv_focused    TYPE abap_bool DEFAULT abap_false
        iv_selected   TYPE abap_bool DEFAULT abap_false
        iv_changed    TYPE abap_bool DEFAULT abap_false
        iv_disabled   TYPE abap_bool DEFAULT abap_false
        iv_required   TYPE abap_bool DEFAULT abap_false
        iv_error      TYPE abap_bool DEFAULT abap_false
        iv_warning    TYPE abap_bool DEFAULT abap_false
        iv_total      TYPE abap_bool DEFAULT abap_false
        iv_subtotal   TYPE abap_bool DEFAULT abap_false
        iv_hotspot    TYPE abap_bool DEFAULT abap_false
        iv_readonly   TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS format_external_value
      IMPORTING
        iv_value      TYPE string
        iv_type       TYPE string
      RETURNING
        VALUE(result) TYPE string.

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
    CLASS-METHODS set_sapevent
      IMPORTING
        control    TYPE REF TO cl_gui_control
        registered TYPE abap_bool.

    CLASS-METHODS set_text_state
      IMPORTING
        control           TYPE REF TO cl_gui_control
        toolbar_mode      TYPE abap_bool OPTIONAL
        statusbar_mode    TYPE abap_bool OPTIONAL
        wordwrap_mode     TYPE i OPTIONAL
        wordwrap_position TYPE i OPTIONAL
        wrap_to_linebreak TYPE i OPTIONAL
        fixed_font        TYPE i OPTIONAL
        modified          TYPE i OPTIONAL
        cursor_line       TYPE i OPTIONAL
        cursor_pos        TYPE i OPTIONAL
        protected_from    TYPE i OPTIONAL
        protected_to      TYPE i OPTIONAL
        readonly          TYPE abap_bool OPTIONAL.

    CLASS-METHODS set_picture_state
      IMPORTING
        control      TYPE REF TO cl_gui_control
        display_mode TYPE i OPTIONAL
        border       TYPE i OPTIONAL
        state        TYPE string OPTIONAL
        alt_text     TYPE string OPTIONAL.

  PRIVATE SECTION.
* The control registry row is internal: it is only read by this class, the
* render path, and nothing else. Keep the type private so no invented
* structure appears in a public section.
    TYPES: BEGIN OF ty_snapshot,
             control_id             TYPE string,
             parent_id              TYPE string,
             kind                   TYPE string,
             left                   TYPE i,
             top                    TYPE i,
             width                  TYPE i,
             height                 TYPE i,
             enabled                TYPE abap_bool,
             visible                TYPE abap_bool,
             focused                TYPE abap_bool,
             payload                TYPE string,
             html                   TYPE string,
             buttons                TYPE ttb_button,
             sapevent               TYPE abap_bool,
             text_toolbar_mode      TYPE abap_bool,
             text_statusbar_mode    TYPE abap_bool,
             text_wordwrap_mode     TYPE i,
             text_wordwrap_position TYPE i,
             text_wrap_to_linebreak TYPE i,
             text_fixed_font        TYPE i,
             text_modified          TYPE i,
             text_cursor_line       TYPE i,
             text_cursor_pos        TYPE i,
             text_protected_from    TYPE i,
             text_protected_to      TYPE i,
             text_readonly          TYPE abap_bool,
             picture_display_mode   TYPE i,
             picture_border         TYPE i,
             picture_state          TYPE string,
             picture_alt_text       TYPE string,
            END OF ty_snapshot.
    TYPES ty_snapshots TYPE STANDARD TABLE OF ty_snapshot WITH DEFAULT KEY.

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
    CLASS-METHODS rewrite_sapevent
      IMPORTING
        document      TYPE string
        sapevent      TYPE ty_sapevent
      RETURNING
        VALUE(result) TYPE string.
    CLASS-METHODS safe_url
      IMPORTING
        text          TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.
    CLASS-METHODS belongs_to_container
      IMPORTING
        iv_control_id TYPE string
        iv_host_id    TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.
    CLASS-METHODS render_control_html
      IMPORTING
        is_snapshot    TYPE ty_snapshot
        iv_style       TYPE string
        iv_hidden      TYPE string
        iv_disabled    TYPE string
        iv_state_class TYPE string
        is_sapevent    TYPE ty_sapevent OPTIONAL
      RETURNING
        VALUE(result)  TYPE string.
    CLASS-METHODS render_toolbar_html
      IMPORTING
        is_snapshot    TYPE ty_snapshot
        iv_style       TYPE string
        iv_hidden      TYPE string
        iv_state_class TYPE string
      RETURNING
        VALUE(result)  TYPE string.
    CLASS-METHODS render_textedit_html
      IMPORTING
        is_snapshot    TYPE ty_snapshot
        iv_style       TYPE string
        iv_hidden      TYPE string
        iv_disabled    TYPE string
        iv_state_class TYPE string
      RETURNING
        VALUE(result)  TYPE string.
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

  METHOD state_class.
    result = `gg-state`.
    IF iv_focused = abap_true.
      result = result && ` gg-state-focused`.
    ENDIF.
    IF iv_selected = abap_true.
      result = result && ` gg-state-selected`.
    ENDIF.
    IF iv_changed = abap_true.
      result = result && ` gg-state-changed`.
    ENDIF.
    IF iv_disabled = abap_true.
      result = result && ` gg-state-disabled`.
    ENDIF.
    IF iv_required = abap_true.
      result = result && ` gg-state-required`.
    ENDIF.
    IF iv_error = abap_true.
      result = result && ` gg-state-error`.
    ENDIF.
    IF iv_warning = abap_true.
      result = result && ` gg-state-warning`.
    ENDIF.
    IF iv_total = abap_true.
      result = result && ` gg-state-total`.
    ENDIF.
    IF iv_subtotal = abap_true.
      result = result && ` gg-state-subtotal`.
    ENDIF.
    IF iv_hotspot = abap_true.
      result = result && ` gg-state-hotspot`.
    ENDIF.
    IF iv_readonly = abap_true.
      result = result && ` gg-state-readonly`.
    ENDIF.
  ENDMETHOD.

  METHOD format_external_value.
    DATA lv_first TYPE string.
    DATA lv_second TYPE string.
    DATA lv_third TYPE string.

    result = iv_value.
    CASE to_upper( iv_type ).
      WHEN 'D'.
        IF strlen( iv_value ) = 8 AND iv_value CO '0123456789'.
          lv_first = substring(
            val = iv_value
            off = 6
            len = 2 ).
          lv_second = substring(
            val = iv_value
            off = 4
            len = 2 ).
          lv_third = substring(
            val = iv_value
            off = 0
            len = 4 ).
          result = |{ lv_first }.{ lv_second }.{ lv_third }|.
        ENDIF.
      WHEN 'T'.
        IF strlen( iv_value ) = 6 AND iv_value CO '0123456789'.
          lv_first = substring(
            val = iv_value
            off = 0
            len = 2 ).
          lv_second = substring(
            val = iv_value
            off = 2
            len = 2 ).
          lv_third = substring(
            val = iv_value
            off = 4
            len = 2 ).
          result = |{ lv_first }:{ lv_second }:{ lv_third }|.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD set_buttons.
    READ TABLE mt_snapshots INTO DATA(ls_snapshot)
      WITH KEY control_id = control->control_id.
    IF sy-subrc = 0.
      ls_snapshot-buttons = buttons.
      MODIFY mt_snapshots FROM ls_snapshot INDEX sy-tabix.
    ENDIF.
  ENDMETHOD.

  METHOD set_sapevent.
    READ TABLE mt_snapshots INTO DATA(ls_snapshot)
      WITH KEY control_id = control->control_id.
    IF sy-subrc = 0.
      ls_snapshot-sapevent = registered.
      MODIFY mt_snapshots FROM ls_snapshot INDEX sy-tabix.
    ENDIF.
  ENDMETHOD.

  METHOD is_alive.
    IF control IS NOT BOUND.
      RETURN.
    ENDIF.
    READ TABLE mt_snapshots TRANSPORTING NO FIELDS
      WITH KEY control_id = control->control_id.
    result = xsdbool( sy-subrc = 0 ).
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
    DATA lv_state_class TYPE string.

    DATA lv_host_id TYPE string.
    IF iv_container_name IS NOT INITIAL.
      LOOP AT mt_snapshots INTO DATA(ls_host_candidate)
          WHERE kind = 'CUSTOM_CONTAINER'.
        IF ls_host_candidate-payload CP |*name={ iv_container_name };*|.
          lv_host_id = ls_host_candidate-control_id.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.
    IF iv_document = abap_true.
      result = |<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>GUI controls</title><style>.gg-control\{position:absolute;box-sizing:border-box\}.gg-controls\{position:relative;min-height:240px\}.gg-control[hidden]\{display:none\}.gg-textedit-shell\{display:flex;flex-direction:column;gap:4px;padding:4px;border:1px solid #6b8298;background:#edf5fb\}.gg-textedit-shell textarea\{position:relative!important;left:auto!important;top:auto!important;width:100%!important;height:auto!important;flex:1;min-height:0\}.gg-textedit-toolbar\{display:flex;align-items:center;min-height:22px;padding:0 6px;background:#d9e8f5;border:1px solid #a6bdd0;font:12px system-ui,sans-serif\}.gg-textedit-statusbar\{padding:2px 6px;border-top:1px solid #a6bdd0;color:#40566b;font:11px system-ui,sans-serif\}textarea[data-fixed-font="1"]\{font-family:ui-monospace,SFMono-Regular,Consolas,monospace\}.gg-toolbar-menu\{margin:4px 0 0;padding:4px;min-width:160px;list-style:none;border:1px solid #6b8298;background:#fff;box-shadow:0 2px 5px #0003\}.gg-toolbar-menu li\{margin:0;padding:0\}.gg-toolbar-menu button\{width:100%;padding:3px 8px;border:0;background:transparent;text-align:left\}.gg-toolbar-menu button:hover,.gg-toolbar-menu button:focus-visible\{background:#d9e8f5\}.gg-toolbar-menu-separator\{height:1px;margin:4px 0;background:#a6bdd0\}button:focus-visible,input:focus-visible,select:focus-visible,textarea:focus-visible,a:focus-visible,[tabindex="0"]:focus-visible\{outline:2px solid #2668a3;outline-offset:2px\}</style></head><body><main class="gg-controls" aria-label="GUI controls">|.
    ELSEIF iv_container_name IS NOT INITIAL.
      result = |<section class="gg-controls gg-control-host" aria-label="GUI controls" data-control-host="{ escape( iv_container_name ) }" style="width:100%;height:100%;min-height:0">|.
    ELSE.
      result = |<section class="gg-controls" aria-label="GUI controls">|.
    ENDIF.
    LOOP AT mt_snapshots INTO DATA(ls_snapshot).
      IF iv_container_name IS NOT INITIAL
          AND ( lv_host_id IS INITIAL OR ls_snapshot-control_id = lv_host_id
            OR belongs_to_container(
              iv_control_id = ls_snapshot-control_id
              iv_host_id    = lv_host_id ) = abap_false ).
        CONTINUE.
      ENDIF.
      IF ls_snapshot-kind = 'CUSTOM_CONTAINER'.
        READ TABLE mt_snapshots INTO DATA(ls_parent_snapshot)
          WITH KEY control_id = ls_snapshot-parent_id.
        IF sy-subrc = 0 AND ( ls_parent_snapshot-kind = 'SPLITTER_CONTAINER'
            OR ls_parent_snapshot-kind = 'EASY_SPLITTER' ).
          CONTINUE.
        ENDIF.
      ENDIF.
      DATA(lv_style) = |left:{ ls_snapshot-left }px;top:{ ls_snapshot-top }px;|.
      IF ls_snapshot-kind = 'TEXTEDIT'.
        lv_style = lv_style && `box-sizing:border-box;`.
      ENDIF.
      IF ls_snapshot-width > 0.
        lv_style = lv_style && |width:{ ls_snapshot-width }px;|.
      ELSEIF ls_snapshot-kind = 'TEXTEDIT'.
        lv_style = lv_style && `width:160px;`.
      ENDIF.
      IF ls_snapshot-height > 0.
        lv_style = lv_style && |height:{ ls_snapshot-height }px;|.
      ELSEIF ls_snapshot-kind = 'TEXTEDIT'.
        lv_style = lv_style && `height:42px;`.
      ELSEIF iv_container_name IS NOT INITIAL.
        lv_style = lv_style && `height:100%;`.
      ENDIF.
      IF ls_snapshot-width <= 0 AND iv_container_name IS NOT INITIAL.
        lv_style = lv_style && `width:100%;`.
      ENDIF.
      DATA(lv_hidden) = COND string( WHEN ls_snapshot-visible = abap_false THEN ' hidden' ELSE '' ).
      DATA(lv_disabled) = COND string( WHEN ls_snapshot-enabled = abap_false THEN ' disabled' ELSE '' ).
      lv_state_class = state_class(
        iv_focused  = ls_snapshot-focused
        iv_disabled = xsdbool( ls_snapshot-enabled = abap_false )
        iv_readonly = xsdbool( ls_snapshot-enabled = abap_false ) ).
      result = result && render_control_html(
        is_snapshot    = ls_snapshot
        iv_style       = lv_style
        iv_hidden      = lv_hidden
        iv_disabled    = lv_disabled
        iv_state_class = lv_state_class
        is_sapevent    = is_sapevent ).
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

  METHOD render_control_html.
    CASE is_snapshot-kind.
      WHEN 'DIALOGBOX_CONTAINER'.
        result = |<section class="gg-control gg-container gg-dialog-modeless { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="DIALOGBOX_CONTAINER" data-modeless="true" data-dialog-left="{ is_snapshot-left }" data-dialog-top="{ is_snapshot-top }" data-dialog-width="{ is_snapshot-width }" data-dialog-height="{ is_snapshot-height }" role="dialog" aria-modal="false" aria-label="{ escape( is_snapshot-payload ) }"{ iv_hidden }>{ escape( is_snapshot-payload ) }{ is_snapshot-html }</section>|.
      WHEN 'CUSTOM_CONTAINER' OR 'DOCKING_CONTAINER'
          OR 'SPLITTER_CONTAINER' OR 'EASY_SPLITTER'.
        result = |<section class="gg-control gg-container { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="{ escape( is_snapshot-kind ) }" role="region" aria-label="{ escape( is_snapshot-kind ) }"{ iv_hidden }>{ escape( is_snapshot-payload ) }{ is_snapshot-html }</section>|.
      WHEN 'ALV_GRID' OR 'ALV_TREE' OR 'SIMPLE_TREE' OR 'LIST_TREE' OR 'COLUMN_TREE'.
        result = |<div class="gg-control { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="{ escape( is_snapshot-kind ) }"{ iv_hidden }{ iv_disabled }>{ is_snapshot-html }{ escape( is_snapshot-payload ) }</div>|.
      WHEN 'TOOLBAR'.
        result = render_toolbar_html(
          is_snapshot    = is_snapshot
          iv_style       = iv_style
          iv_hidden      = iv_hidden
          iv_state_class = iv_state_class ).
      WHEN 'TEXTEDIT'.
        result = render_textedit_html(
          is_snapshot    = is_snapshot
          iv_style       = iv_style
          iv_hidden      = iv_hidden
          iv_disabled    = iv_disabled
          iv_state_class = iv_state_class ).
      WHEN 'PICTURE'.
        DATA(lv_picture_payload) = is_snapshot-payload.
        DATA(lv_url) = COND string( WHEN is_snapshot-picture_state = 'loaded'
                                    AND safe_url( lv_picture_payload ) = abap_true
                                    THEN escape( lv_picture_payload ) ELSE '' ).
        DATA(lv_picture_fit) = COND string(
          WHEN is_snapshot-picture_display_mode = 1 THEN 'fill'
          WHEN is_snapshot-picture_display_mode = 2 THEN 'contain'
          WHEN is_snapshot-picture_display_mode = 4 THEN 'contain'
          ELSE 'none' ).
        DATA(lv_picture_position) = COND string(
          WHEN is_snapshot-picture_display_mode = 3
            OR is_snapshot-picture_display_mode = 4 THEN 'center'
          ELSE 'initial' ).
        DATA(lv_picture_border) = COND string(
          WHEN is_snapshot-picture_border <> 0 THEN ' border:1px solid #6b8298;'
          ELSE '' ).
        result = |<div class="gg-control { iv_state_class }" style="{ iv_style }{ lv_picture_border }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="PICTURE" data-picture-state="{ escape( is_snapshot-picture_state ) }" data-display-mode="{ is_snapshot-picture_display_mode }" role="img" aria-label="{ escape( COND string( WHEN is_snapshot-picture_alt_text IS INITIAL THEN 'Picture' ELSE is_snapshot-picture_alt_text ) ) }"{ iv_hidden }><img src="{ lv_url }" alt="{ escape( COND string( WHEN is_snapshot-picture_alt_text IS INITIAL THEN 'Picture' ELSE is_snapshot-picture_alt_text ) ) }" style="width:100%;height:100%;object-fit:{ lv_picture_fit };object-position:{ lv_picture_position }"></div>|.
      WHEN 'HTML_VIEWER'.
        DATA(lv_srcdoc) = is_snapshot-payload.
        DATA(lv_sandbox) = ``.
        IF is_snapshot-sapevent = abap_true AND is_sapevent-url IS NOT INITIAL.
* The document registered sapevent and the caller supplied a transport, so its
* anchors become forms that submit to it. Submitting a form and, on a real
* click, replacing the top page are the only two things this needs; scripts
* stay blocked and the frame keeps its opaque origin.
          lv_srcdoc = rewrite_sapevent( document = lv_srcdoc
                                        sapevent = is_sapevent ).
          lv_sandbox = `allow-forms allow-top-navigation-by-user-activation`.
        ENDIF.
        result = |<iframe class="gg-control { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" title="HTML viewer" sandbox="{ lv_sandbox }"{ iv_hidden } srcdoc="{ escape( lv_srcdoc ) }"></iframe>|.
      WHEN 'DRAGDROP'.
        result = |<section class="gg-control gg-dragdrop-fallback { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="DRAGDROP" data-native-capability="unavailable" role="region" aria-label="Legacy ActiveX drag and drop unavailable"{ iv_hidden }><p>Legacy ActiveX drag/drop is unavailable in the browser.</p><textarea readonly aria-label="Legacy drag and drop fallback">{ escape( is_snapshot-payload ) }</textarea></section>|.
      WHEN 'CALENDAR'.
        result = |<section class="gg-control { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="CALENDAR" role="group" aria-label="Calendar"{ iv_hidden }>{ is_snapshot-html }{ escape( is_snapshot-payload ) }</section>|.
      WHEN 'SELECTOR'.
        result = |<select class="gg-control { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" name="{ escape( is_snapshot-control_id ) }" data-control-kind="SELECTOR" aria-label="Selector"{ iv_hidden }{ iv_disabled }>{ COND string( WHEN is_snapshot-html IS INITIAL THEN |<option>{ escape( is_snapshot-payload ) }</option>| ELSE is_snapshot-html ) }</select>|.
      WHEN 'BARCHART' OR 'CHART_ENGINE' OR 'GP_PRES'.
        result = |<figure class="gg-control gg-graphic" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="{ escape( is_snapshot-kind ) }" role="img" aria-label="{ escape( is_snapshot-kind ) }"{ iv_hidden }>{ is_snapshot-html }<figcaption>{ escape( is_snapshot-payload ) }</figcaption></figure>|.
      WHEN OTHERS.
        result = |<div class="gg-control" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="{ escape( is_snapshot-kind ) }"{ iv_hidden }{ iv_disabled }>{ escape( is_snapshot-payload ) }</div>|.
    ENDCASE.
  ENDMETHOD.

  METHOD render_toolbar_html.
    DATA lv_button_label TYPE string.

    result = |<div class="gg-control gg-control-toolbar { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" role="toolbar" aria-label="Control toolbar" data-toolbar-scope="control"{ iv_hidden }>|.
    LOOP AT is_snapshot-buttons INTO DATA(ls_button).
      IF lines( is_snapshot-buttons ) > 6 AND sy-tabix = 7.
        result = result && '<details class="gg-toolbar-overflow"><summary>More toolbar actions</summary><div role="toolbar" aria-label="More control toolbar actions">'.
      ENDIF.
      IF ls_button-butn_type = 2.
        result = result && |<span class="gg-toolbar-separator" role="separator" aria-orientation="vertical"></span>|.
        CONTINUE.
      ENDIF.
      lv_button_label = COND #( WHEN ls_button-text IS INITIAL
                                THEN CONV string( ls_button-quickinfo )
                                ELSE CONV string( ls_button-text ) ).
      DATA(lv_toolbar_type) = COND string(
        WHEN ls_button-butn_type = 3 OR ls_button-butn_type = 4 THEN ' aria-haspopup="menu"'
        ELSE `` ).
      DATA(lv_toolbar_menu) = COND string(
        WHEN ls_button-butn_type = 3 OR ls_button-butn_type = 4
          THEN | aria-controls="{ escape( is_snapshot-control_id ) }-menu"|
        ELSE `` ).
      DATA(lv_toolbar_checked) = COND string(
        WHEN ls_button-checked IS NOT INITIAL THEN ' aria-pressed="true"'
        ELSE ' aria-pressed="false"' ).
      result = result && |<button class="{ state_class( iv_disabled = xsdbool( ls_button-disabled IS NOT INITIAL ) ) }" type="submit" name="gg_action" value="COMMAND:{ escape( CONV string( ls_button-function ) ) }" title="{ escape( CONV string( ls_button-quickinfo ) ) }" aria-label="{ escape( lv_button_label ) }" aria-keyshortcuts="Enter" data-toolbar-button-type="{ ls_button-butn_type }"{ lv_toolbar_type }{ lv_toolbar_menu }{ lv_toolbar_checked }{ COND string( WHEN ls_button-disabled IS NOT INITIAL THEN ' disabled aria-disabled="true"' ELSE '' ) }>{ escape( CONV string( ls_button-text ) ) }</button>|.
    ENDLOOP.
    IF lines( is_snapshot-buttons ) > 6.
      result = result && '</div></details>'.
    ENDIF.
    result = result && |{ is_snapshot-html }</div>|.
  ENDMETHOD.

  METHOD render_textedit_html.
    DATA(lv_textedit_attrs) = | data-wordwrap-mode="{ is_snapshot-text_wordwrap_mode }" data-wordwrap-position="{ is_snapshot-text_wordwrap_position }" data-wrap-to-linebreak="{ is_snapshot-text_wrap_to_linebreak }" data-fixed-font="{ is_snapshot-text_fixed_font }" data-modified="{ is_snapshot-text_modified }" data-cursor-line="{ is_snapshot-text_cursor_line }" data-cursor-position="{ is_snapshot-text_cursor_pos }" data-protected-from="{ is_snapshot-text_protected_from }" data-protected-to="{ is_snapshot-text_protected_to }"|.
    DATA(lv_textedit_aria_readonly) = COND string( WHEN is_snapshot-text_readonly = abap_true THEN ' aria-readonly="true"' ELSE '' ).
    DATA(lv_textedit_html) = |<textarea class="gg-control { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" name="{ escape( is_snapshot-control_id ) }" data-control-kind="TEXTEDIT" aria-label="Text editor"{ lv_textedit_attrs }{ lv_textedit_aria_readonly }{ iv_hidden }{ iv_disabled }>{ escape( is_snapshot-payload ) }</textarea>|.
    IF is_snapshot-text_toolbar_mode = abap_true OR is_snapshot-text_statusbar_mode = abap_true.
      result = |<section class="gg-textedit-shell gg-control { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }-shell" aria-label="Text editor shell"{ iv_hidden }>|.
      IF is_snapshot-text_toolbar_mode = abap_true.
        result = result && '<div class="gg-textedit-toolbar" role="toolbar" aria-label="Text editor tools"><span>Text editor tools</span></div>'.
      ENDIF.
      result = result && lv_textedit_html.
      IF is_snapshot-text_statusbar_mode = abap_true.
        result = result && |<div class="gg-textedit-statusbar" role="status" aria-label="Text editor status">{ COND string( WHEN is_snapshot-text_modified <> 0 THEN 'Modified' ELSE 'Unmodified' ) } &#183; line { is_snapshot-text_cursor_line }, position { is_snapshot-text_cursor_pos }</div>|.
      ENDIF.
      result = result && '</section>'.
    ELSE.
      result = lv_textedit_html.
    ENDIF.
  ENDMETHOD.

  METHOD belongs_to_container.
    DATA lv_parent_id TYPE string.
    DATA lv_current_id TYPE string.

    lv_current_id = iv_control_id.
    WHILE lv_current_id IS NOT INITIAL.
      READ TABLE mt_snapshots INTO DATA(ls_snapshot)
        WITH KEY control_id = lv_current_id.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      lv_parent_id = ls_snapshot-parent_id.
      IF lv_parent_id = iv_host_id.
        result = abap_true.
        RETURN.
      ENDIF.
      lv_current_id = lv_parent_id.
    ENDWHILE.
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

  METHOD set_text_state.
    READ TABLE mt_snapshots INTO DATA(ls_snapshot)
      WITH KEY control_id = control->control_id.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF toolbar_mode IS SUPPLIED.
      ls_snapshot-text_toolbar_mode = toolbar_mode.
    ENDIF.
    IF statusbar_mode IS SUPPLIED.
      ls_snapshot-text_statusbar_mode = statusbar_mode.
    ENDIF.
    IF wordwrap_mode IS SUPPLIED.
      ls_snapshot-text_wordwrap_mode = wordwrap_mode.
    ENDIF.
    IF wordwrap_position IS SUPPLIED.
      ls_snapshot-text_wordwrap_position = wordwrap_position.
    ENDIF.
    IF wrap_to_linebreak IS SUPPLIED.
      ls_snapshot-text_wrap_to_linebreak = wrap_to_linebreak.
    ENDIF.
    IF fixed_font IS SUPPLIED.
      ls_snapshot-text_fixed_font = fixed_font.
    ENDIF.
    IF modified IS SUPPLIED.
      ls_snapshot-text_modified = modified.
    ENDIF.
    IF cursor_line IS SUPPLIED.
      ls_snapshot-text_cursor_line = cursor_line.
    ENDIF.
    IF cursor_pos IS SUPPLIED.
      ls_snapshot-text_cursor_pos = cursor_pos.
    ENDIF.
    IF protected_from IS SUPPLIED.
      ls_snapshot-text_protected_from = protected_from.
    ENDIF.
    IF protected_to IS SUPPLIED.
      ls_snapshot-text_protected_to = protected_to.
    ENDIF.
    IF readonly IS SUPPLIED.
      ls_snapshot-text_readonly = readonly.
    ENDIF.
    MODIFY mt_snapshots FROM ls_snapshot INDEX sy-tabix.
  ENDMETHOD.

  METHOD set_picture_state.
    READ TABLE mt_snapshots INTO DATA(ls_snapshot)
      WITH KEY control_id = control->control_id.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF display_mode IS SUPPLIED.
      ls_snapshot-picture_display_mode = display_mode.
    ENDIF.
    IF border IS SUPPLIED.
      ls_snapshot-picture_border = border.
    ENDIF.
    IF state IS SUPPLIED.
      ls_snapshot-picture_state = state.
    ENDIF.
    IF alt_text IS SUPPLIED.
      ls_snapshot-picture_alt_text = alt_text.
    ENDIF.
    MODIFY mt_snapshots FROM ls_snapshot INDEX sy-tabix.
  ENDMETHOD.

  METHOD is_valid.
    result = COND #( WHEN mv_alive = abap_true THEN 1 ELSE 0 ).
  ENDMETHOD.

  METHOD rewrite_sapevent.
* Replaces every <a href="sapevent:ACTION">label</a> of the document with a
* form that posts the caller's fields plus ACTION, and keeps the rest of the
* document as it is. Only the sapevent href is taken out of the opening tag,
* so no attribute has to be parsed and everything else the program wrote stays
* on the button. A sapevent anchor must not sit inside a form of the document
* itself, because nested forms are dropped by the browser.
    CONSTANTS lc_marker TYPE string VALUE 'href="sapevent:'.
    DATA lv_rest       TYPE string.
    DATA lv_offset     TYPE i.
    DATA lv_tag_end    TYPE i.
    DATA lv_close      TYPE i.
    DATA lv_quote      TYPE i.
    DATA lv_head       TYPE string.
    DATA lv_tag        TYPE string.
    DATA lv_action     TYPE string.
    DATA lv_attributes TYPE string.
    DATA lv_form       TYPE string.
    DATA ls_field      TYPE ty_field.

    lv_rest = document.
    WHILE lv_rest IS NOT INITIAL.
      FIND FIRST OCCURRENCE OF '<a' IN lv_rest MATCH OFFSET lv_offset.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      result = result && substring( val = lv_rest
                                    len = lv_offset ).
      lv_rest = substring( val = lv_rest
                           off = lv_offset ).
      IF strlen( lv_rest ) < 3.
        EXIT.
      ENDIF.

* <abbr>, <article> and friends start with <a as well. Both operands are
* strings, so the trailing blank of the opening tag is significant here.
      lv_head = substring( val = lv_rest
                           len = 3 ).
      IF lv_head <> `<a ` AND lv_head <> `<a>`.
        result = result && substring( val = lv_rest
                                      len = 2 ).
        lv_rest = substring( val = lv_rest
                             off = 2 ).
        CONTINUE.
      ENDIF.

      FIND FIRST OCCURRENCE OF '>' IN lv_rest MATCH OFFSET lv_tag_end.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      lv_tag = substring( val = lv_rest
                          len = lv_tag_end + 1 ).
      FIND FIRST OCCURRENCE OF lc_marker IN lv_tag MATCH OFFSET lv_offset.
      IF sy-subrc <> 0.
* An ordinary link of the document, left untouched.
        result = result && lv_tag.
        lv_rest = substring( val = lv_rest
                             off = lv_tag_end + 1 ).
        CONTINUE.
      ENDIF.

      lv_action = substring( val = lv_tag
                             off = lv_offset + strlen( lc_marker ) ).
      FIND FIRST OCCURRENCE OF '"' IN lv_action MATCH OFFSET lv_quote.
      IF sy-subrc <> 0.
        result = result && lv_tag.
        lv_rest = substring( val = lv_rest
                             off = lv_tag_end + 1 ).
        CONTINUE.
      ENDIF.
      lv_action = substring( val = lv_action
                             len = lv_quote ).
      lv_attributes = substring( val = lv_tag
                                 off = 2
                                 len = lv_tag_end - 2 ).
      REPLACE FIRST OCCURRENCE OF |{ lc_marker }{ lv_action }"| IN lv_attributes WITH ``.

      lv_form = |<form class="gg-sapevent" method="post" action="{ escape( sapevent-url ) }" target="_top">|.
      LOOP AT sapevent-fields INTO ls_field.
        lv_form = lv_form && |<input type="hidden" name="{ escape( ls_field-name ) }"| &&
          | value="{ escape( ls_field-value ) }">|.
      ENDLOOP.
* The action is taken out of an attribute of the document and put back into
* one, so it is already escaped at exactly the level it is needed at.
      lv_form = lv_form && |<button type="submit" name="{ escape( sapevent-action_field ) }"| &&
        | value="{ lv_action }"{ lv_attributes }>|.
      result = result && lv_form.
      lv_rest = substring( val = lv_rest
                           off = lv_tag_end + 1 ).

* Whatever the anchor wrapped becomes the label of the button.
      FIND FIRST OCCURRENCE OF '</a>' IN lv_rest MATCH OFFSET lv_close.
      IF sy-subrc <> 0.
        result = result && lv_rest && |</button></form>|.
        CLEAR lv_rest.
        EXIT.
      ENDIF.
      result = result && substring( val = lv_rest
                                    len = lv_close ) && |</button></form>|.
      lv_rest = substring( val = lv_rest
                           off = lv_close + 4 ).
    ENDWHILE.
    result = result && lv_rest.
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
