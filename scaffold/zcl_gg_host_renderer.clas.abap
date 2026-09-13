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

    "! How a sapevent anchor of an HTML viewer document reaches this host. It
    "! is the same dispatch the rest of the page posts to, so a click inside
    "! the control produces one host page like every other command, and the
    "! function code is still checked against the status of the current page.
    CLASS-METHODS sapevent_transport
      IMPORTING
        iv_session_id      TYPE string
        iv_page_id         TYPE string
      RETURNING
        VALUE(rs_sapevent) TYPE cl_gui_control=>ty_sapevent.

    CLASS-METHODS render_list
      IMPORTING
        iv_session_id    TYPE string
        iv_page_id       TYPE string
        iv_title         TYPE string
        it_lines         TYPE zcl_gg_host_list=>ty_render_lines
        iv_visible_page  TYPE i OPTIONAL
        is_context       TYPE zif_gg_host_html_v1=>ty_renderer_context OPTIONAL
        is_status        TYPE zif_gg_session_types_v1=>ty_gui_status OPTIONAL
        it_actions       TYPE zif_gg_host_html_v1=>ty_actions OPTIONAL
        it_messages      TYPE zcl_gg_host_session=>ty_messages OPTIONAL
        iv_controls_html TYPE string OPTIONAL
      RETURNING
        VALUE(rv_html)   TYPE string.

    CLASS-METHODS render_selection
      IMPORTING
        iv_session_id        TYPE string
        iv_page_id           TYPE string
        iv_title             TYPE string
        it_values            TYPE zif_gg_selection_screen_types=>ty_values
        it_states            TYPE zif_gg_selection_screen_types=>ty_states
        it_blocks            TYPE zcl_gg_host_screen=>ty_blocks
        it_elements          TYPE zcl_gg_host_screen=>ty_elements
        it_tabs              TYPE zcl_gg_host_screen=>ty_tabs OPTIONAL
        is_dynamic_selection TYPE zif_gg_compatibility_v1=>ty_dynamic_selection OPTIONAL
        is_context           TYPE zif_gg_host_html_v1=>ty_renderer_context OPTIONAL
        is_status            TYPE zif_gg_session_types_v1=>ty_gui_status OPTIONAL
        it_messages          TYPE zcl_gg_host_session=>ty_messages OPTIONAL
        iv_help_text         TYPE string OPTIONAL
        iv_help_name         TYPE string OPTIONAL
      RETURNING
        VALUE(rv_html)       TYPE string.

    CLASS-METHODS render_dynpro
      IMPORTING
        iv_session_id     TYPE string
        iv_page_id        TYPE string
        is_screen         TYPE zif_gg_dynpro_types_v1=>ty_screen
        iv_title          TYPE string OPTIONAL
        is_modal_position TYPE zif_gg_session_types_v1=>ty_modal_position OPTIONAL
        is_status         TYPE zif_gg_session_types_v1=>ty_gui_status OPTIONAL
        is_cursor         TYPE zif_gg_session_types_v1=>ty_dialog_cursor OPTIONAL
        it_controls       TYPE zcl_gg_host_dynpro_builder=>ty_controls
        it_values         TYPE zif_gg_dynpro_types_v1=>ty_values
        it_states         TYPE zif_gg_dynpro_types_v1=>ty_states
        is_context        TYPE zif_gg_host_html_v1=>ty_renderer_context OPTIONAL
        it_messages       TYPE zcl_gg_host_session=>ty_messages OPTIONAL
        iv_help_text      TYPE string OPTIONAL
        iv_help_name      TYPE string OPTIONAL
        it_help_values    TYPE zif_gg_dynpro_types_v1=>ty_values OPTIONAL
        is_popup          TYPE zif_gg_compatibility_v1=>ty_popup OPTIONAL
        io_menu           TYPE REF TO cl_ctmenu OPTIONAL
        iv_menu_field     TYPE string OPTIONAL
      RETURNING
        VALUE(rv_html)    TYPE string.

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
        iv_readonly     TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rv_attrs) TYPE string.

* Sizes and aligns an input from the type the program declared, so a date, an
* integer and a long text stop rendering at one shared width. Any caller class
* is merged in, because a second class attribute would be ignored.
    CLASS-METHODS field_type_attrs
      IMPORTING
        is_data_type    TYPE zif_gg_selection_screen_types=>ty_data_type
        iv_extra_class  TYPE string OPTIONAL
      RETURNING
        VALUE(rv_attrs) TYPE string.

    CLASS-METHODS data_type_class
      IMPORTING
        iv_type         TYPE string
        iv_extra_class  TYPE string OPTIONAL
      RETURNING
        VALUE(rv_class) TYPE string.

    CLASS-METHODS dynpro_type_attrs
      IMPORTING
        is_data_type    TYPE zif_gg_dynpro_types_v1=>ty_data_type
        iv_extra_class  TYPE string OPTIONAL
      RETURNING
        VALUE(rv_attrs) TYPE string.

    CLASS-METHODS external_value_attrs
      IMPORTING
        iv_value        TYPE string
        iv_type         TYPE string
      RETURNING
        VALUE(rv_attrs) TYPE string.

    CLASS-METHODS dynpro_attrs
      IMPORTING
        is_state        TYPE zif_gg_dynpro_types_v1=>ty_state
        iv_readonly     TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rv_attrs) TYPE string.

    CLASS-METHODS field_message_attrs
      IMPORTING
        it_messages     TYPE zcl_gg_host_session=>ty_messages
        iv_name         TYPE string
      RETURNING
        VALUE(rv_attrs) TYPE string.

    CLASS-METHODS active_selection_screen
      IMPORTING
        iv_default       TYPE string
        it_tabs          TYPE zcl_gg_host_screen=>ty_tabs
      RETURNING
        VALUE(rv_screen) TYPE string.

    CLASS-METHODS visible_selection_blocks
      IMPORTING
        iv_screen        TYPE string
        it_blocks        TYPE zcl_gg_host_screen=>ty_blocks
      RETURNING
        VALUE(rt_blocks) TYPE zcl_gg_host_screen=>ty_blocks.

    CLASS-METHODS selection_help_section
      IMPORTING
        iv_help_text   TYPE string
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS render_dynpro_table
      IMPORTING
        is_screen      TYPE zif_gg_dynpro_types_v1=>ty_screen
        is_control     TYPE zcl_gg_host_dynpro_builder=>ty_control_record
        iv_style       TYPE string
        it_controls    TYPE zcl_gg_host_dynpro_builder=>ty_controls
        it_values      TYPE zif_gg_dynpro_types_v1=>ty_values
        it_states      TYPE zif_gg_dynpro_types_v1=>ty_states
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS render_dynpro_controls
      IMPORTING
        is_screen        TYPE zif_gg_dynpro_types_v1=>ty_screen
        iv_header_height TYPE i
        iv_active_tab    TYPE string
        is_cursor        TYPE zif_gg_session_types_v1=>ty_dialog_cursor
        is_context       TYPE zif_gg_host_html_v1=>ty_renderer_context
        it_controls      TYPE zcl_gg_host_dynpro_builder=>ty_controls
        it_values        TYPE zif_gg_dynpro_types_v1=>ty_values
        it_states        TYPE zif_gg_dynpro_types_v1=>ty_states
        it_messages      TYPE zcl_gg_host_session=>ty_messages
      RETURNING
        VALUE(rv_html)   TYPE string.

    CLASS-METHODS render_dynpro_control
      IMPORTING
        is_screen      TYPE zif_gg_dynpro_types_v1=>ty_screen
        is_control     TYPE zcl_gg_host_dynpro_builder=>ty_control_record
        is_value       TYPE zif_gg_dynpro_types_v1=>ty_value
        is_state       TYPE zif_gg_dynpro_types_v1=>ty_state
        iv_style       TYPE string
        iv_id          TYPE string
        iv_attrs       TYPE string
        iv_state_class TYPE string
        iv_active_tab  TYPE string
        it_controls    TYPE zcl_gg_host_dynpro_builder=>ty_controls
        it_values      TYPE zif_gg_dynpro_types_v1=>ty_values
        it_states      TYPE zif_gg_dynpro_types_v1=>ty_states
        it_messages    TYPE zcl_gg_host_session=>ty_messages
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS subscreen_for_area
      IMPORTING
        is_area          TYPE zcl_gg_host_dynpro_builder=>ty_control_record
        it_values        TYPE zif_gg_dynpro_types_v1=>ty_values
      RETURNING
        VALUE(rv_screen) TYPE zif_gg_dynpro_types_v1=>ty_screen_number.

    CLASS-METHODS render_selection_value_help
      IMPORTING
        iv_name        TYPE string OPTIONAL
        it_ranges      TYPE zif_gg_selection_screen_types=>ty_ranges
      RETURNING
        VALUE(rv_html) TYPE string.

* Renders the search help affordance for one input: a magnifier button that the
* stylesheet reveals only while the surrounding field has focus, and that the
* shell's F4 key presses for the focused field.
    CLASS-METHODS value_help_button
      IMPORTING
        iv_name        TYPE string
        iv_label       TYPE string
        iv_value_help  TYPE abap_bool
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS render_dynpro_popup
      IMPORTING
        is_popup       TYPE zif_gg_compatibility_v1=>ty_popup
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS render_context_menu
      IMPORTING
        io_menu        TYPE REF TO cl_ctmenu
        iv_field       TYPE string
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS render_context_menu_items
      IMPORTING
        it_items       TYPE zcl_gg_context_menu_state=>ty_items
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS render_dynamic_selection
      IMPORTING
        is_selection   TYPE zif_gg_compatibility_v1=>ty_dynamic_selection
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS range_editor_button
      IMPORTING
        iv_name        TYPE string
        iv_label       TYPE string
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS range_row_actions
      IMPORTING
        iv_name         TYPE string
        iv_label        TYPE string
        iv_first        TYPE abap_bool
        iv_no_extension TYPE abap_bool
        iv_value_help   TYPE abap_bool
      RETURNING
        VALUE(rv_html)  TYPE string.

    CLASS-METHODS render_range_editor
      IMPORTING
        iv_name         TYPE string
        iv_label        TYPE string
        it_ranges       TYPE zif_gg_selection_screen_types=>ty_ranges
        iv_enabled      TYPE abap_bool
        iv_no_intervals TYPE abap_bool
      RETURNING
        VALUE(rv_html)  TYPE string.

    CLASS-METHODS dynpro_geometry
      IMPORTING
        iv_height        TYPE i
        iv_header_height TYPE i
        is_screen        TYPE zif_gg_dynpro_types_v1=>ty_screen
        it_controls      TYPE zcl_gg_host_dynpro_builder=>ty_controls
      CHANGING
        cv_render_height TYPE i.
ENDCLASS.

