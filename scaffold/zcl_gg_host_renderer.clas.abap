CLASS zcl_gg_host_renderer DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Semantic HTML renderer for the host's processor snapshots. It is deliberately
* independent from the transport: callers receive a document string and may
* return it from an HTTP endpoint, embed it, or assert it in ABAP Unit.

  PUBLIC SECTION.
    CLASS-METHODS with_navigation
      IMPORTING
        iv_html        TYPE string
        is_navigation  TYPE zif_gg_host_html_v1=>ty_navigation
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS render_list
      IMPORTING
        iv_session_id    TYPE string
        iv_page_id       TYPE string
        iv_title         TYPE string
        it_lines         TYPE zcl_gg_host_list=>ty_render_lines
        is_context       TYPE zif_gg_host_html_v1=>ty_renderer_context OPTIONAL
        is_status        TYPE zif_gg_session_types_v1=>ty_gui_status OPTIONAL
        it_actions       TYPE zif_gg_host_html_v1=>ty_actions OPTIONAL
        it_messages      TYPE zcl_gg_host_session=>ty_messages OPTIONAL
        iv_controls_html TYPE string OPTIONAL
      RETURNING
        VALUE(rv_html)   TYPE string.

    CLASS-METHODS render_selection
      IMPORTING
        iv_session_id  TYPE string
        iv_page_id     TYPE string
        iv_title       TYPE string
        it_values      TYPE zif_gg_selection_screen_types=>ty_values
        it_states      TYPE zif_gg_selection_screen_types=>ty_states
        it_blocks      TYPE zcl_gg_host_screen=>ty_blocks
        it_elements    TYPE zcl_gg_host_screen=>ty_elements
        it_tabs        TYPE zcl_gg_host_screen=>ty_tabs OPTIONAL
        is_context     TYPE zif_gg_host_html_v1=>ty_renderer_context OPTIONAL
        it_messages    TYPE zcl_gg_host_session=>ty_messages OPTIONAL
        iv_help_text   TYPE string OPTIONAL
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS render_dynpro
      IMPORTING
        iv_session_id  TYPE string
        iv_page_id     TYPE string
        is_screen      TYPE zif_gg_dynpro_types_v1=>ty_screen
        iv_title       TYPE string OPTIONAL
        is_status      TYPE zif_gg_session_types_v1=>ty_gui_status OPTIONAL
        is_cursor      TYPE zif_gg_session_types_v1=>ty_dialog_cursor OPTIONAL
        it_controls    TYPE zcl_gg_host_dynpro_builder=>ty_controls
        it_values      TYPE zif_gg_dynpro_types_v1=>ty_values
        it_states      TYPE zif_gg_dynpro_types_v1=>ty_states
        is_context     TYPE zif_gg_host_html_v1=>ty_renderer_context OPTIONAL
        it_messages    TYPE zcl_gg_host_session=>ty_messages OPTIONAL
        iv_help_text   TYPE string OPTIONAL
        it_help_values TYPE zif_gg_dynpro_types_v1=>ty_values OPTIONAL
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS render_message
      IMPORTING
        iv_session_id  TYPE string
        iv_page_id     TYPE string
        iv_title       TYPE string
        iv_text        TYPE string
        is_context     TYPE zif_gg_host_html_v1=>ty_renderer_context OPTIONAL
        it_messages    TYPE zcl_gg_host_session=>ty_messages OPTIONAL
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS render_terminal
      IMPORTING
        iv_session_id  TYPE string
        iv_page_id     TYPE string
        iv_title       TYPE string
        iv_text        TYPE string
        is_context     TYPE zif_gg_host_html_v1=>ty_renderer_context OPTIONAL
        it_messages    TYPE zcl_gg_host_session=>ty_messages OPTIONAL
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS render_navigation
      IMPORTING
        iv_session_id  TYPE string
        iv_page_id     TYPE string
        iv_title       TYPE string
        is_navigation  TYPE zif_gg_host_html_v1=>ty_navigation
        is_context     TYPE zif_gg_host_html_v1=>ty_renderer_context OPTIONAL
      RETURNING
        VALUE(rv_html) TYPE string.

  PRIVATE SECTION.
    CLASS-METHODS render_messages
      IMPORTING
        it_messages    TYPE zcl_gg_host_session=>ty_messages
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS spaces
      IMPORTING
        iv_count       TYPE i
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS state_attrs
      IMPORTING
        is_state        TYPE zif_gg_selection_screen_types=>ty_state
      RETURNING
        VALUE(rv_attrs) TYPE string.

    CLASS-METHODS dynpro_attrs
      IMPORTING
        is_state        TYPE zif_gg_dynpro_types_v1=>ty_state
      RETURNING
        VALUE(rv_attrs) TYPE string.

    CLASS-METHODS field_message_attrs
      IMPORTING
        it_messages     TYPE zcl_gg_host_session=>ty_messages
        iv_name         TYPE string
      RETURNING
        VALUE(rv_attrs) TYPE string.

    CLASS-METHODS render_selection_value_help
      IMPORTING
        it_ranges      TYPE zif_gg_selection_screen_types=>ty_ranges
      RETURNING
        VALUE(rv_html) TYPE string.
ENDCLASS.

