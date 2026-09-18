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

    METHODS is_alive
      RETURNING
        VALUE(state) TYPE i.

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
    CLASS-METHODS format_total_value
      IMPORTING
        iv_value      TYPE decfloat34
        iv_decimals   TYPE i DEFAULT -1
        iv_sample     TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE string.

* Compares a value against one row of a select-option style range, the way an
* ALV grid filter and a SALV filter both do. The SALV implementation keeps its
* own fallback behavior in a private helper because SALV classes do not inherit
* from the control framework.
    CLASS-METHODS compare_option
      IMPORTING
        iv_value         TYPE string
        iv_option        TYPE string
        iv_low           TYPE string
        iv_high          TYPE string OPTIONAL
        iv_sign          TYPE string OPTIONAL
        iv_unknown_as_eq TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result)    TYPE abap_bool.

    METHODS show_capability_boundary
      IMPORTING
        heading     TYPE string
        explanation TYPE string.

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
    CLASS-METHODS is_standalone_control
      IMPORTING
        iv_control_id TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS is_dialog_child
      IMPORTING
        iv_control_id TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS standalone_height
      RETURNING
        VALUE(result) TYPE i.
    CLASS-METHODS has_splitter_ancestor
      IMPORTING
        iv_control_id TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.
    CLASS-METHODS render_nested_html
      IMPORTING
        iv_parent_id  TYPE string
        is_sapevent   TYPE ty_sapevent OPTIONAL
      RETURNING
        VALUE(result) TYPE string.
    CLASS-METHODS standalone_external_script
      IMPORTING
        iv_container_name TYPE string
      RETURNING
        VALUE(result)     TYPE string.
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
    CLASS-METHODS render_splitter_html
      IMPORTING
        is_snapshot    TYPE ty_snapshot
        iv_style       TYPE string
        iv_hidden      TYPE string
        iv_state_class TYPE string
        is_sapevent    TYPE ty_sapevent OPTIONAL
      RETURNING
        VALUE(result)  TYPE string.
    CLASS-METHODS splitter_payload_value
      IMPORTING
        iv_payload    TYPE string
        iv_key        TYPE string
      RETURNING
        VALUE(result) TYPE string.
    CLASS-METHODS splitter_payload_integer
      IMPORTING
        iv_payload       TYPE string
        iv_key           TYPE string
        iv_default_value TYPE i
      RETURNING
        VALUE(result)    TYPE i.
    CLASS-METHODS splitter_track_template
      IMPORTING
        iv_payload     TYPE string
        iv_mode_key    TYPE string
        iv_sizes_key   TYPE string
        iv_track_count TYPE i
      RETURNING
        VALUE(result)  TYPE string.
    CLASS-METHODS docking_style
      IMPORTING
        is_snapshot   TYPE ty_snapshot
        iv_style      TYPE string
      RETURNING
        VALUE(result) TYPE string.
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

  METHOD show_capability_boundary.
    DATA(lv_heading) = escape_html( text = heading ).
    DATA(lv_explanation) = escape_html( text = explanation ).
    set_html(
      control = me
      html    = |<section class="gg-capability-boundary" role="note"><h3>{ lv_heading }</h3><p>{ lv_explanation }</p></section>| ).
  ENDMETHOD.

  METHOD escape_html.
    result = escape( text ).
  ENDMETHOD.

  METHOD compare_option.
    CASE to_upper( iv_option ).
      WHEN 'EQ'.
        result = xsdbool( iv_value = iv_low ).
      WHEN 'NE'.
        result = xsdbool( iv_value <> iv_low ).
      WHEN 'BT'.
        result = xsdbool( iv_value >= iv_low AND iv_value <= iv_high ).
      WHEN 'NB'.
        result = xsdbool( iv_value < iv_low OR iv_value > iv_high ).
      WHEN 'GE'.
        result = xsdbool( iv_value >= iv_low ).
      WHEN 'GT'.
        result = xsdbool( iv_value > iv_low ).
      WHEN 'LE'.
        result = xsdbool( iv_value <= iv_low ).
      WHEN 'LT'.
        result = xsdbool( iv_value < iv_low ).
      WHEN 'CP'.
        result = xsdbool( iv_value CP iv_low ).
      WHEN 'NP'.
        result = xsdbool( iv_value NP iv_low ).
      WHEN OTHERS.