CLASS zcl_gg_host_renderer IMPLEMENTATION.

  METHOD with_navigation.
    rv_html = iv_html.
    IF is_navigation-kind IS INITIAL OR is_navigation-target IS INITIAL.
      RETURN.
    ENDIF.
    IF is_navigation-modal = abap_true.
      DATA(lv_modal) = |<div class="gg-modal-backdrop" data-navigation-kind="{ zcl_gg_host_html=>escape_attribute( is_navigation-kind ) }" data-navigation-target="{ zcl_gg_host_html=>escape_attribute( is_navigation-target ) }"><section class="gg-modal-panel" role="dialog" aria-modal="true" aria-label="Selection screen { zcl_gg_host_html=>escape_text( is_navigation-target ) }"><header class="gg-modal-header"><span>Transition target: { zcl_gg_host_html=>escape_text( is_navigation-target ) }</span><span class="gg-modal-kind">{ zcl_gg_host_html=>escape_text( is_navigation-kind ) }</span>{ COND string( WHEN is_navigation-kind = zcx_gg_control_flow=>kind_call_selection_screen THEN |<button type="submit" name="gg_action" value="SCREEN:{ zcl_gg_host_html=>escape_attribute( is_navigation-target ) }" form="gg-host-form">Screen { zcl_gg_host_html=>escape_text( is_navigation-target ) }</button>| ELSE `` ) }</header>|.
      REPLACE FIRST OCCURRENCE OF '<main id="gg-main-content" aria-labelledby="wb-page-title">' IN rv_html WITH |<main id="gg-main-content" aria-labelledby="wb-page-title">{ lv_modal }|.
      REPLACE FIRST OCCURRENCE OF '</main>' IN rv_html WITH '</section></div></main>'.
    ELSE.
      DATA(lv_navigation) = |<nav class="gg-navigation" aria-label="Host navigation" data-navigation-kind="{ zcl_gg_host_html=>escape_attribute( is_navigation-kind ) }" data-navigation-modal="false"><span>Transition target: { zcl_gg_host_html=>escape_text( is_navigation-target ) }</span>{ COND string( WHEN is_navigation-kind = zcx_gg_control_flow=>kind_call_selection_screen THEN |<button type="submit" name="gg_action" value="SCREEN:{ zcl_gg_host_html=>escape_attribute( is_navigation-target ) }" form="gg-host-form">Screen { zcl_gg_host_html=>escape_text( is_navigation-target ) }</button>| ELSE `` ) }</nav>|.
      REPLACE FIRST OCCURRENCE OF '<main id="gg-main-content" aria-labelledby="wb-page-title">' IN rv_html WITH |<main id="gg-main-content" aria-labelledby="wb-page-title">{ lv_navigation }|.
    ENDIF.
  ENDMETHOD.

  METHOD sapevent_transport.
    rs_sapevent = VALUE #(
      url          = '/dispatch'
      action_field = 'ucomm'
      fields       = VALUE #(
        ( name = 'session_id' value = iv_session_id )
        ( name = 'page_id'    value = iv_page_id )
        ( name = 'action'     value = zif_gg_host_html_v1=>action_command ) ) ).
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
    DATA lv_line_state_class TYPE string.

    lv_body = |<section class="gg-work-area" aria-label="List work area"><section class="gg-list" aria-label="List output">|.
    LOOP AT it_lines INTO DATA(ls_line).
      IF iv_visible_page > 0 AND ls_line-page <> iv_visible_page.
        CONTINUE.
      ENDIF.
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
        lv_line = lv_line && |<span class="gg-list-fragment { zcl_gg_host_html=>css_class( ls_fragment-format ) }" data-column="{ ls_fragment-position }"{ zcl_gg_host_html=>attribute( iv_name     = `title`
                                                                                                                                                                                        iv_value    = lv_fragment_title
                                                                                                                                                                                        iv_optional = abap_true ) }>{ lv_fragment_html }</span>|.
        lv_column = ls_fragment-position + strlen( ls_fragment-text ).
      ENDLOOP.
      IF ls_line-fragments IS INITIAL.
        lv_line = zcl_gg_host_html=>escape_text( ls_line-text ).
      ENDIF.

      lv_line_id = zcl_gg_host_html=>identifier(
        iv_scope   = 'list-line'
        iv_program = CONV string( is_context-program )
        iv_index   = ls_line-index ).
      lv_line_state_class = |{ COND string( WHEN ls_line-fragments IS INITIAL
        THEN zcl_gg_host_html=>css_class( ls_line-format ) ELSE `` ) } { zcl_gg_host_html=>state_class(
        iv_selected = ls_line-selected
        iv_changed  = ls_line-changed ) }|.
      IF ls_line-fields IS INITIAL.
        lv_body = lv_body && |<div id="{ zcl_gg_host_html=>escape_attribute( lv_line_id ) }" class="gg-list-line { lv_line_state_class }" data-line-index="{ ls_line-index }" aria-current="{ COND string( WHEN ls_line-selected = abap_true THEN `true` ELSE `false` ) }">{ lv_line }</div>|.
      ELSE.
        lv_body = lv_body && |<div id="{ zcl_gg_host_html=>escape_attribute( lv_line_id ) }" class="gg-list-line { lv_line_state_class }" data-line-index="{ ls_line-index }" data-action-token="{ zcl_gg_host_html=>escape_attribute( ls_line-token ) }"><button class="{ zcl_gg_host_html=>state_class( iv_selected = ls_line-selected ) }" type="submit" name="gg_action" value="| && |LINE:{ ls_line-index }| && `|` && |{ zcl_gg_host_html=>escape_attribute( ls_line-token ) }| && |" aria-label="Select line { ls_line-index }" aria-current="{ COND string( WHEN ls_line-selected = abap_true THEN `true` ELSE `false` ) }">{ lv_line }</button></div>|.
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
    lv_body = lv_body && |</section></section>|.
    rv_html = zcl_gg_host_html=>document(
      iv_session_id = iv_session_id
      iv_page_id    = iv_page_id
      iv_kind       = zif_gg_host_html_v1=>page_list
      iv_title      = iv_title
      iv_csp_nonce  = is_context-csp_nonce
      is_status     = is_status
      iv_body       = |<section class="gg-page gg-page--list" aria-label="List page"><header class="gg-status-region" aria-label="List status"><p class="gg-list-status" role="status">{ zcl_gg_host_html=>escape_text( CONV string( is_status-status ) ) }</p></header><section class="gg-message-region" aria-label="Messages">{ render_messages( it_messages ) }</section><form method="post" action="/dispatch"><input type="hidden" name="session_id" value="{ zcl_gg_host_html=>escape_attribute( iv_session_id ) }"><input type="hidden" name="page_id" value="{ zcl_gg_host_html=>escape_attribute( iv_page_id ) }"><input type="hidden" name="action" value="SUBMIT">{ lv_body }<nav class="gg-action-row" aria-label="List actions">{ lv_nav }</nav></form></section>| ).
  ENDMETHOD.

  METHOD render_selection.
    DATA lv_body TYPE string.
    DATA lv_open_block TYPE i.
    DATA lv_open_line TYPE i.
    DATA lv_title TYPE string.
    DATA ls_value TYPE zif_gg_selection_screen_types=>ty_value.
    DATA ls_state TYPE zif_gg_selection_screen_types=>ty_state.
    DATA lv_tab_action TYPE string.
    DATA ls_range TYPE zif_gg_selection_screen_types=>ty_range.
    DATA lv_element_id TYPE string.
    DATA lv_message_attrs TYPE string.
    DATA lv_state_class TYPE string.
    DATA lv_type_attrs TYPE string.
    DATA lv_state_attrs TYPE string.
    DATA lv_external_attrs TYPE string.
    DATA lv_high_external_attrs TYPE string.
    DATA lv_focus_attrs TYPE string.
    DATA lv_initial_focus TYPE abap_bool.
    DATA lv_display_value TYPE string.
    DATA lv_low_display TYPE string.
    DATA lv_high_display TYPE string.
    DATA lv_layout_style TYPE string.
    DATA lv_button_text TYPE string.
    DATA lv_button_icon TYPE string.
    DATA lv_button_body TYPE string.
    DATA lv_confirm_attrs TYPE string.
    DATA lv_field_root_attrs TYPE string.
    DATA lv_active_tab_screen TYPE string.
    DATA lt_visible_blocks TYPE zcl_gg_host_screen=>ty_blocks.

    lv_body = |<section class="gg-page gg-page--selection" aria-label="Selection page"><header class="gg-status-region" aria-label="Selection status"><p class="gg-selection-status"{ COND string( WHEN is_status-status IS INITIAL THEN `` ELSE ` role="status"` ) }>{ zcl_gg_host_html=>escape_text( CONV string( is_status-status ) ) }</p></header><section class="gg-message-region" aria-label="Messages">{ render_messages( it_messages ) }</section>|.
    lv_body = lv_body && selection_help_section( iv_help_text ).
    lv_body = lv_body && |<section class="gg-work-area gg-selection" aria-label="Selection work area"><form method="post" action="/dispatch"><input type="hidden" name="session_id" value="{ zcl_gg_host_html=>escape_attribute( iv_session_id ) }"><input type="hidden" name="page_id" value="{ zcl_gg_host_html=>escape_attribute( iv_page_id ) }"><input type="hidden" name="gg_action" value="SUBMIT">|.

    IF it_tabs IS NOT INITIAL.
      lv_body = lv_body && |<nav role="tablist" aria-label="Selection tabs">|.
      LOOP AT it_tabs INTO DATA(ls_tab).
        lv_tab_action = |TAB:{ zcl_gg_host_html=>escape_attribute( CONV string( ls_tab-name ) ) }| && `|` && |{ zcl_gg_host_html=>escape_attribute( CONV string( ls_tab-ucomm ) ) }|.
        lv_state_class = zcl_gg_host_html=>state_class( iv_selected = ls_tab-selected ).
        lv_body = lv_body && |<button class="{ lv_state_class }" type="submit" role="tab" name="gg_action" value="{ lv_tab_action }" aria-selected="{ COND string( WHEN ls_tab-selected = abap_true THEN `true` ELSE `false` ) }">{ zcl_gg_host_html=>escape_text( ls_tab-text ) }</button>|.
      ENDLOOP.
      lv_body = lv_body && |</nav>|.
    ENDIF.

    lv_active_tab_screen = active_selection_screen(
      iv_default = is_context-screen
      it_tabs    = it_tabs ).
    lt_visible_blocks = visible_selection_blocks(
      iv_screen = lv_active_tab_screen
      it_blocks = it_blocks ).

    LOOP AT it_elements INTO DATA(ls_element).
      CHECK ls_element-kind <> 'SCREEN'
        AND ( ls_element-screen = is_context-screen
          OR ls_element-screen = lv_active_tab_screen ).
      lv_body = lv_body && COND string(
        WHEN lv_open_line > 0 AND ls_element-line <> lv_open_line THEN `</div>`
        ELSE `` ).
      lv_open_line = COND i(
        WHEN lv_open_line > 0 AND ls_element-line <> lv_open_line THEN 0
        ELSE lv_open_line ).
      WHILE lv_open_block < ls_element-block_depth.
        lv_open_block = lv_open_block + 1.
        READ TABLE lt_visible_blocks INTO DATA(ls_block) INDEX lv_open_block.
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
      lv_body = lv_body && COND string(
        WHEN ls_element-line > 0 AND lv_open_line = 0
          THEN |<div class="gg-selection-line" data-selection-line="{ ls_element-line }">|
        ELSE `` ).
      lv_open_line = COND i(
        WHEN ls_element-line > 0 AND lv_open_line = 0 THEN ls_element-line
        ELSE lv_open_line ).

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
          lv_state_class = zcl_gg_host_html=>state_class(
            iv_disabled = xsdbool( ls_state-enabled = abap_false )
            iv_required = ls_state-obligatory
            iv_readonly = xsdbool( ls_state-input = abap_false ) ).
          lv_field_root_attrs = COND string(
            WHEN ls_state-visible = abap_false OR ls_state-no_display = abap_true
            THEN ` hidden`
            ELSE `` ).
          lv_state_class = lv_state_class && COND string(
            WHEN ls_state-intensified = abap_true THEN ` gg-intensified`
            ELSE `` ).
          lv_message_attrs = field_message_attrs(
            it_messages = it_messages
            iv_name     = CONV string( ls_element-name ) ).
          lv_type_attrs = field_type_attrs(
            is_data_type   = ls_element-data_type
            iv_extra_class = lv_state_class ).
          lv_display_value = zcl_gg_host_html=>format_external_value(
            iv_value = lv_value
            iv_type  = ls_element-data_type-typ ).
          lv_external_attrs = external_value_attrs(
            iv_value = lv_value
            iv_type  = ls_element-data_type-typ ).
          lv_state_attrs = state_attrs(
            is_state    = ls_state
            iv_readonly = xsdbool( ls_state-input = abap_false ) ).
          lv_focus_attrs = COND string( WHEN lv_initial_focus = abap_false
            AND ls_state-visible = abap_true
            AND ls_state-enabled = abap_true
            AND ls_state-input = abap_true
            AND ls_state-no_display = abap_false
            THEN ` autofocus` ELSE `` ).
          IF lv_focus_attrs IS NOT INITIAL.
            lv_focus_attrs = ` autofocus`.
            lv_initial_focus = abap_true.
          ENDIF.
          lv_body = lv_body && |<div class="gg-field gg-parameter { lv_state_class }"{ lv_field_root_attrs }><label for="{ zcl_gg_host_html=>escape_attribute( lv_element_id ) }">{ zcl_gg_host_html=>escape_text( ls_element-text ) }</label><input type="{ COND string( WHEN ls_state-password = abap_true THEN `password` ELSE `text` ) }" id="{ zcl_gg_host_html=>escape_attribute( lv_element_id ) }" name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" data-abap-name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" value="{ zcl_gg_host_html=>escape_attribute( lv_display_value ) }"{ lv_type_attrs }{ lv_external_attrs }{ lv_focus_attrs }{ COND string( WHEN iv_help_name = ls_element-name AND iv_help_text IS NOT INITIAL THEN ` aria-describedby="gg-help-text"` ELSE `` ) }{ lv_state_attrs }{ lv_message_attrs }>|.
          lv_body = lv_body && value_help_button( iv_name       = CONV string( ls_element-name )
                                                  iv_label      = CONV string( ls_element-text )
                                                  iv_value_help = xsdbool( ls_element-value_help = abap_true OR ls_state-value_help = abap_true ) ).
          lv_body = lv_body && |</div>|.
          IF ls_value-ranges IS NOT INITIAL.
            lv_body = lv_body && render_selection_value_help(
              iv_name   = CONV string( ls_element-name )
              it_ranges = ls_value-ranges ).
          ENDIF.
        WHEN 'CHECKBOX'.
          lv_element_id = zcl_gg_host_html=>identifier( iv_scope   = 'selection-field'
                                                        iv_program = CONV string( is_context-program )
                                                        iv_name    = CONV string( ls_element-name ) ).
          CLEAR: ls_value, ls_state.
          READ TABLE it_values INTO ls_value WITH KEY name = ls_element-name.
          READ TABLE it_states INTO ls_state WITH KEY name = ls_element-name.
          lv_state_class = zcl_gg_host_html=>state_class(
            iv_selected = xsdbool( ls_value-value = 'X' OR ls_value-value = '1' )
            iv_disabled = xsdbool( ls_state-enabled = abap_false )
            iv_required = ls_state-obligatory ).
          lv_message_attrs = field_message_attrs(
            it_messages = it_messages
            iv_name     = CONV string( ls_element-name ) ).
          lv_body = lv_body && |<div class="gg-field gg-choice { lv_state_class }"{ COND string( WHEN ls_state-visible = abap_false OR ls_state-no_display = abap_true THEN ` hidden` ELSE `` ) }><input type="hidden" name="gg-unchecked-{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" value=""><input class="{ lv_state_class }" type="checkbox" id="{ zcl_gg_host_html=>escape_attribute( lv_element_id ) }" name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" data-abap-name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" data-selection-ucomm="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-ucomm ) ) }" value="X"{ COND string( WHEN ls_value-value = 'X' OR ls_value-value = '1' THEN ` checked` ELSE `` ) }{ COND string( WHEN ls_state-input = abap_false THEN ` disabled aria-disabled="true"` ELSE `` ) }{ state_attrs( ls_state ) }{ lv_message_attrs }><label for="{ zcl_gg_host_html=>escape_attribute( lv_element_id ) }">{ zcl_gg_host_html=>escape_text( ls_element-text ) }</label></div>|.
        WHEN 'RADIOBUTTON'.
          lv_element_id = zcl_gg_host_html=>identifier( iv_scope   = 'selection-field'
                                                        iv_program = CONV string( is_context-program )
                                                        iv_name    = CONV string( ls_element-name ) ).
          CLEAR: ls_value, ls_state.
          READ TABLE it_values INTO ls_value WITH KEY name = ls_element-name.
          READ TABLE it_states INTO ls_state WITH KEY name = ls_element-name.
          lv_state_class = zcl_gg_host_html=>state_class(
            iv_selected = xsdbool( ls_value-value = 'X' OR ls_value-value = '1' )
            iv_disabled = xsdbool( ls_state-enabled = abap_false )
            iv_required = ls_state-obligatory ).
          lv_body = lv_body && |<div class="gg-field gg-choice { lv_state_class }"{ COND string( WHEN ls_state-visible = abap_false OR ls_state-no_display = abap_true THEN ` hidden` ELSE `` ) }><input class="{ lv_state_class }" type="radio" id="{ zcl_gg_host_html=>escape_attribute( lv_element_id ) }" name="gg-radio-{ zcl_gg_host_html=>escape_attribute( CONV string( ls_state-group1 ) ) }" value="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" data-abap-name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" data-selection-ucomm="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-ucomm ) ) }"{ COND string( WHEN ls_value-value = 'X' OR ls_value-value = '1' THEN ` checked` ELSE `` ) }{ COND string( WHEN ls_state-input = abap_false THEN ` disabled aria-disabled="true"` ELSE `` ) }{ state_attrs( ls_state ) }><label for="{ zcl_gg_host_html=>escape_attribute( lv_element_id ) }">{ zcl_gg_host_html=>escape_text( ls_element-text ) }</label></div>|.
        WHEN 'LISTBOX'.
          lv_element_id = zcl_gg_host_html=>identifier( iv_scope   = 'selection-field'
                                                        iv_program = CONV string( is_context-program )
                                                        iv_name    = CONV string( ls_element-name ) ).
          CLEAR: ls_value, ls_state.
          READ TABLE it_values INTO ls_value WITH KEY name = ls_element-name.
          READ TABLE it_states INTO ls_state WITH KEY name = ls_element-name.
          lv_state_class = zcl_gg_host_html=>state_class(
            iv_selected = xsdbool( ls_value-value IS NOT INITIAL )
            iv_disabled = xsdbool( ls_state-enabled = abap_false )
            iv_required = ls_state-obligatory ).
          lv_message_attrs = field_message_attrs(
            it_messages = it_messages
            iv_name     = CONV string( ls_element-name ) ).
          lv_body = lv_body && |<div class="gg-field gg-parameter gg-listbox { lv_state_class }"{ COND string( WHEN ls_state-visible = abap_false OR ls_state-no_display = abap_true THEN ` hidden` ELSE `` ) }><label for="{ zcl_gg_host_html=>escape_attribute( lv_element_id ) }">{ zcl_gg_host_html=>escape_text( ls_element-text ) }</label><select class="{ lv_state_class }" id="{ zcl_gg_host_html=>escape_attribute( lv_element_id ) }" name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" data-abap-name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-name ) ) }" data-selection-ucomm="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-ucomm ) ) }"{ COND string( WHEN ls_state-input = abap_false THEN ` disabled aria-disabled="true"` ELSE `` ) }{ state_attrs( ls_state ) }{ lv_message_attrs }>|.
          DATA(lt_fixed_values) = ls_state-fixed_values.
          IF lt_fixed_values IS INITIAL.
            lt_fixed_values = ls_element-fixed_values.
          ENDIF.
          LOOP AT lt_fixed_values INTO DATA(ls_fixed).
            lv_body = lv_body && |<option value="{ zcl_gg_host_html=>escape_attribute( ls_fixed-key ) }"{ COND string( WHEN ls_fixed-key = ls_value-value THEN ` selected` ELSE `` ) }>{ zcl_gg_host_html=>escape_text( ls_fixed-text ) }</option>|.
          ENDLOOP.
          lv_body = lv_body && |</select></div>|.
        WHEN 'SELECT_OPTION'.
          CLEAR: ls_value, ls_state, ls_range.
          READ TABLE it_values INTO ls_value WITH KEY name = ls_element-name.
          READ TABLE it_states INTO ls_state WITH KEY name = ls_element-name.
          DATA(lv_range_name) = CONV string( ls_element-name ).
          DATA(lv_range_count) = lines( ls_value-ranges ).
          IF lv_range_count = 0.
            lv_range_count = 1.
          ENDIF.
          lv_state_class = zcl_gg_host_html=>state_class(
            iv_disabled = xsdbool( ls_state-enabled = abap_false )
            iv_required = ls_state-obligatory
            iv_readonly = xsdbool( ls_state-input = abap_false ) ).