CLASS zcl_gg_host_renderer IMPLEMENTATION.

  METHOD with_navigation.
    rv_html = iv_html.
    IF is_navigation-kind IS INITIAL OR is_navigation-target IS INITIAL.
      RETURN.
    ENDIF.
    DATA(lv_navigation) = |<nav class="gg-navigation" aria-label="Host navigation" data-navigation-kind="{ zcl_gg_host_html=>escape_attribute( is_navigation-kind ) }"><span>Transition target: { zcl_gg_host_html=>escape_text( is_navigation-target ) }</span></nav>|.
    REPLACE FIRST OCCURRENCE OF '<main>' IN rv_html WITH |<main>{ lv_navigation }|.
  ENDMETHOD.

  METHOD render_list.
    DATA lv_body TYPE string.
    DATA lv_page TYPE i.
    DATA lv_column TYPE i.
    DATA lv_line_id TYPE string.
    DATA lv_fragment_text TYPE string.
    DATA lv_fragment_html TYPE string.
    DATA lv_fragment_title TYPE string.
    DATA lv_nav TYPE string.
    DATA lv_action_value TYPE string.
    DATA lv_disabled TYPE string.
    DATA lv_action_label TYPE string.
    DATA lv_excluded TYPE string.

    lv_body = |<section class="gg-list" aria-label="List output">|.
    LOOP AT it_lines INTO DATA(ls_line).
      IF lv_page <> ls_line-page.
        IF lv_page > 0.
          lv_body = lv_body && |</div></section>|.
        ENDIF.
        lv_page = ls_line-page.
        lv_body = lv_body && |<section class="gg-list-page" data-page="{ ls_line-page }">|.
        lv_body = lv_body && |<h2 class="gg-visually-hidden">Page { ls_line-page }</h2><div>|.
      ENDIF.

      DATA(lv_line) = ``.
      lv_column = 1.
      LOOP AT ls_line-fragments INTO DATA(ls_fragment).
        IF ls_fragment-position > lv_column.
          lv_line = lv_line && spaces( ls_fragment-position - lv_column ).
        ENDIF.
        lv_fragment_text = ls_fragment-text.
        lv_fragment_title = ls_fragment-format-quickinfo.
        CLEAR lv_fragment_html.
        CASE ls_fragment-kind.
          WHEN 'CHECKBOX'.
            IF ls_fragment-text = '[X]'.
              lv_fragment_text = '[selected]'.
            ELSE.
              lv_fragment_text = '[not selected]'.
            ENDIF.
            lv_fragment_html = zcl_gg_host_html=>escape_text( lv_fragment_text ).
          WHEN 'ICON' OR 'SYMBOL'.
            lv_fragment_html = zcl_gg_host_icons=>icon(
              iv_name  = ls_fragment-text
              iv_label = COND string( WHEN lv_fragment_title IS INITIAL THEN ls_fragment-text ELSE lv_fragment_title ) ).
            lv_fragment_html = lv_fragment_html && |<span class="gg-visually-hidden">[{ zcl_gg_host_html=>escape_text( ls_fragment-text ) }]</span>|.
          WHEN OTHERS.
            lv_fragment_html = zcl_gg_host_html=>escape_text( lv_fragment_text ).
        ENDCASE.
        lv_line = lv_line && |<span class="gg-list-fragment { zcl_gg_host_html=>css_class( ls_fragment-format ) }" data-column="{ ls_fragment-position }"{ zcl_gg_host_html=>attribute( iv_name = `title` iv_value = lv_fragment_title iv_optional = abap_true ) }>{ lv_fragment_html }</span>|.
        lv_column = ls_fragment-position + strlen( ls_fragment-text ).
      ENDLOOP.
      IF ls_line-fragments IS INITIAL.
        lv_line = zcl_gg_host_html=>escape_text( ls_line-text ).
      ENDIF.

      lv_line_id = zcl_gg_host_html=>identifier(
        iv_scope   = 'list-line'
        iv_program = CONV string( is_context-program )
        iv_index   = ls_line-index ).
      IF ls_line-fields IS INITIAL.
        lv_body = lv_body && |<div id="{ zcl_gg_host_html=>escape_attribute( lv_line_id ) }" class="gg-list-line" data-line-index="{ ls_line-index }">{ lv_line }</div>|.
      ELSE.
        lv_body = lv_body && |<div id="{ zcl_gg_host_html=>escape_attribute( lv_line_id ) }" class="gg-list-line" data-line-index="{ ls_line-index }" data-action-token="{ zcl_gg_host_html=>escape_attribute( ls_line-token ) }"><button type="submit" name="gg_action" value="| && |LINE:{ ls_line-index }| && `|` && |{ zcl_gg_host_html=>escape_attribute( ls_line-token ) }| && |" aria-label="Select line { ls_line-index }">{ lv_line }</button></div>|.
      ENDIF.
    ENDLOOP.
    LOOP AT it_actions INTO DATA(ls_action).
      lv_action_value = ls_action-kind.
      lv_action_label = ls_action-kind.
      IF ls_action-ucomm IS NOT INITIAL.
        lv_action_value = lv_action_value && `:` && ls_action-ucomm.
        lv_action_label = ls_action-ucomm.
      ENDIF.
      CLEAR lv_disabled.
      IF line_exists( is_status-excluded_ucomm[ table_line = ls_action-ucomm ] ).
        lv_disabled = ` disabled`.
      ENDIF.
      lv_nav = lv_nav && |<button type="submit" name="gg_action" value="{ zcl_gg_host_html=>escape_attribute( lv_action_value ) }"{ lv_disabled }>{ zcl_gg_host_html=>escape_text( lv_action_label ) }</button>|.
    ENDLOOP.
    LOOP AT is_status-excluded_ucomm INTO lv_excluded.
      lv_nav = lv_nav && |<button type="submit" name="gg_action" value="COMMAND:{ zcl_gg_host_html=>escape_attribute( lv_excluded ) }" disabled>{ zcl_gg_host_html=>escape_text( lv_excluded ) }</button>|.
    ENDLOOP.
    IF lv_page > 0.
      lv_body = lv_body && |</div></section>|.
    ENDIF.
    IF iv_controls_html IS NOT INITIAL.
      lv_body = lv_body && iv_controls_html.
    ENDIF.
    lv_body = lv_body && |</section>|.
    rv_html = zcl_gg_host_html=>document(
      iv_session_id = iv_session_id
      iv_page_id    = iv_page_id
      iv_kind       = zif_gg_host_html_v1=>page_list
      iv_title      = iv_title
      iv_csp_nonce  = is_context-csp_nonce
       iv_body       = |<header><h1>{ zcl_gg_host_html=>escape_text( iv_title ) }</h1><p class="gg-list-status">{ zcl_gg_host_html=>escape_text( CONV string( is_status-status ) ) }</p></header>{ render_messages( it_messages ) }<nav aria-label="List actions">{ lv_nav }</nav><form method="post" action="/dispatch"><input type="hidden" name="session_id" value="{ zcl_gg_host_html=>escape_attribute( iv_session_id ) }"><input type="hidden" name="page_id" value="{ zcl_gg_host_html=>escape_attribute( iv_page_id ) }">{ lv_body }</form>| ).
  ENDMETHOD.

  METHOD render_selection.
    DATA lv_body TYPE string.
    DATA lv_open_block TYPE i.
    DATA lv_title TYPE string.
    DATA ls_value TYPE zif_gg_selection_screen_types=>ty_value.
    DATA ls_state TYPE zif_gg_selection_screen_types=>ty_state.
    DATA lv_tab_action TYPE string.
    DATA ls_range TYPE zif_gg_selection_screen_types=>ty_range.
    DATA lv_element_id TYPE string.

    lv_body = |<section class="gg-selection" aria-label="Selection screen">|.
    lv_body = lv_body && |{ render_messages( it_messages ) }|.
    IF iv_help_text IS NOT INITIAL.
      lv_body = lv_body && |<aside class="gg-message gg-info" role="status">{ zcl_gg_host_html=>escape_text( iv_help_text ) }</aside>|.
    ENDIF.
    lv_body = lv_body && |<form method="post" action="/dispatch"><input type="hidden" name="session_id" value="{ zcl_gg_host_html=>escape_attribute( iv_session_id ) }"><input type="hidden" name="page_id" value="{ zcl_gg_host_html=>escape_attribute( iv_page_id ) }"><input type="hidden" name="gg_action" value="SUBMIT">|.

    IF it_tabs IS NOT INITIAL.
      lv_body = lv_body && |<nav role="tablist" aria-label="Selection tabs">|.
      LOOP AT it_tabs INTO DATA(ls_tab).
        lv_tab_action = |TAB:{ zcl_gg_host_html=>escape_attribute( CONV string( ls_tab-name ) ) }| && `|` && |{ zcl_gg_host_html=>escape_attribute( CONV string( ls_tab-ucomm ) ) }|.
        lv_body = lv_body && |<button type="submit" role="tab" name="gg_action" value="{ lv_tab_action }" aria-selected="{ COND string( WHEN ls_tab-selected = abap_true THEN `true` ELSE `false` ) }">{ zcl_gg_host_html=>escape_text( ls_tab-text ) }</button>|.
      ENDLOOP.
      lv_body = lv_body && |</nav>|.
    ENDIF.

    LOOP AT it_elements INTO DATA(ls_element).
      WHILE lv_open_block < ls_element-block_depth.
        lv_open_block = lv_open_block + 1.
        READ TABLE it_blocks INTO DATA(ls_block) INDEX lv_open_block.
        IF sy-subrc = 0.
          lv_title = ls_block-block-title.
        ELSE.
          CLEAR lv_title.
        ENDIF.
        lv_body = lv_body && |<fieldset><legend>{ zcl_gg_host_html=>escape_text( lv_title ) }</legend>|.
      ENDWHILE.
      WHILE lv_open_block > ls_element-block_depth.
        lv_body = lv_body && |</fieldset>|.
        lv_open_block = lv_open_block - 1.
      ENDWHILE.

      CASE ls_element-kind.
        WHEN 'PARAMETER'.
          lv_element_id = zcl_gg_host_html=>identifier(
            iv_scope   = 'selection-field'
            iv_program = CONV string( is_context-program )
            iv_name    = CONV string( ls_element-name ) ).
          DATA(lv_value) = ``.
          CLEAR ls_value.
          READ TABLE it_values INTO ls_value WITH KEY name = ls_element-name.
          IF sy-subrc = 0.
            lv_value = ls_value-value.
          ENDIF.
          CLEAR ls_state.
          READ TABLE it_states INTO ls_state WITH KEY name = ls_element-name.
          IF sy-subrc <> 0.
            CLEAR ls_state.
          ENDIF.
          lv_body = lv_body && |<div class="gg-field"><label for="{ zcl_gg_host_html=>escape_attribute( lv_element_id ) }">{ zcl_gg_host_html=>escape_text( ls_element-text ) }</label><input type="text" id="{ zcl_gg_host_html=>escape_attribute( lv_element_id ) }" name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" data-abap-name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" value="{ zcl_gg_host_html=>escape_attribute( lv_value ) }"{ state_attrs( ls_state ) }{ field_message_attrs( it_messages = it_messages iv_name = CONV string( ls_element-name ) ) }>|.
          IF ls_element-value_help = abap_true OR ls_state-value_help = abap_true.
            lv_body = lv_body && |<button type="submit" formnovalidate name="gg_action" value="VALUE_HELP:{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" aria-label="Value help for { zcl_gg_host_html=>escape_text( ls_element-text ) }">?</button>|.
          ENDIF.
          IF ls_state-search_help IS NOT INITIAL.
            lv_body = lv_body && |<button type="submit" formnovalidate name="gg_action" value="HELP:{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" aria-label="Field help for { zcl_gg_host_html=>escape_text( ls_element-text ) }">?</button>|.
          ENDIF.
          lv_body = lv_body && |</div>|.
          IF ls_value-ranges IS NOT INITIAL.
            lv_body = lv_body && render_selection_value_help( ls_value-ranges ).
          ENDIF.
        WHEN 'CHECKBOX'.
          lv_element_id = zcl_gg_host_html=>identifier( iv_scope = 'selection-field' iv_program = CONV string( is_context-program ) iv_name = CONV string( ls_element-name ) ).
          CLEAR: ls_value, ls_state.
          READ TABLE it_values INTO ls_value WITH KEY name = ls_element-name.
          READ TABLE it_states INTO ls_state WITH KEY name = ls_element-name.
          lv_body = lv_body && |<div class="gg-field"><input type="hidden" name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" value=""><input type="checkbox" id="{ zcl_gg_host_html=>escape_attribute( lv_element_id ) }" name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" data-abap-name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" value="X"{ COND string( WHEN ls_value-value = 'X' OR ls_value-value = '1' THEN ` checked` ELSE `` ) }{ state_attrs( ls_state ) }{ field_message_attrs( it_messages = it_messages iv_name = CONV string( ls_element-name ) ) }><label for="{ zcl_gg_host_html=>escape_attribute( lv_element_id ) }">{ zcl_gg_host_html=>escape_text( ls_element-text ) }</label></div>|.
        WHEN 'RADIOBUTTON'.
          lv_element_id = zcl_gg_host_html=>identifier( iv_scope = 'selection-field' iv_program = CONV string( is_context-program ) iv_name = CONV string( ls_element-name ) ).
          CLEAR: ls_value, ls_state.
          READ TABLE it_values INTO ls_value WITH KEY name = ls_element-name.
          READ TABLE it_states INTO ls_state WITH KEY name = ls_element-name.
          lv_body = lv_body && |<div class="gg-field"><input type="radio" id="{ zcl_gg_host_html=>escape_attribute( lv_element_id ) }" name="gg-radio-{ zcl_gg_host_html=>escape_attribute( CONV string( ls_state-group1 ) ) }" value="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" data-abap-name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }"{ COND string( WHEN ls_value-value = 'X' OR ls_value-value = '1' THEN ` checked` ELSE `` ) }{ state_attrs( ls_state ) }><label for="{ zcl_gg_host_html=>escape_attribute( lv_element_id ) }">{ zcl_gg_host_html=>escape_text( ls_element-text ) }</label></div>|.
        WHEN 'LISTBOX'.
          lv_element_id = zcl_gg_host_html=>identifier( iv_scope = 'selection-field' iv_program = CONV string( is_context-program ) iv_name = CONV string( ls_element-name ) ).
          CLEAR: ls_value, ls_state.
          READ TABLE it_values INTO ls_value WITH KEY name = ls_element-name.
          READ TABLE it_states INTO ls_state WITH KEY name = ls_element-name.
          lv_body = lv_body && |<div class="gg-field"><label for="{ zcl_gg_host_html=>escape_attribute( lv_element_id ) }">{ zcl_gg_host_html=>escape_text( ls_element-text ) }</label><select id="{ zcl_gg_host_html=>escape_attribute( lv_element_id ) }" name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" data-abap-name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }"{ state_attrs( ls_state ) }{ field_message_attrs( it_messages = it_messages iv_name = CONV string( ls_element-name ) ) }>|.
          LOOP AT ls_element-fixed_values INTO DATA(ls_fixed).
            lv_body = lv_body && |<option value="{ zcl_gg_host_html=>escape_attribute( ls_fixed-key ) }"{ COND string( WHEN ls_fixed-key = ls_value-value THEN ` selected` ELSE `` ) }>{ zcl_gg_host_html=>escape_text( ls_fixed-text ) }</option>|.
          ENDLOOP.
          lv_body = lv_body && |</select></div>|.
        WHEN 'SELECT_OPTION'.
          CLEAR: ls_value, ls_state, ls_range.
          READ TABLE it_values INTO ls_value WITH KEY name = ls_element-name.
          READ TABLE it_states INTO ls_state WITH KEY name = ls_element-name.
          READ TABLE ls_value-ranges INTO ls_range INDEX 1.
          DATA(lv_range_name) = CONV string( ls_element-name ).
          DATA(lv_low_name) = |{ lv_range_name }-LOW|.
          DATA(lv_high_name) = |{ lv_range_name }-HIGH|.
          lv_body = lv_body && |<fieldset class="gg-range"><legend>{ zcl_gg_host_html=>escape_text( ls_element-text ) }</legend><label for="{ zcl_gg_host_html=>escape_attribute( lv_low_name ) }">From</label><input type="text" id="{ zcl_gg_host_html=>escape_attribute( lv_low_name ) }" name="{ zcl_gg_host_html=>escape_attribute( lv_low_name ) }" value="{ zcl_gg_host_html=>escape_attribute( ls_range-low ) }"{ state_attrs( ls_state ) }>|.
          IF ls_element-no_intervals = abap_false.
            lv_body = lv_body && |<label for="{ zcl_gg_host_html=>escape_attribute( lv_high_name ) }">To</label><input type="text" id="{ zcl_gg_host_html=>escape_attribute( lv_high_name ) }" name="{ zcl_gg_host_html=>escape_attribute( lv_high_name ) }" value="{ zcl_gg_host_html=>escape_attribute( ls_range-high ) }"{ state_attrs( ls_state ) }>|.
          ENDIF.
          IF ls_element-value_help = abap_true.
            lv_body = lv_body && |<button type="submit" name="gg_action" value="VALUE_HELP:{ zcl_gg_host_html=>escape_attribute( lv_range_name ) }" aria-label="Value help for { zcl_gg_host_html=>escape_text( ls_element-text ) }">?</button>|.
          ENDIF.
          lv_body = lv_body && |<select name="{ zcl_gg_host_html=>escape_attribute( lv_range_name ) }-SIGN" aria-label="Sign"><option value="I"{ COND string( WHEN ls_range-sign = 'I' THEN ` selected` ELSE `` ) }>Include</option><option value="E"{ COND string( WHEN ls_range-sign = 'E' THEN ` selected` ELSE `` ) }>Exclude</option></select><select name="{ zcl_gg_host_html=>escape_attribute( lv_range_name ) }-OPTION" aria-label="Option"><option value="EQ"{ COND string( WHEN ls_range-option = 'EQ' THEN ` selected` ELSE `` ) }>=</option><option value="BT"{ COND string( WHEN ls_range-option = 'BT' THEN ` selected` ELSE `` ) }>Between</option><option value="CP"{ COND string( WHEN ls_range-option = 'CP' THEN ` selected` ELSE `` ) }>Contains</option></select></fieldset>|.
        WHEN 'PUSHBUTTON' OR 'FUNCTION_KEY'.
          lv_body = lv_body && |<button type="submit" name="gg_ucomm" value="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-ucomm ) ) }">{ zcl_gg_host_html=>escape_text( ls_element-text ) }</button>|.
        WHEN 'COMMENT'.
          lv_body = lv_body && |<p>{ zcl_gg_host_html=>escape_text( ls_element-text ) }</p>|.
        WHEN 'ULINE'.
          lv_body = lv_body && |<hr>|.
        WHEN 'SKIP'.
          lv_body = lv_body && |<div aria-hidden="true">&nbsp;</div>|.
        WHEN 'TAB'.
          CONTINUE.
        WHEN 'SCREEN'.
          lv_body = lv_body && |<button type="submit" name="gg_action" value="SCREEN:{ ls_element-screen }">Screen { ls_element-screen }</button>|.
        WHEN OTHERS.
          CONTINUE.
      ENDCASE.
    ENDLOOP.
    WHILE lv_open_block > 0.
      lv_body = lv_body && |</fieldset>|.
      lv_open_block = lv_open_block - 1.
    ENDWHILE.
    lv_body = lv_body && |<div class="gg-field"><button type="submit" name="gg_ucomm" value="ONLI">Continue</button><button type="submit" name="gg_action" value="EXIT">Cancel</button></div></form></section>|.
    rv_html = zcl_gg_host_html=>document(
      iv_session_id = iv_session_id
      iv_page_id    = iv_page_id
      iv_kind       = zif_gg_host_html_v1=>page_selection
      iv_title      = iv_title
      iv_csp_nonce  = is_context-csp_nonce
      iv_body       = |<header><h1>{ zcl_gg_host_html=>escape_text( iv_title ) }</h1></header>{ lv_body }| ).
  ENDMETHOD.

  METHOD render_dynpro.
    DATA lv_body TYPE string.
    DATA lv_height TYPE i.
    DATA lv_title TYPE string.
    DATA ls_value TYPE zif_gg_dynpro_types_v1=>ty_value.
    DATA ls_state TYPE zif_gg_dynpro_types_v1=>ty_state.
    DATA lv_row TYPE i.
    DATA lv_table_body TYPE string.
    DATA lv_cell_name TYPE string.
    DATA lv_cell_value TYPE string.

    lv_title = is_screen-title.
    IF iv_title IS NOT INITIAL.
      lv_title = iv_title.
    ENDIF.

    lv_height = is_screen-height.
    IF lv_height <= 0.
      lv_height = 240.
    ENDIF.
    lv_body = |<section class="gg-dynpro" aria-label="Dynpro { zcl_gg_host_html=>escape_text( lv_title ) }" data-screen="{ is_screen-number }" data-modal="{ COND string( WHEN is_screen-modal = abap_true THEN `true` ELSE `false` ) }" data-cursor-field="{ zcl_gg_host_html=>escape_attribute( CONV string( is_cursor-field ) ) }" data-cursor-row="{ is_cursor-row }" style="min-height:{ lv_height }px">|.
    lv_body = lv_body && |<header><h1>{ zcl_gg_host_html=>escape_text( lv_title ) }</h1><p class="gg-dynpro-status">{ zcl_gg_host_html=>escape_text( CONV string( is_status-status ) ) }</p></header>|.
    lv_body = lv_body && |{ render_messages( it_messages ) }|.
    IF iv_help_text IS NOT INITIAL.
      lv_body = lv_body && |<aside class="gg-message gg-info" role="status">{ zcl_gg_host_html=>escape_text( iv_help_text ) }</aside>|.
    ENDIF.
    IF it_help_values IS NOT INITIAL.
      lv_body = lv_body && |<section class="gg-value-help" aria-label="Value help"><ul>|.
      LOOP AT it_help_values INTO DATA(ls_help_value).
        lv_body = lv_body && |<li data-name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_help_value-name ) ) }">{ zcl_gg_host_html=>escape_text( ls_help_value-value ) }</li>|.
      ENDLOOP.
      lv_body = lv_body && |</ul></section>|.
    ENDIF.
    lv_body = lv_body && |<form method="post" action="/dispatch"><input type="hidden" name="session_id" value="{ zcl_gg_host_html=>escape_attribute( iv_session_id ) }"><input type="hidden" name="page_id" value="{ zcl_gg_host_html=>escape_attribute( iv_page_id ) }"><input type="hidden" name="gg_action" value="SUBMIT">|.
    LOOP AT it_controls INTO DATA(ls_control)
        WHERE screen = is_screen-number.
      CLEAR: ls_value, ls_state.
      READ TABLE it_values INTO ls_value
        WITH KEY container = `` name = ls_control-name row = 0.
      READ TABLE it_states INTO ls_state
        WITH KEY container = `` name = ls_control-name row = 0.
      DATA(lv_style) = |left:{ ls_control-position-column }px;top:{ ls_control-position-row }px;|.
      IF ls_control-position-width > 0.
        lv_style = lv_style && |width:{ ls_control-position-width }px;|.
      ENDIF.
      IF ls_control-position-height > 0.
        lv_style = lv_style && |height:{ ls_control-position-height }px;|.
      ENDIF.
      DATA(lv_id) = zcl_gg_host_html=>identifier(
        iv_scope   = 'dynpro-control'
        iv_program = CONV string( is_context-program )
        iv_name    = CONV string( ls_control-name ) ).
      DATA(lv_attrs) = dynpro_attrs( ls_state ).
      IF is_cursor-field = ls_control-name.
        lv_attrs = lv_attrs && ` autofocus`.
      ENDIF.
      CASE ls_control-kind.
        WHEN 'INPUT'.
          lv_body = lv_body && |<label class="gg-dynpro-control" style="{ lv_style }" for="{ zcl_gg_host_html=>escape_attribute( lv_id ) }"><span class="gg-visually-hidden">{ zcl_gg_host_html=>escape_text( CONV string( ls_control-name ) ) }</span><input id="{ zcl_gg_host_html=>escape_attribute( lv_id ) }" name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_control-name ) ) }" data-abap-name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_control-name ) ) }" value="{ zcl_gg_host_html=>escape_attribute( ls_value-value ) }"{ COND string( WHEN ls_control-password = abap_true THEN ` type="password"` ELSE ` type="text"` ) }{ lv_attrs }></label>|.
          IF ls_control-value_help = abap_true.
            lv_body = lv_body && |<button type="submit" formnovalidate name="gg_action" value="VALUE_HELP:{ zcl_gg_host_html=>escape_attribute( CONV string( ls_control-name ) ) }" aria-label="Value help for { zcl_gg_host_html=>escape_text( CONV string( ls_control-name ) ) }">?</button>|.
          ENDIF.
          IF ls_control-search_help IS NOT INITIAL.
            lv_body = lv_body && |<button type="submit" formnovalidate name="gg_action" value="HELP:{ zcl_gg_host_html=>escape_attribute( CONV string( ls_control-name ) ) }" aria-label="Field help for { zcl_gg_host_html=>escape_text( CONV string( ls_control-name ) ) }">?</button>|.
          ENDIF.
        WHEN 'OUTPUT'.
          lv_body = lv_body && |<output class="gg-dynpro-control" style="{ lv_style }" id="{ zcl_gg_host_html=>escape_attribute( lv_id ) }">{ zcl_gg_host_html=>escape_text( ls_value-value ) }</output>|.
        WHEN 'TEXT'.
          lv_body = lv_body && |<span class="gg-dynpro-control" style="{ lv_style }">{ zcl_gg_host_html=>escape_text( ls_control-text ) }</span>|.
        WHEN 'PUSHBUTTON'.
          lv_body = lv_body && |<button class="gg-dynpro-control" style="{ lv_style }" type="submit" name="gg_ucomm" value="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_control-ucomm ) ) }"{ lv_attrs }>{ zcl_gg_host_html=>escape_text( ls_control-text ) }</button>|.
        WHEN 'CHECKBOX'.
          lv_body = lv_body && |<label class="gg-dynpro-control" style="{ lv_style }"><input type="checkbox" name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_control-name ) ) }" data-abap-name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_control-name ) ) }" value="X"{ COND string( WHEN ls_value-value = 'X' OR ls_value-value = '1' THEN ` checked` ELSE `` ) }{ lv_attrs }>{ zcl_gg_host_html=>escape_text( ls_control-text ) }</label>|.
        WHEN 'RADIOBUTTON'.
          lv_body = lv_body && |<label class="gg-dynpro-control" style="{ lv_style }"><input type="radio" name="gg-radio-{ zcl_gg_host_html=>escape_attribute( CONV string( ls_control-group ) ) }" data-abap-name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_control-name ) ) }" value="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_control-name ) ) }"{ COND string( WHEN ls_value-value = 'X' OR ls_value-value = '1' THEN ` checked` ELSE `` ) }{ lv_attrs }>{ zcl_gg_host_html=>escape_text( ls_control-text ) }</label>|.
        WHEN 'LISTBOX'.
          lv_body = lv_body && |<select class="gg-dynpro-control" style="{ lv_style }" id="{ zcl_gg_host_html=>escape_attribute( lv_id ) }" name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_control-name ) ) }" data-abap-name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_control-name ) ) }"{ lv_attrs }>|.
          LOOP AT ls_control-fixed_values INTO DATA(ls_fixed).
            lv_body = lv_body && |<option value="{ zcl_gg_host_html=>escape_attribute( ls_fixed-key ) }"{ COND string( WHEN ls_fixed-key = ls_value-value THEN ` selected` ELSE `` ) }>{ zcl_gg_host_html=>escape_text( ls_fixed-text ) }</option>|.
          ENDLOOP.
          lv_body = lv_body && |</select>|.
        WHEN 'BOX'.
          lv_body = lv_body && |<fieldset class="gg-dynpro-control" style="{ lv_style }"><legend>{ zcl_gg_host_html=>escape_text( ls_control-text ) }</legend></fieldset>|.
        WHEN 'TABSTRIP'.
          lv_body = lv_body && |<div class="gg-dynpro-control" style="{ lv_style }" role="tablist" aria-label="{ zcl_gg_host_html=>escape_text( CONV string( ls_control-name ) ) }">|.
          LOOP AT it_controls INTO DATA(ls_tab)
              WHERE screen = is_screen-number AND kind = 'TAB'
                AND parent = ls_control-name.
            lv_body = lv_body && |<button type="submit" role="tab" name="gg_action" value="| && |TAB:{ zcl_gg_host_html=>escape_attribute( CONV string( ls_tab-name ) ) }| && `|` && |{ zcl_gg_host_html=>escape_attribute( CONV string( ls_tab-ucomm ) ) }" aria-selected="{ COND string( WHEN sy-tabix = 1 THEN `true` ELSE `false` ) }" data-target-screen="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_tab-subscreen ) ) }">{ zcl_gg_host_html=>escape_text( ls_tab-text ) }</button>|.
          ENDLOOP.
          lv_body = lv_body && |</div>|.
        WHEN 'TAB'.
          CONTINUE.
        WHEN 'SUBSCREEN_AREA'.
          lv_body = lv_body && |<section class="gg-dynpro-control" style="{ lv_style }" data-subscreen-area="{ zcl_gg_host_html=>escape_attribute( lv_id ) }" role="region" aria-label="Subscreen area { zcl_gg_host_html=>escape_text( CONV string( ls_control-name ) ) }"></section>|.
        WHEN 'TABLE_CONTROL'.
          lv_table_body = |<table><caption>{ zcl_gg_host_html=>escape_text( CONV string( ls_control-name ) ) }</caption><thead><tr>|.
          LOOP AT it_controls INTO DATA(ls_column)
              WHERE screen = is_screen-number AND kind = 'TABLE_COLUMN'
                AND parent = ls_control-name.
            lv_table_body = lv_table_body && |<th scope="col" style="width:{ ls_column-column_width }px">{ zcl_gg_host_html=>escape_text( ls_column-column_title ) }</th>|.
          ENDLOOP.
          lv_table_body = lv_table_body && |</tr></thead><tbody>|.
          lv_row = 1.
          WHILE lv_row <= ls_control-visible_rows.
            lv_table_body = lv_table_body && |<tr data-row="{ lv_row }">|.
            LOOP AT it_controls INTO ls_column
                WHERE screen = is_screen-number AND kind = 'TABLE_COLUMN'
                  AND parent = ls_control-name.
              CLEAR lv_cell_value.
              READ TABLE it_values INTO DATA(ls_cell)
                WITH KEY container = ls_control-name
                         name = ls_column-name
                         row = lv_row.
              IF sy-subrc = 0.
                lv_cell_value = ls_cell-value.
              ENDIF.
              lv_cell_name = |gg-cell-{ CONV string( ls_control-name ) }-{ CONV string( ls_column-name ) }-{ lv_row }|.
              IF ls_column-input = abap_true.
                lv_table_body = lv_table_body && |<td><input type="text" name="{ zcl_gg_host_html=>escape_attribute( lv_cell_name ) }" value="{ zcl_gg_host_html=>escape_attribute( lv_cell_value ) }"{ COND string( WHEN ls_column-required = abap_true THEN ` required` ELSE `` ) }></td>|.
              ELSE.
                lv_table_body = lv_table_body && |<td><output>{ zcl_gg_host_html=>escape_text( lv_cell_value ) }</output></td>|.
              ENDIF.
            ENDLOOP.
            lv_table_body = lv_table_body && |</tr>|.
            lv_row = lv_row + 1.
          ENDWHILE.
          lv_table_body = lv_table_body && |</tbody></table>|.
          lv_body = lv_body && |<section class="gg-dynpro-control" style="{ lv_style }" data-table-control="{ zcl_gg_host_html=>escape_attribute( lv_id ) }" data-selection-mode="{ zcl_gg_host_html=>escape_attribute( ls_control-selection_mode ) }" data-hscroll="{ COND string( WHEN ls_control-with_hscroll = abap_true THEN `true` ELSE `false` ) }" data-vscroll="{ COND string( WHEN ls_control-with_vscroll = abap_true THEN `true` ELSE `false` ) }">{ lv_table_body }</section>|.
        WHEN 'CUSTOM_CONTROL'.
          lv_body = lv_body && |<div class="gg-dynpro-control" style="{ lv_style }" data-custom-control="{ zcl_gg_host_html=>escape_attribute( lv_id ) }" role="region" aria-label="Custom control { zcl_gg_host_html=>escape_text( CONV string( ls_control-name ) ) }"></div>|.
        WHEN OTHERS.
          lv_body = lv_body && |<div class="gg-dynpro-control" style="{ lv_style }">{ zcl_gg_host_html=>escape_text( ls_control-text ) }</div>|.
      ENDCASE.
    ENDLOOP.
    lv_body = lv_body && |<div class="gg-field"><button type="submit" formnovalidate name="gg_ucomm" value="BACK">Back</button></div></form></section>|.
    rv_html = zcl_gg_host_html=>document(
      iv_session_id = iv_session_id
      iv_page_id    = iv_page_id
      iv_kind       = zif_gg_host_html_v1=>page_dynpro
      iv_title      = lv_title
      iv_csp_nonce  = is_context-csp_nonce
      iv_body       = lv_body ).
  ENDMETHOD.

  METHOD render_message.
    rv_html = zcl_gg_host_html=>document(
      iv_session_id = iv_session_id
      iv_page_id    = iv_page_id
      iv_kind       = zif_gg_host_html_v1=>page_message
      iv_title      = iv_title
      iv_csp_nonce  = is_context-csp_nonce
      iv_body       = |<header><h1>{ zcl_gg_host_html=>escape_text( iv_title ) }</h1></header>{ render_messages( it_messages ) }<p>{ zcl_gg_host_html=>escape_text( iv_text ) }</p>| ).
  ENDMETHOD.

  METHOD render_terminal.
    rv_html = zcl_gg_host_html=>document(
      iv_session_id = iv_session_id
      iv_page_id    = iv_page_id
      iv_kind       = zif_gg_host_html_v1=>page_terminal
      iv_title      = iv_title
      iv_csp_nonce  = is_context-csp_nonce
      iv_body       = |<header><h1>{ zcl_gg_host_html=>escape_text( iv_title ) }</h1></header>{ render_messages( it_messages ) }<p class="gg-terminal">{ zcl_gg_host_html=>escape_text( iv_text ) }</p>| ).
  ENDMETHOD.

  METHOD render_navigation.
    rv_html = zcl_gg_host_html=>document(
      iv_session_id = iv_session_id
      iv_page_id    = iv_page_id
      iv_kind       = zif_gg_host_html_v1=>page_navigation
      iv_title      = iv_title
      iv_csp_nonce  = is_context-csp_nonce
      iv_body       = |<header><h1>{ zcl_gg_host_html=>escape_text( iv_title ) }</h1></header><section class="gg-navigation-page" aria-label="Navigation transition"><p data-navigation-kind="{ zcl_gg_host_html=>escape_attribute( is_navigation-kind ) }">Continue to <strong>{ zcl_gg_host_html=>escape_text( is_navigation-target ) }</strong>.</p><form method="post" action="/dispatch"><input type="hidden" name="session_id" value="{ zcl_gg_host_html=>escape_attribute( iv_session_id ) }"><input type="hidden" name="page_id" value="{ zcl_gg_host_html=>escape_attribute( iv_page_id ) }"><input type="hidden" name="gg_action" value="SUBMIT"><button type="submit">Continue</button></form></section>| ).
  ENDMETHOD.

  METHOD render_messages.
    LOOP AT it_messages INTO DATA(ls_message).
      DATA(lv_message_id) = zcl_gg_host_html=>identifier(
        iv_scope = 'message'
        iv_name  = CONV string( ls_message-field )
        iv_index = sy-tabix ).
      DATA(lv_display_type) = COND zif_gg_session_types_v1=>ty_message_type(
        WHEN ls_message-display_like IS INITIAL THEN ls_message-type
        ELSE ls_message-display_like ).
      rv_html = rv_html && |<div id="{ zcl_gg_host_html=>escape_attribute( lv_message_id ) }" class="gg-message { zcl_gg_host_html=>message_class( lv_display_type ) }" role="alert" aria-live="polite" data-field="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_message-field ) ) }">{ zcl_gg_host_html=>escape_text( ls_message-text ) }</div>|.
    ENDLOOP.
  ENDMETHOD.

  METHOD field_message_attrs.
    READ TABLE it_messages INTO DATA(ls_message)
      WITH KEY field = iv_name.
    IF sy-subrc = 0.
      DATA(lv_message_id) = zcl_gg_host_html=>identifier(
        iv_scope = 'message'
        iv_name  = iv_name
        iv_index = sy-tabix ).
      rv_attrs = | aria-describedby="{ zcl_gg_host_html=>escape_attribute( lv_message_id ) }" aria-invalid="true" autofocus|.
    ENDIF.
  ENDMETHOD.

  METHOD render_selection_value_help.
    rv_html = |<aside class="gg-value-help" role="status" aria-label="Value help"><ul>|.
    LOOP AT it_ranges INTO DATA(ls_range).
      DATA(lv_value) = ls_range-low.
      IF ls_range-high IS NOT INITIAL.
        lv_value = lv_value && | - { ls_range-high }|.
      ENDIF.
      rv_html = rv_html && |<li>{ zcl_gg_host_html=>escape_text( lv_value ) }</li>|.
    ENDLOOP.
    rv_html = rv_html && `</ul></aside>`.
  ENDMETHOD.

  METHOD spaces.
    IF iv_count > 0.
      rv_text = repeat( val = ` ` occ = iv_count ).
    ENDIF.
  ENDMETHOD.

  METHOD state_attrs.
    IF is_state-visible = abap_false OR is_state-no_display = abap_true.
      rv_attrs = rv_attrs && ` hidden`.
    ENDIF.
    IF is_state-enabled = abap_false.
      rv_attrs = rv_attrs && ` disabled`.
    ENDIF.
    IF is_state-obligatory = abap_true.
      rv_attrs = rv_attrs && ` required`.
    ENDIF.
  ENDMETHOD.

  METHOD dynpro_attrs.
    IF is_state-visible = abap_false.
      rv_attrs = rv_attrs && ` hidden`.
    ENDIF.
    IF is_state-enabled = abap_false.
      rv_attrs = rv_attrs && ` disabled`.
    ENDIF.
    IF is_state-required = abap_true.
      rv_attrs = rv_attrs && ` required`.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