* The two filter sources read an unrecognised option differently: an ALV grid
* falls back to equality, a SALV filter rejects the row. Each keeps its own
* reading instead of one being quietly changed to the other.
        result = xsdbool( iv_unknown_as_eq = abap_true AND iv_value = iv_low ).
    ENDCASE.
    IF iv_sign = 'E'.
      result = xsdbool( result = abap_false ).
    ENDIF.
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
    state = state_dead.
    READ TABLE mt_snapshots TRANSPORTING NO FIELDS
      WITH KEY control_id = control_id.
    IF sy-subrc = 0.
      state = state_alive.
    ENDIF.
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
    DATA lv_standalone_height TYPE i VALUE 240.
    IF iv_container_name IS NOT INITIAL.
      LOOP AT mt_snapshots INTO DATA(ls_host_candidate)
          WHERE kind = 'CUSTOM_CONTAINER'.
        IF ls_host_candidate-payload CP |*name={ iv_container_name };*|.
          lv_host_id = ls_host_candidate-control_id.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.
    IF iv_document = abap_false AND iv_container_name IS INITIAL.
      lv_standalone_height = standalone_height( ).
    ENDIF.
    IF iv_document = abap_true.
      result = |<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>GUI controls</title><style>.gg-control\{position:absolute;box-sizing:border-box\}.gg-controls\{position:relative;min-height:240px\}.gg-control[hidden]\{display:none\}.gg-textedit-shell\{display:flex;flex-direction:column;gap:4px;padding:4px;border:1px solid #6b8298;background:#edf5fb\}.gg-textedit-shell textarea\{position:relative!important;left:auto!important;top:auto!important;width:100%!important;height:auto!important;flex:1;min-height:0\}.gg-textedit-toolbar\{display:flex;align-items:center;min-height:22px;padding:0 6px;background:#d9e8f5;border:1px solid #a6bdd0;font:12px system-ui,sans-serif\}.gg-textedit-statusbar\{padding:2px 6px;border-top:1px solid #a6bdd0;color:#40566b;font:11px system-ui,sans-serif\}textarea[data-fixed-font="1"]\{font-family:ui-monospace,SFMono-Regular,Consolas,monospace\}.gg-toolbar-menu\{margin:4px 0 0;padding:4px;min-width:160px;list-style:none;border:1px solid #6b8298;background:#fff;box-shadow:0 2px 5px #0003\}.gg-toolbar-menu li\{margin:0;padding:0\}.gg-toolbar-menu button\{width:100%;padding:3px 8px;border:0;background:transparent;text-align:left\}.gg-toolbar-menu button:hover,.gg-toolbar-menu button:focus-visible\{background:#d9e8f5\}.gg-toolbar-menu-separator\{height:1px;margin:4px 0;background:#a6bdd0\}button:focus-visible,input:focus-visible,select:focus-visible,textarea:focus-visible,a:focus-visible,[tabindex="0"]:focus-visible\{outline:2px solid #2668a3;outline-offset:2px\}</style></head><body><main class="gg-controls" aria-label="GUI controls">|.
    ELSEIF iv_container_name IS NOT INITIAL.
      result = |<section class="gg-controls gg-control-host" aria-label="GUI controls" data-control-host="{ escape( iv_container_name ) }" style="position:relative;width:100%;height:100%;min-height:0;box-sizing:border-box;overflow:auto">|.
    ELSE.
      result = |<section class="gg-controls gg-controls-standalone" aria-label="GUI controls" style="display:flow-root;position:relative;min-height:{ lv_standalone_height }px">|.
    ENDIF.
    LOOP AT mt_snapshots INTO DATA(ls_snapshot).
      IF iv_container_name IS NOT INITIAL
          AND ls_snapshot-control_id <> lv_host_id
          AND belongs_to_container(
                iv_control_id = ls_snapshot-control_id
                iv_host_id    = lv_host_id ) = abap_false
          AND is_standalone_control(
                iv_control_id = ls_snapshot-control_id ) = abap_false.
        CONTINUE.
      ENDIF.
      IF has_splitter_ancestor( iv_control_id = ls_snapshot-control_id ) = abap_true.
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
      DATA(lv_render_top) = COND i(
        WHEN ls_snapshot-kind = 'DIALOGBOX_CONTAINER' AND ls_snapshot-top > 60
          THEN ls_snapshot-top - 60
        WHEN ls_snapshot-kind = 'DIALOGBOX_CONTAINER'
          THEN 0
        ELSE ls_snapshot-top ).
      DATA(lv_render_left) = COND i(
        WHEN ls_snapshot-kind = 'DIALOGBOX_CONTAINER' AND ls_snapshot-width > 0
          THEN 660
        ELSE ls_snapshot-left ).
      DATA(lv_style) = |position:absolute;box-sizing:border-box;left:{ lv_render_left }px;top:{ lv_render_top }px;|.
      IF ls_snapshot-kind = 'TEXTEDIT'.
        lv_style = lv_style && `box-sizing:border-box;`.
      ENDIF.
      IF ls_snapshot-width > 0.
        lv_style = lv_style && |width:{ ls_snapshot-width }px;|.
      ELSEIF iv_container_name IS NOT INITIAL.
        lv_style = lv_style && `width:100%;`.
      ELSEIF ls_snapshot-kind = 'TEXTEDIT'.
        lv_style = lv_style && `width:160px;`.
      ENDIF.
      IF ls_snapshot-height > 0.
        lv_style = lv_style && |height:{ ls_snapshot-height }px;|.
      ELSEIF iv_container_name IS NOT INITIAL.
        lv_style = lv_style && `height:100%;`.
      ELSEIF ls_snapshot-kind = 'TEXTEDIT'.
        lv_style = lv_style && `height:42px;`.
      ENDIF.
      lv_style = docking_style(
        is_snapshot = ls_snapshot
        iv_style    = lv_style ).
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
      result = result && standalone_external_script( iv_container_name = iv_container_name ).
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
        DATA(lv_dialog_html) = render_nested_html(
          iv_parent_id = is_snapshot-control_id
          is_sapevent  = is_sapevent ).
        result = |<section class="gg-control gg-container gg-dialog-modeless { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="DIALOGBOX_CONTAINER" data-payload="{ escape( is_snapshot-payload ) }" data-modeless="true" data-dialog-left="{ is_snapshot-left }" data-dialog-top="{ is_snapshot-top }" data-dialog-width="{ is_snapshot-width }" data-dialog-height="{ is_snapshot-height }" role="dialog" aria-modal="false" aria-label="{ escape( is_snapshot-payload ) }"{ iv_hidden }><header class="gg-dialog-title">SAP GUI modeless control dialog</header><div class="gg-dialog-body">{ lv_dialog_html }</div></section>|.
      WHEN 'CUSTOM_CONTAINER' OR 'DOCKING_CONTAINER'.
        DATA(lv_container_html) = ``.
        IF is_snapshot-kind = 'DOCKING_CONTAINER'.
          lv_container_html = render_nested_html(
            iv_parent_id = is_snapshot-control_id
            is_sapevent  = is_sapevent ).
        ENDIF.
        result = |<section class="gg-control gg-container { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="{ escape( is_snapshot-kind ) }" data-payload="{ escape( is_snapshot-payload ) }" role="region" aria-label="{ escape( is_snapshot-kind ) }"{ iv_hidden }>{ is_snapshot-html }{ lv_container_html }</section>|.
      WHEN 'LIST_TREE'.
        DATA(lv_list_tree_heading) = escape( is_snapshot-payload ).
        result = |<div class="gg-control { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="LIST_TREE" data-hierarchy-header="{ lv_list_tree_heading }"{ iv_hidden }{ iv_disabled }>{ COND string( WHEN is_snapshot-payload IS NOT INITIAL THEN |<h2>{ lv_list_tree_heading }</h2>| ELSE `` ) }{ is_snapshot-html }</div>|.
      WHEN 'SPLITTER_CONTAINER' OR 'EASY_SPLITTER'.
        result = render_splitter_html(
          is_snapshot    = is_snapshot
          iv_style       = iv_style
          iv_hidden      = iv_hidden
          iv_state_class = iv_state_class
          is_sapevent    = is_sapevent ).
      WHEN 'ALV_GRID' OR 'ALV_TREE' OR 'SIMPLE_TREE' OR 'COLUMN_TREE'.
        result = |<div class="gg-control { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="{ escape( is_snapshot-kind ) }" data-payload="{ escape( is_snapshot-payload ) }"{ iv_hidden }{ iv_disabled }>{ is_snapshot-html }</div>|.
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
        DATA(lv_srcdoc) = is_snapshot-html.
        DATA(lv_iframe_style) = iv_style && `border:0;`.
        DATA(lv_sandbox) = ``.
        DATA(lv_iframe_source) = ``.
        IF lv_srcdoc IS NOT INITIAL.
          IF is_snapshot-sapevent = abap_true AND is_sapevent-url IS NOT INITIAL.
* The document registered sapevent and the caller supplied a transport, so its
* anchors become forms that submit to it. Submitting a form and, on a real
* click, replacing the top page are the only two things this needs; scripts
* stay blocked and the frame keeps its opaque origin.
            lv_srcdoc = rewrite_sapevent( document = lv_srcdoc
                                          sapevent = is_sapevent ).
            lv_sandbox = `allow-forms allow-top-navigation-by-user-activation`.
          ENDIF.
          lv_iframe_source = |srcdoc="{ escape( lv_srcdoc ) }"|.
        ELSEIF safe_url( is_snapshot-payload ) = abap_true.
          lv_iframe_source = |src="{ escape( is_snapshot-payload ) }"|.
        ENDIF.
        result = |<iframe class="gg-control { iv_state_class }" style="{ lv_iframe_style }" id="{ escape( is_snapshot-control_id ) }" title="HTML viewer" sandbox="{ lv_sandbox }"{ iv_hidden } { lv_iframe_source }></iframe>|.
      WHEN 'DRAGDROP'.
        result = |<section class="gg-control gg-dragdrop-fallback { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="DRAGDROP" data-native-capability="unavailable" data-payload="{ escape( is_snapshot-payload ) }" role="region" aria-label="Legacy ActiveX drag and drop unavailable"{ iv_hidden }><textarea readonly aria-label="Legacy drag and drop fallback">Legacy ActiveX drag/drop is unavailable in the browser.</textarea></section>|.
      WHEN 'CALENDAR'.
        result = |<section class="gg-control { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="CALENDAR" data-date-range="{ escape( is_snapshot-payload ) }" role="group" aria-label="Calendar"{ iv_hidden }>{ is_snapshot-html }</section>|.
      WHEN 'SELECTOR'.
        result = |<select class="gg-control { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" name="{ escape( is_snapshot-control_id ) }" data-control-kind="SELECTOR" aria-label="Selector"{ iv_hidden }{ iv_disabled }>{ COND string( WHEN is_snapshot-html IS INITIAL THEN |<option>{ escape( is_snapshot-payload ) }</option>| ELSE is_snapshot-html ) }</select>|.
      WHEN 'CHART_ENGINE'.
        result = |<div class="gg-control gg-graphic { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="CHART_ENGINE" data-payload="{ escape( is_snapshot-payload ) }"{ iv_hidden }>{ is_snapshot-html }</div>|.
      WHEN 'BARCHART' OR 'GP_PRES'.
        result = |<figure class="gg-control gg-graphic" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="{ escape( is_snapshot-kind ) }" role="img" aria-label="{ escape( is_snapshot-kind ) }"{ iv_hidden }>{ is_snapshot-html }<figcaption>{ escape( is_snapshot-payload ) }</figcaption></figure>|.
      WHEN 'TIMER'.
        result = |<div class="gg-control" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="TIMER" data-payload="{ escape( is_snapshot-payload ) }" aria-hidden="true" hidden></div>|.
      WHEN OTHERS.
        result = |<div class="gg-control" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="{ escape( is_snapshot-kind ) }"{ iv_hidden }{ iv_disabled }>{ escape( is_snapshot-payload ) }</div>|.
    ENDCASE.
  ENDMETHOD.

  METHOD standalone_external_script.
    IF iv_container_name IS INITIAL.
      result = `<script>(function(){var place=function(){var roots=document.querySelectorAll(".gg-controls-standalone");for(var i=0;i<roots.length;i++){var root=roots[i],external=null,children=root.children;for(var j=0;j<children.length;j++){if(children[j].classList.contains("gg-external")){external=children[j];break;}}if(!external){continue;}var rootBounds=root.getBoundingClientRect(),bottom=0;for(var k=0;k<children.length;k++){var child=children[k];if(child===external||child.hidden||window.getComputedStyle(child).position!=="absolute"){continue;}var bounds=child.getBoundingClientRect();bottom=Math.max(bottom,bounds.bottom-rootBounds.top);}external.style.marginTop=Math.ceil(bottom+8)+"px";}};place();window.addEventListener("resize",place);})();</script>`.
    ENDIF.
  ENDMETHOD.

  METHOD format_total_value.
    DATA lv_integer TYPE string.
    DATA lv_fraction TYPE string.
    DATA lv_decimals TYPE i.
    DATA lv_factor TYPE decfloat34.
    DATA lv_scaled TYPE decfloat34.
    DATA lv_scaled_text TYPE string.
    DATA lv_sign TYPE string.
    DATA lv_integer_length TYPE i.
    DATA lv_integer_part TYPE string.
    DATA lv_fraction_part TYPE string.

    lv_decimals = iv_decimals.
    IF lv_decimals < 0.
      SPLIT iv_sample AT '.' INTO lv_integer lv_fraction.
      lv_decimals = strlen( lv_fraction ).
    ENDIF.
    IF lv_decimals > 14.
      lv_decimals = 14.
    ENDIF.
    lv_factor = 1.
    DO lv_decimals TIMES.
      lv_factor = lv_factor * 10.
    ENDDO.
    lv_scaled = round(
      val = iv_value * lv_factor
      dec = 0 ).
    lv_scaled_text = |{ lv_scaled }|.
    IF lv_scaled_text+0(1) = '-'.
      lv_sign = '-'.
      lv_scaled_text = substring(
        val = lv_scaled_text
        off = 1 ).
    ENDIF.
    WHILE strlen( lv_scaled_text ) <= lv_decimals.
      lv_scaled_text = |0{ lv_scaled_text }|.
    ENDWHILE.
    IF lv_decimals = 0.
      result = lv_sign && lv_scaled_text.
    ELSE.
      lv_integer_length = strlen( lv_scaled_text ) - lv_decimals.
      lv_integer_part = substring(
        val = lv_scaled_text
        off = 0
        len = lv_integer_length ).
      lv_fraction_part = substring(
        val = lv_scaled_text
        off = lv_integer_length ).
      result = |{ lv_sign }{ lv_integer_part }.{ lv_fraction_part }|.
    ENDIF.
  ENDMETHOD.

  METHOD splitter_payload_value.
    DATA lv_offset TYPE i.
    DATA lv_tail TYPE string.
    DATA lv_value_end TYPE i.

    lv_offset = find(
      val = iv_payload
      sub = iv_key ).
    IF lv_offset < 0.
      RETURN.
    ENDIF.
    lv_tail = substring(
      val = iv_payload
      off = lv_offset + strlen( iv_key ) ).
    lv_value_end = find(
      val = lv_tail
      sub = ';' ).
    IF lv_value_end > 0.
      result = substring(
        val = lv_tail
        len = lv_value_end ).
    ELSE.
      result = lv_tail.
    ENDIF.
  ENDMETHOD.

  METHOD splitter_payload_integer.
    DATA(lv_value) = splitter_payload_value(
      iv_payload = iv_payload
      iv_key     = iv_key ).
    IF lv_value IS INITIAL.
      result = iv_default_value.
      RETURN.
    ENDIF.
    result = CONV i( lv_value ).
  ENDMETHOD.

  METHOD splitter_track_template.
    DATA lv_mode TYPE i.
    DATA lv_sizes TYPE string.
    DATA lv_size TYPE string.
    DATA lt_sizes TYPE string_table.

    lv_mode = splitter_payload_integer(
      iv_payload       = iv_payload
      iv_key           = iv_mode_key
      iv_default_value = 1 ).
    lv_sizes = splitter_payload_value(
      iv_payload = iv_payload
      iv_key     = iv_sizes_key ).
    IF lv_sizes IS INITIAL.
      result = |repeat({ iv_track_count },minmax(0,1fr))|.
      RETURN.
    ENDIF.
    SPLIT lv_sizes AT ',' INTO TABLE lt_sizes.
    IF lines( lt_sizes ) <> iv_track_count.
      result = |repeat({ iv_track_count },minmax(0,1fr))|.
      RETURN.
    ENDIF.
    LOOP AT lt_sizes INTO lv_size.
      IF result IS NOT INITIAL.
        result = result && ` `.
      ENDIF.
      IF lv_mode = 1.
        result = result && |{ CONV i( lv_size ) }%|.
      ELSE.
        result = result && |{ CONV i( lv_size ) }px|.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD docking_style.
    result = iv_style.
    IF is_snapshot-kind <> 'DOCKING_CONTAINER'.
      RETURN.
    ENDIF.
    DATA(lv_side) = splitter_payload_integer(
      iv_payload       = is_snapshot-payload
      iv_key           = 'side='
      iv_default_value = 1 ).
    DATA(lv_extension) = splitter_payload_integer(
      iv_payload       = is_snapshot-payload
      iv_key           = 'extension='
      iv_default_value = 260 ).
    IF lv_extension < 1.
      lv_extension = 1.
    ENDIF.
    DATA(lv_vertical) = xsdbool( lv_side = 1 OR lv_side = 8 ).
    IF is_snapshot-width <= 0.
      IF lv_vertical = abap_true.
        result = result && |width:{ lv_extension }px;|.
      ELSE.
        result = result && `width:100%;`.
      ENDIF.
    ENDIF.
    IF is_snapshot-height <= 0.
      IF lv_vertical = abap_true.
        result = result && `height:100%;`.
      ELSE.
        result = result && |height:{ lv_extension }px;|.
      ENDIF.
    ENDIF.
    result = result && `overflow:auto;`.
  ENDMETHOD.

  METHOD render_splitter_html.
    DATA lv_rows TYPE i VALUE 1.
    DATA lv_columns TYPE i VALUE 1.
    DATA lv_row_tracks TYPE string.
    DATA lv_column_tracks TYPE string.

    lv_rows = splitter_payload_integer(
      iv_payload       = is_snapshot-payload
      iv_key           = 'rows='
      iv_default_value = 1 ).
    lv_columns = splitter_payload_integer(
      iv_payload       = is_snapshot-payload
      iv_key           = 'columns='
      iv_default_value = 1 ).
    IF lv_rows < 1.
      lv_rows = 1.
    ENDIF.
    IF lv_columns < 1.
      lv_columns = 1.
    ENDIF.
    lv_row_tracks = splitter_track_template(
      iv_payload     = is_snapshot-payload
      iv_mode_key    = 'row_mode='
      iv_sizes_key   = 'row_heights='
      iv_track_count = lv_rows ).
    lv_column_tracks = splitter_track_template(
      iv_payload     = is_snapshot-payload
      iv_mode_key    = 'column_mode='
      iv_sizes_key   = 'column_widths='
      iv_track_count = lv_columns ).
    DATA(lv_splitter_html) = render_nested_html(
      iv_parent_id = is_snapshot-control_id
      is_sapevent  = is_sapevent ).
    result = |<section class="gg-control gg-container { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" data-control-kind="{ escape( is_snapshot-kind ) }" data-layout-state="{ escape( is_snapshot-payload ) }" role="region" aria-label="{ escape( is_snapshot-kind ) }"{ iv_hidden }><div class="gg-splitter-layout" style="display:grid;width:100%;height:100%;min-height:0;overflow:hidden;grid-template-columns:{ lv_column_tracks };grid-template-rows:{ lv_row_tracks };">{ lv_splitter_html }</div></section>|.
  ENDMETHOD.

  METHOD render_toolbar_html.
    DATA lv_button_label TYPE string.
    DATA lv_button_icon TYPE string.
    DATA(lv_is_alv_toolbar) = xsdbool( is_snapshot-payload CS 'toolbar-kind=ALV' ).
    DATA(lv_toolbar_class) = COND string(
      WHEN lv_is_alv_toolbar = abap_true
        THEN 'gg-control-toolbar gg-alv-toolbar'
      ELSE 'gg-control-toolbar' ).

    result = |<div class="gg-control { lv_toolbar_class } { iv_state_class }" style="{ iv_style }" id="{ escape( is_snapshot-control_id ) }" role="toolbar" aria-label="{ COND string( WHEN lv_is_alv_toolbar = abap_true THEN 'ALV toolbar' ELSE 'Control toolbar' ) }" data-toolbar-scope="control"{ iv_hidden }>|.
    LOOP AT is_snapshot-buttons INTO DATA(ls_button).
      IF lv_is_alv_toolbar = abap_false AND lines( is_snapshot-buttons ) > 6 AND sy-tabix = 7.
        result = result && '<details class="gg-toolbar-overflow"><summary>More toolbar actions</summary><div role="toolbar" aria-label="More control toolbar actions">'.
      ENDIF.
      IF ls_button-butn_type = 2 OR ls_button-function IS INITIAL.
        result = result && |<span class="gg-toolbar-separator" role="separator" aria-orientation="vertical"></span>|.
        CONTINUE.
      ENDIF.
      lv_button_label = COND #( WHEN ls_button-text IS INITIAL
                                THEN CONV string( ls_button-quickinfo )
                                ELSE CONV string( ls_button-text ) ).
      lv_button_icon = COND string(
        WHEN ls_button-icon IS INITIAL THEN ``
        ELSE zcl_gg_host_icons=>icon( iv_name = CONV string( ls_button-icon ) ) ).
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
      DATA(lv_toolbar_button_class) = state_class(
        iv_disabled = xsdbool( ls_button-disabled IS NOT INITIAL ) ).
      IF lv_is_alv_toolbar = abap_true AND ls_button-text IS INITIAL
          AND ls_button-function IS NOT INITIAL.
        lv_toolbar_button_class = lv_toolbar_button_class && ` gg-alv-tool-button`.
      ENDIF.
      result = result && |<button class="{ lv_toolbar_button_class }" type="submit" name="gg_action" value="COMMAND:{ escape( CONV string( ls_button-function ) ) }" title="{ escape( CONV string( ls_button-quickinfo ) ) }" aria-label="{ escape( lv_button_label ) }" aria-keyshortcuts="Enter" data-toolbar-button-type="{ ls_button-butn_type }"{ lv_toolbar_type }{ lv_toolbar_menu }{ lv_toolbar_checked }{ COND string( WHEN ls_button-disabled IS NOT INITIAL THEN ' disabled aria-disabled="true"' ELSE '' ) }>{ lv_button_icon }{ escape( CONV string( ls_button-text ) ) }</button>|.
    ENDLOOP.
    IF lv_is_alv_toolbar = abap_false AND lines( is_snapshot-buttons ) > 6.
      result = result && '</div></details>'.
    ENDIF.
    result = result && |{ is_snapshot-html }</div>|.
  ENDMETHOD.

  METHOD render_textedit_html.
    DATA lt_textedit_lines TYPE string_table.
    DATA(lv_textedit_attrs) = | data-wordwrap-mode="{ is_snapshot-text_wordwrap_mode }" data-wordwrap-position="{ is_snapshot-text_wordwrap_position }" data-wrap-to-linebreak="{ is_snapshot-text_wrap_to_linebreak }" data-fixed-font="{ is_snapshot-text_fixed_font }" data-modified="{ is_snapshot-text_modified }" data-cursor-line="{ is_snapshot-text_cursor_line }" data-cursor-position="{ is_snapshot-text_cursor_pos }" data-protected-from="{ is_snapshot-text_protected_from }" data-protected-to="{ is_snapshot-text_protected_to }"|.
    SPLIT is_snapshot-payload AT cl_abap_char_utilities=>newline INTO TABLE lt_textedit_lines.
    DATA(lv_textedit_line_count) = lines( lt_textedit_lines ).
    IF lv_textedit_line_count = 0.
      lv_textedit_line_count = 1.
    ENDIF.
    DATA(lv_textedit_cursor_line) = COND i( WHEN is_snapshot-text_cursor_line < 1 THEN 1 ELSE is_snapshot-text_cursor_line ).
    DATA(lv_textedit_cursor_column) = is_snapshot-text_cursor_pos + 1.
    IF lv_textedit_cursor_column < 1.
      lv_textedit_cursor_column = 1.
    ENDIF.
    DATA(lv_textedit_aria_readonly) = COND string( WHEN is_snapshot-text_readonly = abap_true THEN ' aria-readonly="true"' ELSE '' ).
    DATA(lv_textedit_style) = iv_style.
    DATA(lv_shell_style) = iv_style.
    IF is_snapshot-text_toolbar_mode = abap_true OR is_snapshot-text_statusbar_mode = abap_true.
      lv_textedit_style = lv_textedit_style && `position:relative;left:auto;top:auto;width:100%;height:auto;flex:1;min-height:0;`.
      lv_shell_style = lv_shell_style && `display:flex;flex-direction:column;gap:4px;padding:4px;border:1px solid #6b8298;background:#edf5fb;`.
    ENDIF.
    IF is_snapshot-text_fixed_font <> 0.
      lv_textedit_style = lv_textedit_style && `font-family:ui-monospace,SFMono-Regular,Consolas,monospace;`.
    ENDIF.
    DATA(lv_textedit_html) = |<textarea class="gg-control { iv_state_class }" style="{ lv_textedit_style }" id="{ escape( is_snapshot-control_id ) }" name="{ escape( is_snapshot-control_id ) }" data-control-kind="TEXTEDIT" aria-label="Text editor"{ lv_textedit_attrs }{ lv_textedit_aria_readonly }{ iv_hidden }{ iv_disabled }>{ escape( is_snapshot-payload ) }</textarea>|.
    IF is_snapshot-text_toolbar_mode = abap_true OR is_snapshot-text_statusbar_mode = abap_true.
      result = |<section class="gg-textedit-shell gg-control { iv_state_class }" style="{ lv_shell_style }" id="{ escape( is_snapshot-control_id ) }-shell" aria-label="Text editor shell"{ iv_hidden }>|.
      IF is_snapshot-text_toolbar_mode = abap_true.
        result = result && '<div class="gg-textedit-toolbar" style="display:flex;align-items:center;gap:2px;min-height:26px;padding:2px 4px;background:#d9e8f5;border:1px solid #a6bdd0;font:12px system-ui,sans-serif" role="toolbar" aria-label="Text editor tools">'.
        result = result && |<button class="gg-textedit-tool-button" type="submit" name="gg_action" value="COMMAND:TEXTEDIT_CUT" title="Cut" aria-label="Cut">{ zcl_gg_host_icons=>icon( iv_name = 'edit' ) }</button>|.
        result = result && |<button class="gg-textedit-tool-button" type="submit" name="gg_action" value="COMMAND:TEXTEDIT_COPY" title="Copy" aria-label="Copy">{ zcl_gg_host_icons=>icon( iv_name = 'file-code' ) }</button>|.
        result = result && |<button class="gg-textedit-tool-button" type="submit" name="gg_action" value="COMMAND:TEXTEDIT_PASTE" title="Paste" aria-label="Paste">{ zcl_gg_host_icons=>icon( iv_name = 'folder-open' ) }</button>|.
        result = result && |<button class="gg-textedit-tool-button" type="submit" name="gg_action" value="COMMAND:TEXTEDIT_UNDO" title="Undo" aria-label="Undo">{ zcl_gg_host_icons=>icon( iv_name = 'arrow-back-up' ) }</button>|.
        result = result && |<button class="gg-textedit-tool-button" type="submit" name="gg_action" value="COMMAND:TEXTEDIT_REDO" title="Redo" aria-label="Redo">{ zcl_gg_host_icons=>icon( iv_name = 'arrow-forward-up' ) }</button>|.
        result = result && |<button class="gg-textedit-tool-button" type="submit" name="gg_action" value="COMMAND:TEXTEDIT_FIND" title="Find" aria-label="Find">{ zcl_gg_host_icons=>icon( iv_name = 'search' ) }</button>|.
        result = result && |<button class="gg-textedit-tool-button" type="submit" name="gg_action" value="COMMAND:TEXTEDIT_SAVE" title="Save" aria-label="Save">{ zcl_gg_host_icons=>icon( iv_name = 'device-floppy' ) }</button>|.
        result = result && |<button class="gg-textedit-tool-button" type="submit" name="gg_action" value="COMMAND:TEXTEDIT_PRINT" title="Print" aria-label="Print">{ zcl_gg_host_icons=>icon( iv_name = 'printer' ) }</button>|.
        result = result && '</div>'.
      ENDIF.
      result = result && lv_textedit_html.
      IF is_snapshot-text_statusbar_mode = abap_true.
        result = result && |<div class="gg-textedit-statusbar" style="display:flex;justify-content:flex-end;flex:0 0 auto;padding:2px 6px;border-top:1px solid #a6bdd0;color:#40566b;font:11px system-ui,sans-serif" role="status" aria-label="Text editor status" data-modified="{ is_snapshot-text_modified }"><span style="min-width:160px;padding:2px 6px;border-left:1px solid #d0d9e0">Li { lv_textedit_cursor_line }, Co { lv_textedit_cursor_column }</span><span style="min-width:160px;padding:2px 6px;border-left:1px solid #d0d9e0">Ln 1 - Ln { lv_textedit_line_count } of { lv_textedit_line_count } lines</span></div>|.
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

  METHOD is_standalone_control.
    DATA lv_current_id TYPE string.
    DATA lv_parent_id TYPE string.

    lv_current_id = iv_control_id.
    WHILE lv_current_id IS NOT INITIAL.
      READ TABLE mt_snapshots INTO DATA(ls_snapshot)
        WITH KEY control_id = lv_current_id.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      IF ls_snapshot-kind = 'DIALOGBOX_CONTAINER'
          OR ls_snapshot-kind = 'DOCKING_CONTAINER'.
        result = abap_true.
        RETURN.
      ENDIF.
      lv_parent_id = ls_snapshot-parent_id.
      IF lv_parent_id IS INITIAL.
        RETURN.
      ENDIF.
      lv_current_id = lv_parent_id.
    ENDWHILE.
  ENDMETHOD.

  METHOD is_dialog_child.
    DATA lv_current_id TYPE string.
    DATA lv_parent_id TYPE string.

    lv_current_id = iv_control_id.
    WHILE lv_current_id IS NOT INITIAL.
      READ TABLE mt_snapshots INTO DATA(ls_snapshot)
        WITH KEY control_id = lv_current_id.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      lv_parent_id = ls_snapshot-parent_id.
      IF lv_parent_id IS INITIAL.
        RETURN.
      ENDIF.
      READ TABLE mt_snapshots INTO DATA(ls_parent)
        WITH KEY control_id = lv_parent_id.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      IF ls_parent-kind = 'DIALOGBOX_CONTAINER'.
        result = abap_true.
        RETURN.
      ENDIF.
      lv_current_id = lv_parent_id.
    ENDWHILE.
  ENDMETHOD.

  METHOD standalone_height.
    result = 240.
    LOOP AT mt_snapshots INTO DATA(ls_snapshot).
      IF is_standalone_control( iv_control_id = ls_snapshot-control_id ) = abap_false
          OR ls_snapshot-visible = abap_false.
        CONTINUE.
      ENDIF.
      DATA(lv_height) = ls_snapshot-height.
      IF lv_height <= 0 AND ls_snapshot-kind = 'TEXTEDIT'.
        lv_height = 42.
      ENDIF.
      DATA(lv_bottom) = ls_snapshot-top + lv_height.
      IF lv_bottom > result.
        result = lv_bottom.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD has_splitter_ancestor.
    DATA lv_current_id TYPE string.
    DATA lv_parent_id TYPE string.

    IF is_dialog_child( iv_control_id ) = abap_true.
      result = abap_true.
      RETURN.
    ENDIF.
    lv_current_id = iv_control_id.
    WHILE lv_current_id IS NOT INITIAL.
      READ TABLE mt_snapshots INTO DATA(ls_snapshot)
        WITH KEY control_id = lv_current_id.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      lv_parent_id = ls_snapshot-parent_id.
      IF lv_parent_id IS INITIAL.
        RETURN.
      ENDIF.
      READ TABLE mt_snapshots INTO DATA(ls_parent)
        WITH KEY control_id = lv_parent_id.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      IF ls_parent-kind = 'SPLITTER_CONTAINER'
          OR ls_parent-kind = 'EASY_SPLITTER'
          OR ls_parent-kind = 'DOCKING_CONTAINER'.
        result = abap_true.
        RETURN.
      ENDIF.
      lv_current_id = lv_parent_id.
    ENDWHILE.
  ENDMETHOD.

  METHOD render_nested_html.
    READ TABLE mt_snapshots INTO DATA(ls_parent)
      WITH KEY control_id = iv_parent_id.
    DATA(lv_parent_found) = xsdbool( sy-subrc = 0 ).
    LOOP AT mt_snapshots INTO DATA(ls_snapshot)
        WHERE parent_id = iv_parent_id.
      IF ls_snapshot-kind = 'CUSTOM_CONTAINER'
          AND lv_parent_found = abap_true
          AND ( ls_parent-kind = 'SPLITTER_CONTAINER'
            OR ls_parent-kind = 'EASY_SPLITTER' ).
        DATA(lv_cell_html) = render_nested_html(
          iv_parent_id = ls_snapshot-control_id
          is_sapevent  = is_sapevent ).
        result = result && |<div class="gg-splitter-cell" style="position:relative;min-width:0;min-height:0;box-sizing:border-box;overflow:auto;border:1px solid #b2c7d8;background:#f7fbff" id="{ escape( ls_snapshot-control_id ) }" data-control-kind="SPLITTER_CELL" aria-label="Splitter cell">{ lv_cell_html }</div>|.
        CONTINUE.
      ENDIF.
      DATA(lv_style) = `position:relative;left:0;top:0;box-sizing:border-box;`.
      IF ls_snapshot-width > 0.
        lv_style = lv_style && |width:{ ls_snapshot-width }px;|.
      ELSE.
        lv_style = lv_style && `width:100%;`.
      ENDIF.
      IF ls_snapshot-height > 0.
        lv_style = lv_style && |height:{ ls_snapshot-height }px;|.
      ELSE.
        lv_style = lv_style && `height:100%;`.
      ENDIF.
      DATA(lv_hidden) = COND string( WHEN ls_snapshot-visible = abap_false THEN ' hidden' ELSE '' ).
      DATA(lv_disabled) = COND string( WHEN ls_snapshot-enabled = abap_false THEN ' disabled' ELSE '' ).
      DATA(lv_state_class) = state_class(
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