* A select-option reads as one labelled row, like the parameters around it, so
* its name lines up in the same label column instead of sitting in a framed
* box of its own. Only a multi-row range needs the row numbers.
          lv_body = lv_body && |<div class="gg-field gg-range { lv_state_class }" role="group" aria-label="{ zcl_gg_host_html=>escape_attribute( ls_element-text ) }"><span class="gg-range-name">{ zcl_gg_host_html=>escape_text( ls_element-text ) }</span><div class="gg-range-list{ COND string( WHEN lv_range_count > 1 THEN ` gg-range-list--numbered` ELSE `` ) }" data-range-list="{ zcl_gg_host_html=>escape_attribute( lv_range_name ) }">|.
          DO lv_range_count TIMES.
            CLEAR ls_range.
            READ TABLE ls_value-ranges INTO ls_range INDEX sy-index.
            DATA(lv_row_suffix) = COND string( WHEN lv_range_count = 1 THEN `` ELSE |-{ sy-index }| ).
            DATA(lv_low_name) = |{ lv_range_name }{ lv_row_suffix }-LOW|.
            DATA(lv_high_name) = |{ lv_range_name }{ lv_row_suffix }-HIGH|.
            lv_type_attrs = field_type_attrs(
              is_data_type   = ls_element-data_type
              iv_extra_class = |gg-range-input { lv_state_class }| ).
            lv_low_display = zcl_gg_host_html=>format_external_value(
              iv_value = ls_range-low
              iv_type  = ls_element-data_type-typ ).
            lv_high_display = zcl_gg_host_html=>format_external_value(
              iv_value = ls_range-high
              iv_type  = ls_element-data_type-typ ).
            lv_external_attrs = external_value_attrs(
              iv_value = ls_range-low
              iv_type  = ls_element-data_type-typ ).
            lv_high_external_attrs = external_value_attrs(
              iv_value = ls_range-high
              iv_type  = ls_element-data_type-typ ).
            lv_state_attrs = state_attrs(
              is_state    = ls_state
              iv_readonly = xsdbool( ls_state-input = abap_false ) ).
            lv_body = lv_body && |<div class="gg-range-row{ COND string( WHEN ls_element-no_intervals = abap_true THEN ` gg-range-row--single` ELSE `` ) }" data-range-index="{ sy-index }">{ COND string( WHEN lv_range_count > 1 THEN |<span class="gg-range-index" aria-hidden="true">{ sy-index }</span>| ELSE `` ) }<input type="text" id="{ zcl_gg_host_html=>escape_attribute( lv_low_name ) }" name="{ zcl_gg_host_html=>escape_attribute( lv_low_name ) }" value="{ zcl_gg_host_html=>escape_attribute( lv_low_display ) }" aria-label="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-text ) ) } low"{ lv_type_attrs }{ lv_external_attrs }{ lv_state_attrs }>|.
            IF ls_element-no_intervals = abap_false.
              lv_body = lv_body && |<span class="gg-range-to" aria-hidden="true">to</span><input type="text" id="{ zcl_gg_host_html=>escape_attribute( lv_high_name ) }" name="{ zcl_gg_host_html=>escape_attribute( lv_high_name ) }" value="{ zcl_gg_host_html=>escape_attribute( lv_high_display ) }" aria-label="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-text ) ) } high"{ lv_type_attrs }{ lv_high_external_attrs }{ lv_state_attrs }>|.
            ENDIF.
            lv_body = lv_body && |<input type="hidden" name="{ zcl_gg_host_html=>escape_attribute( lv_range_name ) }{ lv_row_suffix }-SIGN" value="{ COND string( WHEN ls_range-sign IS INITIAL THEN `I` ELSE ls_range-sign ) }"><input type="hidden" name="{ zcl_gg_host_html=>escape_attribute( lv_range_name ) }{ lv_row_suffix }-OPTION" value="{ COND string( WHEN ls_range-option IS INITIAL THEN `EQ` ELSE ls_range-option ) }">|.
            IF ls_state-obligatory = abap_true.
              lv_body = lv_body && |<span class="gg-required-marker" title="Required" aria-label="Required">*</span>|.
            ENDIF.
            lv_body = lv_body && range_row_actions(
              iv_name         = lv_range_name
              iv_label        = CONV string( ls_element-text )
              iv_first        = xsdbool( sy-index = 1 )
              iv_no_extension = ls_element-no_extension
              iv_value_help   = ls_element-value_help ).
            lv_body = lv_body && |</div>|.
          ENDDO.
          lv_body = lv_body && `</div></div>`.
          lv_body = lv_body && render_range_editor(
            iv_name         = lv_range_name
            iv_label        = CONV string( ls_element-text )
            it_ranges       = ls_value-ranges
            iv_enabled      = xsdbool( ls_element-no_extension = abap_false
                                       AND ls_element-value_help = abap_false )
            iv_no_intervals = ls_element-no_intervals ).
        WHEN 'PUSHBUTTON' OR 'FUNCTION_KEY'.
          lv_button_text = ls_element-text.
          CLEAR lv_button_icon.
          lv_confirm_attrs = COND string(
            WHEN ls_element-ucomm = 'SAVE' OR ls_element-ucomm = 'DELETE'
            THEN zcl_gg_host_html=>attribute(
              iv_name  = 'onclick'
              iv_value = `return window.confirm('Continue with this variant action?')` )
            ELSE `` ).
          IF lv_button_text CP '@ICON:*'.
            lv_button_icon = substring(
              val = lv_button_text
              off = 6 ).
            SPLIT lv_button_icon AT space INTO lv_button_icon lv_button_text.
          ENDIF.
          lv_button_body = zcl_gg_host_html=>escape_text( lv_button_text ).
          IF lv_button_icon IS NOT INITIAL.
            lv_button_body = zcl_gg_host_icons=>icon( iv_name = lv_button_icon ) && lv_button_body.
          ENDIF.
          lv_body = lv_body && |<button class="gg-selection-button" type="submit" formnovalidate name="gg_ucomm" value="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_element-ucomm ) ) }"{ lv_confirm_attrs }>{ lv_button_body }</button>|.
        WHEN 'COMMENT'.
          lv_body = lv_body && |<p class="gg-selection-comment">{ zcl_gg_host_html=>escape_text( ls_element-text ) }</p>|.
        WHEN 'ULINE'.
          lv_body = lv_body && |<hr class="gg-selection-uline">|.
        WHEN 'SKIP'.
          lv_body = lv_body && |<div class="gg-selection-skip" data-lines="{ ls_element-length }" aria-hidden="true"></div>|.
        WHEN 'TAB'.
          CONTINUE.
        WHEN OTHERS.
          CONTINUE.
      ENDCASE.
    ENDLOOP.
    lv_body = lv_body && COND string( WHEN lv_open_line > 0 THEN `</div>` ELSE `` ).
    WHILE lv_open_block > 0.
      lv_body = lv_body && |</fieldset>|.
      lv_open_block = lv_open_block - 1.
    ENDWHILE.
