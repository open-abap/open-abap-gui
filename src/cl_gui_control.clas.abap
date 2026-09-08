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
             sapevent   TYPE abap_bool,
           END OF ty_snapshot.
    TYPES ty_snapshots TYPE STANDARD TABLE OF ty_snapshot WITH DEFAULT KEY.

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

    CLASS-METHODS get_snapshots
      RETURNING
        VALUE(result) TYPE ty_snapshots.

    CLASS-METHODS render_html
      IMPORTING
        iv_document   TYPE abap_bool DEFAULT abap_true
        is_sapevent   TYPE ty_sapevent OPTIONAL
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
    CLASS-METHODS set_sapevent
      IMPORTING
        control    TYPE REF TO cl_gui_control
        registered TYPE abap_bool.

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

  METHOD set_sapevent.
    READ TABLE mt_snapshots INTO DATA(ls_snapshot)
      WITH KEY control_id = control->control_id.
    IF sy-subrc = 0.
      ls_snapshot-sapevent = registered.
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
    DATA lv_srcdoc  TYPE string.
    DATA lv_sandbox TYPE string.

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
          lv_srcdoc = ls_snapshot-payload.
          CLEAR lv_sandbox.
          IF ls_snapshot-sapevent = abap_true AND is_sapevent-url IS NOT INITIAL.
* The document registered sapevent and the caller supplied a transport, so its
* anchors become forms that submit to it. Submitting a form and, on a real
* click, replacing the top page are the only two things this needs; scripts
* stay blocked and the frame keeps its opaque origin.
            lv_srcdoc = rewrite_sapevent( document = lv_srcdoc
                                          sapevent = is_sapevent ).
            lv_sandbox = `allow-forms allow-top-navigation-by-user-activation`.
          ENDIF.
          result = result && |<iframe class="gg-control" style="{ lv_style }" id="{ escape( ls_snapshot-control_id ) }" title="HTML viewer" sandbox="{ lv_sandbox }"{ lv_hidden } srcdoc="{ escape( lv_srcdoc ) }"></iframe>|.
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