* Execute carries the ONLI function code. It skips browser validation, as the
* program-declared pushbuttons above already do, so an empty obligatory field
* is rejected by the program's own selection-screen validation with a message
* rather than by a native browser bubble.
    lv_body = lv_body && render_dynamic_selection( is_selection = is_dynamic_selection ).
    lv_body = lv_body && |<div class="gg-action-row gg-field gg-actions" role="group" aria-label="Selection actions"><button type="submit" formnovalidate name="gg_ucomm" value="ONLI" data-key="F8" aria-keyshortcuts="F8">Execute</button><button type="submit" name="gg_action" value="EXIT" aria-keyshortcuts="Escape">Cancel</button></div></form></section></section>|.
    rv_html = zcl_gg_host_html=>document(
      iv_session_id = iv_session_id
      iv_page_id    = iv_page_id
      iv_kind       = zif_gg_host_html_v1=>page_selection
      iv_title      = iv_title
      iv_csp_nonce  = is_context-csp_nonce
* The workbench shell already carries the page title in wb-app-title, the way
* SAP GUI shows it once in the window title bar. A second heading inside the
* screen would duplicate it and give the page two h1 elements.
      iv_body       = lv_body ).
  ENDMETHOD.

  METHOD render_dynamic_selection.
    DATA lv_mode TYPE string.
    DATA lv_field_name TYPE string.
    DATA lv_field_text TYPE string.
    DATA lv_checked TYPE string.
    DATA lv_sign_i TYPE string.
    DATA lv_sign_e TYPE string.
    DATA lv_option_eq TYPE string.
    DATA lv_option_bt TYPE string.

    IF is_selection-open = abap_false.
      RETURN.
    ENDIF.

    lv_mode = COND string(
      WHEN is_selection-as_window = abap_true THEN 'Dialog window'
      ELSE 'Fullscreen dialog' ).
    rv_html = |<section class="gg-free-selection-modal{ COND string( WHEN is_selection-as_window = abap_false THEN ` gg-free-selection-modal--fullscreen` ELSE `` ) }" role="dialog" aria-modal="true" aria-labelledby="gg-free-selection-title" data-free-selection="true"><div class="gg-free-selection-panel"><header class="gg-free-selection-header"><h2 id="gg-free-selection-title">{ zcl_gg_host_html=>escape_text( COND string( WHEN is_selection-title IS INITIAL THEN `Dynamic selections` ELSE is_selection-title ) ) }</h2><span>{ zcl_gg_host_html=>escape_text( lv_mode ) }</span></header><div class="gg-free-selection-body"><aside class="gg-free-selection-tree" aria-label="Available fields"><h3>Available fields</h3><div role="tree">|.
    LOOP AT is_selection-fields INTO DATA(ls_field).
      lv_field_name = zcl_gg_host_html=>escape_attribute( ls_field-name ).
      lv_field_text = COND string(
        WHEN ls_field-text IS INITIAL THEN |{ ls_field-table_name }-{ ls_field-name }|
        ELSE ls_field-text ).
      lv_checked = COND string( WHEN ls_field-active = abap_true THEN ` checked` ELSE `` ).
      rv_html = rv_html && |<label class="gg-free-selection-tree-item" role="treeitem"><input type="checkbox" name="gg-free-{ lv_field_name }-ACTIVE" value="X"{ lv_checked }><span>{ zcl_gg_host_html=>escape_text( lv_field_text ) }</span></label>|.
    ENDLOOP.
    rv_html = rv_html && |</div></aside><section class="gg-free-selection-criteria" aria-label="Selection criteria"><h3>Selection criteria</h3>|.
    LOOP AT is_selection-fields INTO ls_field.
      lv_field_name = zcl_gg_host_html=>escape_attribute( ls_field-name ).
      lv_field_text = COND string(
        WHEN ls_field-text IS INITIAL THEN |{ ls_field-table_name }-{ ls_field-name }|
        ELSE ls_field-text ).
      lv_sign_i = COND string( WHEN ls_field-sign = 'I' OR ls_field-sign IS INITIAL THEN ` selected` ELSE `` ).
      lv_sign_e = COND string( WHEN ls_field-sign = 'E' THEN ` selected` ELSE `` ).
      lv_option_eq = COND string( WHEN ls_field-option = 'EQ' OR ls_field-option IS INITIAL THEN ` selected` ELSE `` ).
      lv_option_bt = COND string( WHEN ls_field-option = 'BT' THEN ` selected` ELSE `` ).
      rv_html = rv_html && |<div class="gg-free-selection-row"><label for="gg-free-{ lv_field_name }-low">{ zcl_gg_host_html=>escape_text( lv_field_text ) }</label><select name="gg-free-{ lv_field_name }-SIGN" aria-label="{ zcl_gg_host_html=>escape_attribute( lv_field_text ) } sign"><option value="I"{ lv_sign_i }>Include</option><option value="E"{ lv_sign_e }>Exclude</option></select><select name="gg-free-{ lv_field_name }-OPTION" aria-label="{ zcl_gg_host_html=>escape_attribute( lv_field_text ) } option"><option value="EQ"{ lv_option_eq }>Equals</option><option value="BT"{ lv_option_bt }>Between</option></select><input id="gg-free-{ lv_field_name }-low" type="text" name="gg-free-{ lv_field_name }-LOW" value="{ zcl_gg_host_html=>escape_attribute( ls_field-low ) }" placeholder="Low"><input type="text" name="gg-free-{ lv_field_name }-HIGH" value="{ zcl_gg_host_html=>escape_attribute( ls_field-high ) }" placeholder="High" aria-label="{ zcl_gg_host_html=>escape_attribute( lv_field_text ) } high"></div>|.
    ENDLOOP.
    rv_html = rv_html && |</section></div><footer class="gg-free-selection-actions" aria-label="Dynamic selection actions"><button type="submit" formnovalidate name="gg_free_action" value="APPLY">Apply</button><button type="submit" formnovalidate name="gg_free_action" value="CANCEL">Cancel</button><button type="submit" formnovalidate name="gg_free_action" value="RESET">Reset selection</button></footer></div></section>|.
  ENDMETHOD.

  METHOD render_dynpro_table.
    DATA lv_table_body TYPE string.
    DATA lv_table_class TYPE string.
    DATA lv_id TYPE string.
    DATA lv_row TYPE i.
    DATA lv_cell_name TYPE string.
    DATA lv_cell_value TYPE string.
    DATA lv_state_class TYPE string.
    DATA lv_cell_attrs TYPE string.
    DATA lv_cell_input_attrs TYPE string.
    DATA lv_type_attrs TYPE string.
    DATA lv_external_attrs TYPE string.
    DATA lv_display_value TYPE string.
    DATA lv_output_class TYPE string.
    DATA ls_value TYPE zif_gg_dynpro_types_v1=>ty_value.
    DATA ls_state TYPE zif_gg_dynpro_types_v1=>ty_state.

    lv_id = zcl_gg_host_html=>identifier(
      iv_scope = 'dynpro-control'
      iv_name  = CONV string( is_control-name ) ).
    lv_table_class = zcl_gg_host_html=>state_class( iv_disabled = xsdbool( is_control-enabled = abap_false ) ).
    lv_table_body = |<table><caption>{ zcl_gg_host_html=>escape_text( CONV string( is_control-name ) ) }</caption><thead><tr>|.
    LOOP AT it_controls INTO DATA(ls_column)
        WHERE screen = is_screen-number AND kind = 'TABLE_COLUMN'
          AND parent = is_control-name.
      lv_table_body = lv_table_body && |<th scope="col" style="width:{ ls_column-column_width }px">{ zcl_gg_host_html=>escape_text( ls_column-column_title ) }</th>|.
    ENDLOOP.
    lv_table_body = lv_table_body && |</tr></thead><tbody>|.
    lv_row = 1.
    WHILE lv_row <= is_control-visible_rows.
      lv_table_body = lv_table_body && |<tr class="gg-grid-row" data-row="{ lv_row }">|.
      LOOP AT it_controls INTO ls_column
          WHERE screen = is_screen-number AND kind = 'TABLE_COLUMN'
            AND parent = is_control-name.
        CLEAR: lv_cell_value, ls_value, ls_state.
        READ TABLE it_values INTO ls_value
          WITH KEY container = is_control-name
                   name = ls_column-name
                   row = lv_row.
        IF sy-subrc = 0.
          lv_cell_value = ls_value-value.
        ENDIF.
        READ TABLE it_states INTO ls_state
          WITH KEY container = is_control-name
                   name = COND #( WHEN ls_column-state_name IS INITIAL
                                  THEN ls_column-name
                                  ELSE ls_column-state_name )
                   row = lv_row.
        IF sy-subrc <> 0.
          ls_state-enabled = abap_true.
          ls_state-visible = abap_true.
          ls_state-input = ls_column-input.
        ENDIF.
        lv_cell_name = |gg-cell-{ CONV string( is_control-name ) }-{ CONV string( ls_column-name ) }-{ lv_row }|.
        lv_state_class = zcl_gg_host_html=>state_class(
          iv_disabled = xsdbool( ls_state-enabled = abap_false
                                 OR ( ls_column-input = abap_true
                                      AND ls_state-input = abap_false ) )
          iv_required = xsdbool( ls_column-required = abap_true
                                 OR ls_state-required = abap_true )
          iv_readonly = xsdbool( ls_column-input = abap_false
                                 OR ls_state-input = abap_false ) ).
        lv_state_class = lv_state_class && COND string(
          WHEN ls_state-intensified = abap_true THEN ` gg-intensified`
          ELSE `` ).
        lv_cell_attrs = COND string(
          WHEN ls_state-visible = abap_false OR ls_state-no_display = abap_true
            THEN ` hidden` ELSE `` ).
        lv_cell_input_attrs = ``.
        IF ls_state-enabled = abap_false
            OR ( ls_column-input = abap_true AND ls_state-input = abap_false ).
          lv_cell_input_attrs = ` disabled aria-disabled="true"`.
        ENDIF.
        IF ls_column-required = abap_true OR ls_state-required = abap_true.
          lv_cell_input_attrs = lv_cell_input_attrs && ` required aria-required="true"`.
        ENDIF.
        lv_display_value = zcl_gg_host_html=>format_external_value(
          iv_value = lv_cell_value
          iv_type  = ls_column-data_type-typ ).
        lv_external_attrs = external_value_attrs(
          iv_value = lv_cell_value
          iv_type  = ls_column-data_type-typ ).
        IF ls_column-checkbox = abap_true.
          lv_table_body = lv_table_body && |<td class="gg-grid-cell { lv_state_class }"{ lv_cell_attrs }><input type="hidden" name="{ zcl_gg_host_html=>escape_attribute( lv_cell_name ) }" value=""><input type="checkbox" name="{ zcl_gg_host_html=>escape_attribute( lv_cell_name ) }" aria-label="{ zcl_gg_host_html=>escape_attribute( COND string( WHEN ls_column-column_title IS INITIAL THEN CONV string( ls_column-name ) ELSE CONV string( ls_column-column_title ) ) ) } row { lv_row }" value="X"{ COND string( WHEN lv_cell_value = 'X' OR lv_cell_value = '1' THEN ` checked` ELSE `` ) }{ lv_cell_input_attrs }></td>|.
        ELSEIF ls_column-input = abap_true.
          lv_type_attrs = dynpro_type_attrs(
            is_data_type   = ls_column-data_type
            iv_extra_class = lv_state_class ).
          lv_table_body = lv_table_body && |<td class="gg-grid-cell { lv_state_class }"{ lv_cell_attrs }><input type="text" name="{ zcl_gg_host_html=>escape_attribute( lv_cell_name ) }" aria-label="{ zcl_gg_host_html=>escape_attribute( COND string( WHEN ls_column-column_title IS INITIAL THEN CONV string( ls_column-name ) ELSE CONV string( ls_column-column_title ) ) ) } row { lv_row }" value="{ zcl_gg_host_html=>escape_attribute( lv_display_value ) }"{ lv_type_attrs }{ lv_external_attrs }{ lv_cell_input_attrs }></td>|.
        ELSE.
          lv_output_class = data_type_class(
            iv_type        = ls_column-data_type-typ
            iv_extra_class = lv_state_class ).
          lv_table_body = lv_table_body && |<td class="gg-grid-cell { lv_state_class }"{ lv_cell_attrs }><output class="{ lv_output_class }"{ lv_external_attrs }>{ zcl_gg_host_html=>escape_text( lv_display_value ) }</output></td>|.
        ENDIF.
      ENDLOOP.
      lv_table_body = lv_table_body && |</tr>|.
      lv_row = lv_row + 1.
    ENDWHILE.
    lv_table_body = lv_table_body && |</tbody></table>|.
    rv_html = |<section class="gg-dynpro-control { lv_table_class }" style="{ iv_style }" data-table-control="{ zcl_gg_host_html=>escape_attribute( lv_id ) }" data-selection-mode="{ zcl_gg_host_html=>escape_attribute( is_control-selection_mode ) }" data-hscroll="{ COND string( WHEN is_control-with_hscroll = abap_true THEN `true` ELSE `false` ) }" data-vscroll="{ COND string( WHEN is_control-with_vscroll = abap_true THEN `true` ELSE `false` ) }">{ lv_table_body }</section>|.
  ENDMETHOD.

  METHOD render_dynpro.
    DATA lv_body TYPE string.
    DATA lv_height TYPE i.
    DATA lv_header_height TYPE i.
    DATA lv_render_height TYPE i.
    DATA lv_title TYPE string.
    DATA ls_value TYPE zif_gg_dynpro_types_v1=>ty_value.
    DATA ls_state TYPE zif_gg_dynpro_types_v1=>ty_state.
    DATA lv_row TYPE i.
    DATA lv_table_body TYPE string.
    DATA lv_cell_name TYPE string.
    DATA lv_cell_value TYPE string.
    DATA lv_top TYPE i.
    DATA lv_help_html TYPE string.
    DATA lv_tab_index TYPE i.
    DATA lv_button_icon TYPE string.
    DATA lv_state_class TYPE string.
    DATA lv_type_attrs TYPE string.
    DATA lv_external_attrs TYPE string.
    DATA lv_display_value TYPE string.
    DATA lv_output_class TYPE string.
    DATA lv_output_icon TYPE string.
    DATA lv_output_text TYPE string.
    DATA ls_cell_state TYPE zif_gg_dynpro_types_v1=>ty_state.
    DATA lv_cell_attrs TYPE string.
    DATA lv_cell_input_attrs TYPE string.
    DATA lv_left TYPE i.
    DATA lv_active_tab TYPE string.
    DATA lv_tab_selected TYPE abap_bool.
    DATA lv_tab_text TYPE string.
    DATA ls_subscreen_area TYPE zcl_gg_host_dynpro_builder=>ty_control_record.
    DATA ls_tab_state TYPE zif_gg_dynpro_types_v1=>ty_state.
    DATA ls_tab_value TYPE zif_gg_dynpro_types_v1=>ty_value.
    DATA ls_active_value TYPE zif_gg_dynpro_types_v1=>ty_value.
    DATA lv_modal_style TYPE string.
    DATA lv_context_menu TYPE string.

    lv_title = is_screen-title.
    IF iv_title IS NOT INITIAL.
      lv_title = iv_title.
    ENDIF.

    lv_height = is_screen-height.
    IF lv_height <= 0.
      lv_height = 240.
    ENDIF.
    lv_header_height = 0.
    lv_render_height = lv_height + lv_header_height.
    dynpro_geometry(
      EXPORTING
        iv_height        = lv_height
        iv_header_height = lv_header_height
        is_screen        = is_screen
        it_controls      = it_controls
      CHANGING
        cv_render_height = lv_render_height ).
    IF is_screen-modal = abap_true.
      lv_modal_style = |min-height:{ lv_render_height }px;width:{ is_screen-width }px;|.
      IF is_modal_position-start_column > 0.
        lv_modal_style = lv_modal_style && |margin-left:{ is_modal_position-start_column * 10 }px;|.
      ENDIF.
      IF is_modal_position-start_row > 0.
        lv_modal_style = lv_modal_style && |margin-top:{ is_modal_position-start_row * 26 }px;|.
      ENDIF.
    ELSE.
      lv_modal_style = |min-height:{ lv_render_height }px;|.
    ENDIF.
    lv_body = |<section class="gg-page gg-page--dynpro" aria-label="Dynpro page"><section class="gg-message-region" aria-label="Messages">{ render_messages( it_messages ) }</section>|.
    IF iv_help_text IS NOT INITIAL.
      lv_body = lv_body && |<section class="gg-instruction-region" aria-label="Instructions"><aside class="gg-message gg-info" role="status">{ zcl_gg_host_html=>escape_text( iv_help_text ) }</aside></section>|.
    ENDIF.
    IF is_screen-modal = abap_true AND is_screen-width <= 0.
      lv_modal_style = lv_modal_style && |width:640px;|.
    ENDIF.
    lv_body = lv_body && |<section class="gg-work-area" aria-label="Dynpro work area"><section class="gg-dynpro" aria-label="Dynpro { zcl_gg_host_html=>escape_text( lv_title ) }" data-screen="{ is_screen-number }" data-modal="{ COND string( WHEN is_screen-modal = abap_true THEN `true` ELSE `false` ) }" data-cursor-field="{ zcl_gg_host_html=>escape_attribute( CONV string( is_cursor-field ) ) }" data-cursor-row="{ is_cursor-row }" style="{ lv_modal_style }">|.
    IF it_help_values IS NOT INITIAL.
      lv_body = lv_body && |<div class="gg-value-help-modal" role="dialog" aria-modal="true" aria-labelledby="gg-value-help-title" data-help-field="{ zcl_gg_host_html=>escape_attribute( iv_help_name ) }"><div class="gg-value-help-panel"><header class="gg-value-help-header"><h2 id="gg-value-help-title">Value help</h2><button class="gg-value-help-close" type="button" data-value-help-close aria-label="Close value help">{ zcl_gg_host_icons=>icon( iv_name = 'circle-x' ) }</button></header><div class="gg-value-help-status" role="status" aria-label="Value help results"><section class="gg-value-help" role="region" aria-label="Value help"><ul>|.
      LOOP AT it_help_values INTO DATA(ls_help_value).
        lv_body = lv_body && |<li data-name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_help_value-name ) ) }" data-value="{ zcl_gg_host_html=>escape_attribute( ls_help_value-value ) }" tabindex="0" role="option">{ zcl_gg_host_html=>escape_text( ls_help_value-value ) }</li>|.
      ENDLOOP.
      lv_body = lv_body && |</ul></section></div></div></div>|.
    ENDIF.
    lv_body = lv_body && |<form method="post" action="/dispatch" id="gg-dynpro-form"><input type="hidden" name="session_id" value="{ zcl_gg_host_html=>escape_attribute( iv_session_id ) }"><input type="hidden" name="page_id" value="{ zcl_gg_host_html=>escape_attribute( iv_page_id ) }"><input type="hidden" name="action" value="SUBMIT">|.
    LOOP AT it_values INTO ls_active_value
        WHERE container = `` AND row = 0.
      IF ls_active_value-name NP '*-ACTIVETAB'
          AND ls_active_value-name <> 'GV_SUBSCREEN'
          AND NOT line_exists( it_controls[ screen = is_screen-number
                                             kind = 'SUBSCREEN_AREA'
                                             subscreen_field = ls_active_value-name ] ).
        CONTINUE.
      ENDIF.
      lv_body = lv_body && |<input type="hidden" name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_active_value-name ) ) }" data-abap-name="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_active_value-name ) ) }" value="{ zcl_gg_host_html=>escape_attribute( ls_active_value-value ) }">|.
    ENDLOOP.
    IF is_popup-kind IS NOT INITIAL.
      lv_body = lv_body && render_dynpro_popup( is_popup ).
    ENDIF.
    LOOP AT it_controls INTO DATA(ls_tabstrip)
        WHERE screen = is_screen-number AND kind = 'TABSTRIP'.
      READ TABLE it_values INTO ls_tab_value
        WITH KEY container = ``
                 name = |{ ls_tabstrip-name }-ACTIVETAB|
                 row = 0.
      IF sy-subrc = 0.
        lv_active_tab = ls_tab_value-value.
      ENDIF.
      READ TABLE it_controls INTO DATA(ls_active_tab)
        WITH KEY screen = is_screen-number
                 kind = 'TAB'
                 parent = ls_tabstrip-name
                 ucomm = lv_active_tab.
      IF sy-subrc <> 0.
        READ TABLE it_controls INTO ls_active_tab
          WITH KEY screen = is_screen-number
                   kind = 'TAB'
                   parent = ls_tabstrip-name.
      ENDIF.
      IF sy-subrc = 0.
        lv_active_tab = ls_active_tab-ucomm.
      ENDIF.
      EXIT.
    ENDLOOP.
    lv_body = lv_body && render_dynpro_controls(
      is_screen        = is_screen
      iv_header_height = lv_header_height
      iv_active_tab    = lv_active_tab
      is_cursor        = is_cursor
      is_context       = is_context
      it_controls      = it_controls
      it_values        = it_values
      it_states        = it_states
      it_messages      = it_messages ).
    IF io_menu IS BOUND AND iv_menu_field IS NOT INITIAL.
      lv_context_menu = render_context_menu(
        io_menu  = io_menu
        iv_field = iv_menu_field ).
      lv_body = lv_body && lv_context_menu && '<script>(function(){var menu=document.querySelector(".gg-context-menu");if(!menu){return;}var close=function(){menu.hidden=true;};document.addEventListener("contextmenu",function(event){var field=event.target.closest?event.target.closest("[data-context-menu=true]"):null;if(!field){return;}event.preventDefault();menu.hidden=false;menu.style.left=event.clientX+"px";menu.style.top=event.clientY+"px";var first=menu.querySelector("button:not(:disabled)");if(first){first.focus();}});document.addEventListener("click",function(event){if(!menu.contains(event.target)){close();}});document.addEventListener("keydown",function(event){if(event.key==="Escape"&&!menu.hidden){event.preventDefault();close();}});}());</script>'.
    ENDIF.
    lv_body = lv_body && |</form></section></section></section>|.
    rv_html = zcl_gg_host_html=>document(
      iv_session_id = iv_session_id
      iv_page_id    = iv_page_id
      iv_kind       = zif_gg_host_html_v1=>page_dynpro
      iv_title      = lv_title
      iv_csp_nonce  = is_context-csp_nonce
      is_status     = is_status
      iv_body       = lv_body ).
  ENDMETHOD.

  METHOD render_context_menu.
    IF io_menu IS NOT BOUND OR iv_field IS INITIAL.
      RETURN.
    ENDIF.
    rv_html = |<div class="gg-context-menu" data-context-menu-for="{ zcl_gg_host_html=>escape_attribute( iv_field ) }" role="menu" hidden><ul class="gg-context-menu-list" role="none">{ render_context_menu_items( zcl_gg_context_menu_state=>get_items( io_menu = io_menu ) ) }</ul></div>|.
  ENDMETHOD.

  METHOD render_context_menu_items.
    DATA lv_state TYPE string.

    LOOP AT it_items INTO DATA(ls_item).
      IF ls_item-hidden = abap_true.
        CONTINUE.
      ENDIF.
      IF ls_item-separator = abap_true.
        rv_html = rv_html && '<li class="gg-context-menu-separator" role="separator"></li>'.
        CONTINUE.
      ENDIF.
      IF ls_item-submenu IS BOUND.
        rv_html = rv_html && |<li class="gg-context-menu-group" role="none"><span class="gg-context-menu-group-label">{ zcl_gg_host_html=>escape_text( ls_item-text ) }</span><ul class="gg-context-menu-list" role="none">{ render_context_menu_items( zcl_gg_context_menu_state=>get_items( io_menu = ls_item-submenu ) ) }</ul></li>|.
        CONTINUE.
      ENDIF.
      lv_state = COND string( WHEN ls_item-disabled = abap_true THEN ` disabled` ELSE `` ).
      rv_html = rv_html && |<li role="none"><button class="gg-context-menu-item" type="submit" name="gg_ucomm" value="{ zcl_gg_host_html=>escape_attribute( ls_item-fcode ) }" role="menuitem" formnovalidate{ lv_state }>{ zcl_gg_host_html=>escape_text( ls_item-text ) }</button></li>|.
    ENDLOOP.
  ENDMETHOD.

  METHOD render_dynpro_controls.
    DATA lv_top TYPE i.
    DATA lv_left TYPE i.
    DATA lv_area_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.
    DATA lv_active_subscreen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.
    DATA ls_active_tab TYPE zcl_gg_host_dynpro_builder=>ty_control_record.
    DATA ls_active_value TYPE zif_gg_dynpro_types_v1=>ty_value.
    DATA ls_subscreen_area TYPE zcl_gg_host_dynpro_builder=>ty_control_record.
    DATA ls_value TYPE zif_gg_dynpro_types_v1=>ty_value.
    DATA ls_state TYPE zif_gg_dynpro_types_v1=>ty_state.
    DATA lv_style TYPE string.
    DATA lv_id TYPE string.
    DATA lv_attrs TYPE string.
    DATA lv_state_class TYPE string.

    IF iv_active_tab IS NOT INITIAL.
      READ TABLE it_controls INTO ls_active_tab
        WITH KEY screen = is_screen-number
                 kind = 'TAB'
                 ucomm = iv_active_tab.
      IF sy-subrc = 0.
        lv_active_subscreen = ls_active_tab-subscreen.
      ENDIF.
      IF lv_active_subscreen IS INITIAL OR lv_active_subscreen = '0000'.
        READ TABLE it_values INTO ls_active_value
          WITH KEY container = `` name = 'GV_SUBSCREEN' row = 0.
        IF sy-subrc = 0.
          lv_active_subscreen = CONV #( ls_active_value-value ).
        ENDIF.
      ENDIF.
    ENDIF.

    LOOP AT it_controls INTO DATA(ls_control).
      IF ls_control-screen <> is_screen-number.
        CLEAR ls_subscreen_area.
        LOOP AT it_controls INTO DATA(ls_area)
            WHERE screen = is_screen-number AND kind = 'SUBSCREEN_AREA'.
          lv_area_screen = subscreen_for_area(
            is_area   = ls_area
            it_values = it_values ).
          IF lv_area_screen = ls_control-screen.
            ls_subscreen_area = ls_area.
            EXIT.
          ENDIF.
        ENDLOOP.
        IF ls_subscreen_area-name IS INITIAL.
          CONTINUE.
        ENDIF.
        IF lv_active_subscreen IS NOT INITIAL
            AND lv_area_screen <> lv_active_subscreen.
          CONTINUE.
        ENDIF.
        lv_top = ls_subscreen_area-position-row + ls_control-position-row + iv_header_height.
        lv_left = ls_subscreen_area-position-column + ls_control-position-column.
      ELSE.
        IF ls_control-kind = 'SUBSCREEN_AREA'
            AND lv_active_subscreen IS NOT INITIAL.
          lv_area_screen = subscreen_for_area(
            is_area   = ls_control
            it_values = it_values ).
          IF lv_area_screen <> lv_active_subscreen.
            CONTINUE.
          ENDIF.
        ENDIF.
        lv_top = ls_control-position-row + iv_header_height.
        lv_left = ls_control-position-column.
      ENDIF.
      CLEAR: ls_value, ls_state.
      READ TABLE it_values INTO ls_value
        WITH KEY container = `` name = ls_control-name row = 0.
      READ TABLE it_states INTO ls_state
        WITH KEY container = `` name = ls_control-name row = 0.
      lv_style = |left:{ lv_left }px;top:{ lv_top }px;|.
      IF ls_control-position-width > 0.
        lv_style = lv_style && |width:{ ls_control-position-width }px;|.
      ENDIF.
      IF ls_control-position-height > 0.
        lv_style = lv_style && |height:{ ls_control-position-height }px;|.
      ENDIF.
      lv_id = zcl_gg_host_html=>identifier(
        iv_scope   = 'dynpro-control'
        iv_program = CONV string( is_context-program )
        iv_name    = CONV string( ls_control-name ) ).
      lv_attrs = dynpro_attrs(
        is_state    = ls_state
        iv_readonly = xsdbool( ls_control-kind = 'INPUT'
                                AND ( ls_control-input = abap_false
                                      OR ls_state-input = abap_false ) ) ).
      lv_state_class = zcl_gg_host_html=>state_class(
        iv_focused  = xsdbool( is_cursor-field = ls_control-name )
        iv_disabled = xsdbool( ls_control-enabled = abap_false
                               OR ls_state-enabled = abap_false )
        iv_required = xsdbool( ls_control-required = abap_true
                               OR ls_state-required = abap_true )
        iv_readonly = xsdbool( ( ls_control-kind = 'INPUT'
                                 OR ls_control-kind = 'TABLE_COLUMN' )
                               AND ( ls_control-input = abap_false
                                     OR ls_state-input = abap_false ) ) ).
      IF is_cursor-field = ls_control-name.
        lv_attrs = lv_attrs && ` autofocus`.
      ENDIF.
      rv_html = rv_html && render_dynpro_control(
        is_screen      = is_screen
        is_control     = ls_control
        is_value       = ls_value
        is_state       = ls_state
        iv_style       = lv_style
        iv_id          = lv_id
        iv_attrs       = lv_attrs
        iv_state_class = lv_state_class
        iv_active_tab  = iv_active_tab
        it_controls    = it_controls
        it_values      = it_values
        it_states      = it_states
        it_messages    = it_messages ).
    ENDLOOP.
  ENDMETHOD.

  METHOD render_dynpro_control.
    DATA lv_help_html TYPE string.
    DATA lv_type_attrs TYPE string.
    DATA lv_external_attrs TYPE string.
    DATA lv_display_value TYPE string.
    DATA lv_output_class TYPE string.
    DATA lv_output_icon TYPE string.
    DATA lv_output_text TYPE string.
    DATA lv_button_icon TYPE string.
    DATA lv_tab_index TYPE i.
    DATA lv_tab_text TYPE string.
    DATA lv_tab_selected TYPE abap_bool.
    DATA ls_tab_state TYPE zif_gg_dynpro_types_v1=>ty_state.
    DATA ls_tab_value TYPE zif_gg_dynpro_types_v1=>ty_value.
    DATA ls_active_value TYPE zif_gg_dynpro_types_v1=>ty_value.
    DATA lv_field_attrs TYPE string.

    CASE is_control-kind.
      WHEN 'TAB'.
        RETURN.
      WHEN 'TABLE_COLUMN'.
        RETURN.
      WHEN 'INPUT'.
        lv_help_html = value_help_button( iv_name       = CONV string( is_control-name )
                                          iv_label      = CONV string( is_control-name )
                                          iv_value_help = is_control-value_help ).
        lv_type_attrs = dynpro_type_attrs(
          is_data_type   = is_control-data_type
          iv_extra_class = iv_state_class ).
        lv_display_value = zcl_gg_host_html=>format_external_value(
          iv_value = is_value-value
          iv_type  = is_control-data_type-typ ).
        lv_external_attrs = external_value_attrs(
          iv_value = is_value-value
          iv_type  = is_control-data_type-typ ).
        lv_field_attrs = field_message_attrs( it_messages = it_messages
                                              iv_name     = CONV string( is_control-name ) ).
        rv_html = |<span class="gg-dynpro-control gg-dynpro-field { iv_state_class }" style="{ iv_style }"><label for="{ zcl_gg_host_html=>escape_attribute( iv_id ) }"><span class="gg-visually-hidden">{ zcl_gg_host_html=>escape_text( CONV string( is_control-name ) ) }</span><input id="{ zcl_gg_host_html=>escape_attribute( iv_id ) }" name="{ zcl_gg_host_html=>escape_attribute( CONV string( is_control-name ) ) }" data-abap-name="{ zcl_gg_host_html=>escape_attribute( CONV string( is_control-name ) ) }"{ COND string( WHEN is_control-context_menu = abap_true THEN ` data-context-menu="true"` ELSE `` ) } value="{ zcl_gg_host_html=>escape_attribute( lv_display_value ) }"{ COND string( WHEN is_control-password = abap_true THEN ` type="password"` ELSE ` type="text"` ) }{ lv_type_attrs }{ lv_external_attrs }{ iv_attrs }{ lv_field_attrs }></label>{ lv_help_html }</span>|.
      WHEN 'OUTPUT'.
        lv_output_class = data_type_class(
          iv_type        = is_control-data_type-typ
          iv_extra_class = iv_state_class ).
        lv_display_value = zcl_gg_host_html=>format_external_value(
          iv_value = is_value-value
          iv_type  = is_control-data_type-typ ).
        lv_external_attrs = external_value_attrs(
          iv_value = is_value-value
          iv_type  = is_control-data_type-typ ).
        IF lv_display_value CP '@ICON:*'.
          lv_output_icon = substring(
            val = lv_display_value
            off = 6 ).
          SPLIT lv_output_icon AT space INTO lv_output_icon lv_output_text.
          rv_html = |<output class="gg-dynpro-control { lv_output_class }" style="{ iv_style }" id="{ zcl_gg_host_html=>escape_attribute( iv_id ) }" aria-readonly="true"{ lv_external_attrs }>{ zcl_gg_host_icons=>icon( iv_name = |icon_{ lv_output_icon }| ) }{ zcl_gg_host_html=>escape_text( lv_output_text ) }</output>|.
        ELSE.
          rv_html = |<output class="gg-dynpro-control { lv_output_class }" style="{ iv_style }" id="{ zcl_gg_host_html=>escape_attribute( iv_id ) }" aria-readonly="true"{ lv_external_attrs }>{ zcl_gg_host_html=>escape_text( lv_display_value ) }</output>|.
        ENDIF.
      WHEN 'TEXT'.
        rv_html = |<span class="gg-dynpro-control { iv_state_class }" style="{ iv_style }">{ zcl_gg_host_html=>escape_text( is_control-text ) }</span>|.
      WHEN 'PUSHBUTTON'.
        CASE is_control-ucomm.
          WHEN 'DISPLAY'.
            lv_button_icon = zcl_gg_host_icons=>icon( iv_name = 'device-desktop' ).
          WHEN 'LOGS'.
            lv_button_icon = zcl_gg_host_icons=>icon( iv_name = 'search' ).
          WHEN 'ACTION_LOG'.
            lv_button_icon = zcl_gg_host_icons=>icon( iv_name = 'edit' ).
          WHEN 'APPLY'.
            lv_button_icon = zcl_gg_host_icons=>icon( iv_name = 'circle-check' ).
          WHEN 'RESET'.
            lv_button_icon = zcl_gg_host_icons=>icon( iv_name = 'refresh' ).
          WHEN 'BACK'.
            lv_button_icon = zcl_gg_host_icons=>icon( iv_name = 'arrow-left' ).
        ENDCASE.
        rv_html = |<button class="gg-dynpro-control { iv_state_class }" style="{ iv_style }" type="submit" name="gg_ucomm" value="{ zcl_gg_host_html=>escape_attribute( CONV string( is_control-ucomm ) ) }"{ COND string( WHEN is_control-ucomm = 'EXECUTE' THEN ` data-key="F8" aria-keyshortcuts="F8"` ELSE `` ) }{ iv_attrs }>{ lv_button_icon }<span>{ zcl_gg_host_html=>escape_text( is_control-text ) }</span></button>|.
      WHEN 'CHECKBOX'.
        rv_html = |<label class="gg-dynpro-control { iv_state_class }" style="{ iv_style }"><input type="hidden" name="gg-unchecked-{ zcl_gg_host_html=>escape_attribute( CONV string( is_control-name ) ) }" value=""><input class="{ iv_state_class }" type="checkbox" name="{ zcl_gg_host_html=>escape_attribute( CONV string( is_control-name ) ) }" data-abap-name="{ zcl_gg_host_html=>escape_attribute( CONV string( is_control-name ) ) }" value="X"{ COND string( WHEN is_value-value = 'X' OR is_value-value = '1' THEN ` checked` ELSE `` ) }{ iv_attrs }>{ zcl_gg_host_html=>escape_text( is_control-text ) }</label>|.
      WHEN 'RADIOBUTTON'.
        rv_html = |<label class="gg-dynpro-control { iv_state_class }" style="{ iv_style }"><input class="{ iv_state_class }" type="radio" name="gg-radio-{ zcl_gg_host_html=>escape_attribute( CONV string( is_control-group ) ) }" data-abap-name="{ zcl_gg_host_html=>escape_attribute( CONV string( is_control-name ) ) }" value="{ zcl_gg_host_html=>escape_attribute( CONV string( is_control-name ) ) }"{ COND string( WHEN is_value-value = 'X' OR is_value-value = '1' THEN ` checked` ELSE `` ) }{ iv_attrs }>{ zcl_gg_host_html=>escape_text( is_control-text ) }</label>|.
      WHEN 'LISTBOX'.
        rv_html = |<select class="gg-dynpro-control { iv_state_class }" style="{ iv_style }" id="{ zcl_gg_host_html=>escape_attribute( iv_id ) }" name="{ zcl_gg_host_html=>escape_attribute( CONV string( is_control-name ) ) }" data-abap-name="{ zcl_gg_host_html=>escape_attribute( CONV string( is_control-name ) ) }"{ iv_attrs }>|.
        LOOP AT is_control-fixed_values INTO DATA(ls_fixed).
          rv_html = rv_html && |<option value="{ zcl_gg_host_html=>escape_attribute( ls_fixed-key ) }"{ COND string( WHEN ls_fixed-key = is_value-value THEN ` selected` ELSE `` ) }>{ zcl_gg_host_html=>escape_text( ls_fixed-text ) }</option>|.
        ENDLOOP.
        rv_html = rv_html && |</select>|.
      WHEN 'BOX'.
        rv_html = |<fieldset class="gg-dynpro-control { iv_state_class }" style="{ iv_style }"><legend>{ zcl_gg_host_html=>escape_text( is_control-text ) }</legend></fieldset>|.
      WHEN 'TABSTRIP'.
        rv_html = |<div class="gg-dynpro-control { iv_state_class }" style="{ iv_style }" role="tablist" aria-label="{ zcl_gg_host_html=>escape_text( CONV string( is_control-name ) ) }">|.
        LOOP AT it_controls INTO DATA(ls_tab)
            WHERE screen = is_screen-number AND kind = 'TAB'
              AND parent = is_control-name.
          READ TABLE it_states INTO ls_tab_state
            WITH KEY container = `` name = ls_tab-name row = 0.
          IF ( ls_tab_state-visible = abap_false OR ls_tab_state-no_display = abap_true )
              AND ( is_screen-number <> '0100'
                OR ls_tab-name <> 'GV_TAB3_TITLE' ).
            CONTINUE.
          ENDIF.
          IF is_screen-number = '0100' AND ls_tab-name = 'GV_TAB3_TITLE'.
            READ TABLE it_values INTO ls_active_value
              WITH KEY container = `` name = 'GV_SHOW_ADVANCED' row = 0.
            IF sy-subrc = 0
                AND ls_active_value-value <> 'X'
                AND ls_active_value-value <> '1'.
              CONTINUE.
            ENDIF.
          ENDIF.
          lv_tab_index = lv_tab_index + 1.
          lv_tab_selected = xsdbool( ls_tab-ucomm = iv_active_tab
            OR ( iv_active_tab IS INITIAL AND lv_tab_index = 1 ) ).
          lv_tab_text = ls_tab-text.
          READ TABLE it_values INTO ls_tab_value
            WITH KEY container = `` name = ls_tab-name row = 0.
          IF sy-subrc = 0 AND ls_tab_value-value IS NOT INITIAL.
            lv_tab_text = ls_tab_value-value.
          ENDIF.
          rv_html = rv_html && |<button class="{ zcl_gg_host_html=>state_class( iv_selected = lv_tab_selected ) }" type="submit" role="tab" name="gg_action" value="| && |TAB:{ zcl_gg_host_html=>escape_attribute( CONV string( ls_tab-name ) ) }| && `|` && |{ zcl_gg_host_html=>escape_attribute( CONV string( ls_tab-ucomm ) ) }" aria-selected="{ COND string( WHEN lv_tab_selected = abap_true THEN `true` ELSE `false` ) }" data-target-screen="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_tab-subscreen ) ) }">{ zcl_gg_host_html=>escape_text( lv_tab_text ) }</button>|.
        ENDLOOP.
        rv_html = rv_html && |</div>|.
      WHEN 'SUBSCREEN_AREA'.
        rv_html = |<section class="gg-dynpro-control { iv_state_class }" style="{ iv_style }" data-subscreen-area="{ zcl_gg_host_html=>escape_attribute( iv_id ) }" role="region" aria-label="Subscreen area { zcl_gg_host_html=>escape_text( CONV string( is_control-name ) ) }"></section>|.
      WHEN 'TABLE_CONTROL'.
        rv_html = render_dynpro_table(
          is_screen   = is_screen
          is_control  = is_control
          iv_style    = iv_style
          it_controls = it_controls
          it_values   = it_values
          it_states   = it_states ).
      WHEN 'CUSTOM_CONTROL'.
        rv_html = |<div class="gg-dynpro-control { iv_state_class }" style="{ iv_style }" data-custom-control="{ zcl_gg_host_html=>escape_attribute( iv_id ) }" role="region" aria-label="Custom control { zcl_gg_host_html=>escape_text( CONV string( is_control-name ) ) }"></div>|.
      WHEN OTHERS.
        rv_html = |<div class="gg-dynpro-control { iv_state_class }" style="{ iv_style }">{ zcl_gg_host_html=>escape_text( is_control-text ) }</div>|.
    ENDCASE.
  ENDMETHOD.

  METHOD subscreen_for_area.
    DATA ls_value TYPE zif_gg_dynpro_types_v1=>ty_value.

    rv_screen = is_area-subscreen.
    IF rv_screen IS INITIAL AND is_area-subscreen_field IS NOT INITIAL.
      READ TABLE it_values INTO ls_value
        WITH KEY container = ``
                 name = is_area-subscreen_field
                 row = 0.
      IF sy-subrc = 0.
        rv_screen = CONV #( ls_value-value ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD dynpro_geometry.
    DATA lv_control_bottom TYPE i.

    cv_render_height = iv_height + iv_header_height.
    LOOP AT it_controls INTO DATA(ls_control)
        WHERE screen = is_screen-number.
      lv_control_bottom = ls_control-position-row + iv_header_height + COND i( WHEN ls_control-position-height > 26 THEN ls_control-position-height ELSE 26 ).
      IF lv_control_bottom + 8 > cv_render_height.
        cv_render_height = lv_control_bottom + 8.
      ENDIF.
    ENDLOOP.
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
      DATA(lv_state_attr) = COND string(
        WHEN lv_display_type = zif_gg_session_types_v1=>message_type_warning
          THEN ` data-state="warning gg-state-warning"`
        WHEN lv_display_type = zif_gg_session_types_v1=>message_type_error
          OR lv_display_type = zif_gg_session_types_v1=>message_type_abort
          OR lv_display_type = zif_gg_session_types_v1=>message_type_exit
          THEN ` data-state="error gg-state-error"`
        ELSE `` ).
      rv_html = rv_html && |<div id="{ zcl_gg_host_html=>escape_attribute( lv_message_id ) }" class="gg-message { zcl_gg_host_html=>message_class( lv_display_type ) }" role="alert" aria-live="polite"{ lv_state_attr } data-field="{ zcl_gg_host_html=>escape_attribute( CONV string( ls_message-field ) ) }">{ zcl_gg_host_html=>escape_text( ls_message-text ) }</div>|.
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

  METHOD active_selection_screen.
    rv_screen = COND string( WHEN iv_default IS INITIAL OR iv_default = '0000'
      THEN '1000' ELSE iv_default ).
    IF it_tabs IS INITIAL.
      RETURN.
    ENDIF.
    READ TABLE it_tabs INTO DATA(ls_tab) WITH KEY selected = abap_true.
    IF sy-subrc <> 0.
      READ TABLE it_tabs INTO ls_tab INDEX 1.
    ENDIF.
    IF sy-subrc = 0 AND ls_tab-subscreen IS NOT INITIAL.
      rv_screen = ls_tab-subscreen.
    ENDIF.
  ENDMETHOD.

  METHOD visible_selection_blocks.
    LOOP AT it_blocks INTO DATA(ls_block)
        WHERE screen = iv_screen.
      APPEND ls_block TO rt_blocks.
    ENDLOOP.
  ENDMETHOD.

  METHOD selection_help_section.
    IF iv_help_text IS NOT INITIAL.
      rv_html = |<section class="gg-instruction-region" aria-label="Instructions"><aside id="gg-help-text" class="gg-message gg-info" role="status">{ zcl_gg_host_html=>escape_text( iv_help_text ) }</aside></section>|.
    ENDIF.
  ENDMETHOD.

  METHOD value_help_button.
    IF iv_value_help = abap_false.
      RETURN.
    ENDIF.
    rv_html = |<button class="gg-help-button" type="submit" formnovalidate name="gg_action" value="VALUE_HELP:{ zcl_gg_host_html=>escape_attribute( iv_name ) }" aria-label="Value help for { zcl_gg_host_html=>escape_text( iv_label ) }">{ zcl_gg_host_icons=>icon( iv_name = 'search' ) }</button>|.
  ENDMETHOD.

  METHOD range_editor_button.
    rv_html = |<button class="gg-help-button gg-range-editor-open" type="button" data-range-editor-open="{ zcl_gg_host_html=>escape_attribute( iv_name ) }" aria-label="Multiple selection for { zcl_gg_host_html=>escape_text( iv_label ) }">{ zcl_gg_host_icons=>icon( iv_name = 'search' ) }</button>|.
  ENDMETHOD.

  METHOD range_row_actions.
    IF iv_first = abap_false.
      RETURN.
    ENDIF.
    rv_html = value_help_button(
      iv_name       = iv_name
      iv_label      = iv_label
      iv_value_help = iv_value_help ).
    IF iv_no_extension = abap_false AND iv_value_help = abap_false.
      rv_html = rv_html && range_editor_button(
        iv_name  = iv_name
        iv_label = iv_label ).
    ENDIF.
  ENDMETHOD.

  METHOD render_range_editor.
    DATA lt_ranges TYPE zif_gg_selection_screen_types=>ty_ranges.
    IF iv_enabled = abap_false.
      RETURN.
    ENDIF.
    lt_ranges = it_ranges.
    IF lt_ranges IS INITIAL.
      APPEND VALUE #( sign = 'I' option = 'EQ' ) TO lt_ranges.
    ENDIF.
    DATA(lv_title_id) = |gg-range-editor-title-{ iv_name }|.
    rv_html = |<div class="gg-range-editor-modal" hidden aria-hidden="true" role="dialog" aria-modal="true" aria-labelledby="{ zcl_gg_host_html=>escape_attribute( lv_title_id ) }" data-range-editor-modal="{ zcl_gg_host_html=>escape_attribute( iv_name ) }"><div class="gg-value-help-panel gg-range-editor-panel"><header class="gg-value-help-header"><h2 id="{ zcl_gg_host_html=>escape_attribute( lv_title_id ) }">Multiple selection: { zcl_gg_host_html=>escape_text( iv_label ) }</h2><button class="gg-value-help-close" type="button" data-range-editor-close aria-label="Close multiple selection">{ zcl_gg_host_icons=>icon( iv_name = 'circle-x' ) }</button></header><div class="gg-range-editor-body"><p>Enter include or exclude values and ranges.</p><div class="gg-range-editor-list" data-range-editor-list="{ zcl_gg_host_html=>escape_attribute( iv_name ) }">|.
    LOOP AT lt_ranges INTO DATA(ls_editor_range).
      DATA(lv_editor_index) = sy-tabix.
      DATA(lv_editor_prefix) = |gg_editor_{ iv_name }-{ lv_editor_index }|.
      rv_html = rv_html && |<div class="gg-range-editor-row" data-editor-index="{ lv_editor_index }"><select name="{ zcl_gg_host_html=>escape_attribute( lv_editor_prefix ) }-SIGN" aria-label="Sign"><option value="I"{ COND string( WHEN ls_editor_range-sign <> 'E' THEN ` selected` ELSE `` ) }>Include</option><option value="E"{ COND string( WHEN ls_editor_range-sign = 'E' THEN ` selected` ELSE `` ) }>Exclude</option></select><select name="{ zcl_gg_host_html=>escape_attribute( lv_editor_prefix ) }-OPTION" aria-label="Option"><option value="EQ"{ COND string( WHEN ls_editor_range-option = 'EQ' OR ls_editor_range-option IS INITIAL THEN ` selected` ELSE `` ) }>=</option><option value="BT"{ COND string( WHEN ls_editor_range-option = 'BT' THEN ` selected` ELSE `` ) }>Between</option><option value="GE"{ COND string( WHEN ls_editor_range-option = 'GE' THEN ` selected` ELSE `` ) }>>=</option><option value="LE"{ COND string( WHEN ls_editor_range-option = 'LE' THEN ` selected` ELSE `` ) }><=</option><option value="CP"{ COND string( WHEN ls_editor_range-option = 'CP' THEN ` selected` ELSE `` ) }>Contains</option><option value="NP"{ COND string( WHEN ls_editor_range-option = 'NP' THEN ` selected` ELSE `` ) }>Not contains</option></select><input type="text" name="{ zcl_gg_host_html=>escape_attribute( lv_editor_prefix ) }-LOW" value="{ zcl_gg_host_html=>escape_attribute( ls_editor_range-low ) }" aria-label="Low value">{ COND string( WHEN iv_no_intervals = abap_false THEN |<input type="text" name="{ zcl_gg_host_html=>escape_attribute( lv_editor_prefix ) }-HIGH" value="{ zcl_gg_host_html=>escape_attribute( ls_editor_range-high ) }" aria-label="High value">| ELSE `` ) }<button type="button" data-range-editor-remove aria-label="Remove range">x</button></div>|.
    ENDLOOP.
    rv_html = rv_html && |</div><div class="gg-range-editor-actions"><button type="button" data-range-editor-add>Add row</button><span class="gg-range-editor-spacer"></span><button type="button" data-range-editor-cancel>Cancel</button><button type="button" data-range-editor-apply>Apply</button></div></div></div></div>|.
  ENDMETHOD.

  METHOD render_selection_value_help.
    rv_html = |<div class="gg-value-help-modal" role="dialog" aria-modal="true" aria-labelledby="gg-value-help-title" data-help-field="{ zcl_gg_host_html=>escape_attribute( iv_name ) }"><div class="gg-value-help-panel"><header class="gg-value-help-header"><h2 id="gg-value-help-title">Value help</h2><button class="gg-value-help-close" type="button" data-value-help-close aria-label="Close value help">{ zcl_gg_host_icons=>icon( iv_name = 'circle-x' ) }</button></header><div class="gg-value-help-status" role="status" aria-label="Value help results"><section class="gg-value-help" role="region" aria-label="Value help"><ul>|.
    LOOP AT it_ranges INTO DATA(ls_range).
      DATA(lv_value) = ls_range-low.
      IF ls_range-high IS NOT INITIAL.
        lv_value = lv_value && | - { ls_range-high }|.
      ENDIF.
      rv_html = rv_html && |<li data-name="{ zcl_gg_host_html=>escape_attribute( iv_name ) }" data-value="{ zcl_gg_host_html=>escape_attribute( ls_range-low ) }" tabindex="0" role="option">{ zcl_gg_host_html=>escape_text( lv_value ) }</li>|.
    ENDLOOP.
    rv_html = rv_html && |</ul></section></div></div></div>|.
  ENDMETHOD.

  METHOD render_dynpro_popup.
    DATA lv_kind TYPE string.
    DATA lv_prefix TYPE string.

    lv_kind = is_popup-kind.
    lv_prefix = COND string(
      WHEN lv_kind = 'CONFIRM' THEN 'CONFIRM'
      WHEN lv_kind = 'VALUES' THEN 'VALUE'
      WHEN lv_kind = 'TABLE' THEN 'TABLE'
      WHEN lv_kind = 'MONTH' THEN 'MONTH'
      ELSE 'INFORM' ).
    rv_html = |<div class="gg-popup-modal" role="dialog" aria-modal="true" aria-labelledby="gg-popup-title" data-popup-kind="{ zcl_gg_host_html=>escape_attribute( lv_kind ) }" data-popup-start-row="{ is_popup-start_row }" data-popup-start-column="{ is_popup-start_column }"><div class="gg-value-help-panel gg-popup-panel"><header class="gg-value-help-header"><h2 id="gg-popup-title">{ zcl_gg_host_html=>escape_text( is_popup-title ) }</h2></header><div class="gg-popup-body">|.
    LOOP AT is_popup-text_lines INTO DATA(lv_line).
      rv_html = rv_html && |<p>{ zcl_gg_host_html=>escape_text( lv_line ) }</p>|.
    ENDLOOP.
    CASE lv_kind.
      WHEN 'VALUES'.
        LOOP AT is_popup-fields INTO DATA(ls_field).
          rv_html = rv_html && |<label class="gg-popup-field"><span>{ zcl_gg_host_html=>escape_text( COND string( WHEN ls_field-text IS INITIAL THEN ls_field-name ELSE ls_field-text ) ) }</span><input type="text" name="gg-popup-{ zcl_gg_host_html=>escape_attribute( ls_field-name ) }" value="{ zcl_gg_host_html=>escape_attribute( ls_field-value ) }"></label>|.
        ENDLOOP.
      WHEN 'TABLE'.
        rv_html = rv_html && |<table class="gg-popup-table"><caption>Choose a row</caption><thead><tr><th scope="col">Row</th><th scope="col">Value</th></tr></thead><tbody>|.
        LOOP AT is_popup-table_values INTO DATA(lv_table_value).
          rv_html = rv_html && |<tr><th scope="row">{ sy-tabix }</th><td><button type="submit" name="gg_action" value="POPUP:TABLE:{ sy-tabix }" formnovalidate>{ zcl_gg_host_html=>escape_text( lv_table_value ) }</button></td></tr>|.
        ENDLOOP.
        rv_html = rv_html && '</tbody></table>'.
    ENDCASE.
    rv_html = rv_html && |</div><footer class="gg-popup-actions">|.
    LOOP AT is_popup-buttons INTO DATA(ls_button).
      rv_html = rv_html && |<button type="submit" name="gg_action" value="POPUP:{ lv_prefix }:{ zcl_gg_host_html=>escape_attribute( ls_button-value ) }" formnovalidate>{ zcl_gg_host_html=>escape_text( ls_button-text ) }</button>|.
    ENDLOOP.
    rv_html = rv_html && |</footer></div></div></div>|.
  ENDMETHOD.

  METHOD spaces.
    IF iv_count > 0.
      rv_text = repeat( val = ` `
                        occ = iv_count ).
    ENDIF.
  ENDMETHOD.

  METHOD field_type_attrs.
    DATA lv_length TYPE i.

    lv_length = is_data_type-visible_length.
    IF lv_length <= 0.
      lv_length = is_data_type-length.
    ENDIF.

* Dates and times render at the width of their formatted value, not at the
* internal length. Numerics keep the declared length and align right.
    IF is_data_type-typ = 'D'.
      lv_length = 10.
    ELSEIF is_data_type-typ = 'T'.
      lv_length = 8.
    ELSEIF ( is_data_type-typ = 'I' OR is_data_type-typ = 'P'
             OR is_data_type-typ = 'N' OR is_data_type-typ = 'F' )
           AND lv_length <= 0.
      lv_length = 13.
    ENDIF.

    IF lv_length > 0.
      rv_attrs = | size="{ lv_length }"|.
    ENDIF.
    rv_attrs = rv_attrs && | class="{ data_type_class( iv_type        = is_data_type-typ
                                                       iv_extra_class = iv_extra_class ) }"|.
  ENDMETHOD.

  METHOD data_type_class.
    rv_class = COND string(
      WHEN iv_type = 'D' THEN `gg-type-date`
      WHEN iv_type = 'T' THEN `gg-type-time`
      WHEN iv_type = 'I' OR iv_type = 'P' OR iv_type = 'N' OR iv_type = 'F'
        THEN `gg-type-number`
      ELSE `gg-type-text` ).
    IF iv_extra_class IS NOT INITIAL.
      rv_class = |{ iv_extra_class } { rv_class }|.
    ENDIF.
  ENDMETHOD.

  METHOD dynpro_type_attrs.
    DATA lv_length TYPE i.

    lv_length = is_data_type-length.
    IF is_data_type-typ = 'D'.
      lv_length = 10.
    ELSEIF is_data_type-typ = 'T'.
      lv_length = 8.
    ELSEIF ( is_data_type-typ = 'I' OR is_data_type-typ = 'P'
             OR is_data_type-typ = 'N' OR is_data_type-typ = 'F' )
           AND lv_length <= 0.
      lv_length = 13.
    ENDIF.
    IF lv_length > 0.
      rv_attrs = | size="{ lv_length }"|.
    ENDIF.
    DATA(lv_class) = data_type_class(
      iv_type        = is_data_type-typ
      iv_extra_class = iv_extra_class ).
    rv_attrs = rv_attrs && | class="{ lv_class }"|.
  ENDMETHOD.

  METHOD external_value_attrs.
    IF iv_type = 'D' OR iv_type = 'T'.
      rv_attrs = | data-abap-type="{ zcl_gg_host_html=>escape_attribute( iv_type ) }" data-abap-value="{ zcl_gg_host_html=>escape_attribute( iv_value ) }"|.
    ENDIF.
  ENDMETHOD.

  METHOD state_attrs.
    IF is_state-visible = abap_false OR is_state-no_display = abap_true.
      rv_attrs = rv_attrs && ` hidden`.
    ENDIF.
    IF is_state-enabled = abap_false.
      rv_attrs = rv_attrs && ` disabled aria-disabled="true"`.
    ENDIF.
    IF is_state-obligatory = abap_true.
      rv_attrs = rv_attrs && ` required aria-required="true"`.
    ENDIF.
    IF iv_readonly = abap_true.
      rv_attrs = rv_attrs && ` readonly aria-readonly="true"`.
    ENDIF.
  ENDMETHOD.

  METHOD dynpro_attrs.
    IF is_state-visible = abap_false.
      rv_attrs = rv_attrs && ` hidden`.
    ENDIF.
    IF is_state-no_display = abap_true.
      rv_attrs = rv_attrs && ` hidden`.
    ENDIF.
    IF is_state-enabled = abap_false.
      rv_attrs = rv_attrs && ` disabled aria-disabled="true"`.
    ENDIF.
    IF is_state-required = abap_true.
      rv_attrs = rv_attrs && ` required aria-required="true"`.
    ENDIF.
    IF iv_readonly = abap_true.
      rv_attrs = rv_attrs && ` readonly aria-readonly="true"`.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
