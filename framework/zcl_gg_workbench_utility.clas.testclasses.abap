CLASS ltcl_gg_workbench_utility DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS renders_styles FOR TESTING.
    METHODS renders_top FOR TESTING.
    METHODS renders_main_menu FOR TESTING.
    METHODS renders_status_owned_icon_bar FOR TESTING.
    METHODS routes_back_when_active FOR TESTING.
    METHODS renders_bottom FOR TESTING.
    METHODS renders_bottom_message_types FOR TESTING.
    METHODS renders_message_details FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_workbench_utility IMPLEMENTATION.

  METHOD renders_styles.
    DATA(lv_html) = zcl_gg_workbench_utility=>render_styles( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '.wb-menubar' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '.wb-status-menu-items{min-height:32px' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '.wb-statusbar' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '.wb-runtime-content' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '--gg-work-area:#d5e6f3' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '--gg-row:26px' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '--gg-input:#fff' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '.wb-command-input{width:190px' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'background:var(--gg-action)' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'border:1px solid var(--gg-border-dark)' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '.wb-skip-link:focus' ) ).
* A disabled command must not react to hover or to being pressed.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '.wb-command-button:not(:disabled):active' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '.wb-command-button:active' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '.wb-command-button:disabled:active' ) ).
* A status message pops out; an empty feedback slot stays plain, and the
* animation is dropped for readers who ask for reduced motion.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '@keyframes wb-status-pop' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '.wb-status-feedback:not(:empty){' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '.wb-status-error:not(:empty){' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '@media(prefers-reduced-motion:reduce)' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '@media(max-width:760px)' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'flex-wrap:wrap' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '.wb-runtime-content--dynpro{margin:6px 10px 0;padding:0;overflow:auto}' ) ).
  ENDMETHOD.

  METHOD renders_status_owned_icon_bar.
    DATA(lv_html) = zcl_gg_workbench_utility=>render_top(
      iv_runtime = abap_true
      is_status  = VALUE #( active_ucomm   = VALUE #( ( 'RUN' ) ( 'EXCLUDED' ) )
                            excluded_ucomm = VALUE #( ( 'EXCLUDED' ) )
                            icon_bar       = VALUE #(
                              ( ucomm = 'RUN'      label = `A & <Run>` icon = `not-a-real-icon` )
                              ( ucomm = 'INACTIVE' label = `Inactive` icon = `refresh` separator = abap_true )
                              ( ucomm = 'EXCLUDED' label = `Excluded` icon = `refresh` ) ) ) ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'title="A &amp; &lt;Run&gt;"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'value="COMMAND:RUN"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'value="COMMAND:INACTIVE"' ) ).
* An excluded function is not shown in the application toolbar.
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'data-ucomm="EXCLUDED"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-ucomm="INACTIVE" disabled' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-toolbar-separator' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-toolbar-scope="application-status"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '#wb-icon-square-dashed' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'not-a-real-icon' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '<svg on' ) ).

    DATA(lv_selection_html) = zcl_gg_workbench_utility=>render_top(
      iv_runtime      = abap_true
      iv_execute_form = `gg-host-form` ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_selection_html CS
      'form="gg-host-form" formnovalidate name="gg_ucomm" value="ONLI" data-key="F8"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_selection_html CS '#wb-icon-player-play' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'value="ONLI"' ) ).
  ENDMETHOD.

  METHOD routes_back_when_active.
    DATA(lv_program_html) = zcl_gg_workbench_utility=>render_top(
      iv_runtime    = abap_true
      iv_session_id = `S1`
      iv_page_id    = `P1`
      is_status     = VALUE #( active_ucomm = VALUE #( ( `BACK` ) ) ) ).
    DATA(lv_workbench_html) = zcl_gg_workbench_utility=>render_top(
      iv_runtime    = abap_true
      iv_session_id = `S1`
      iv_page_id    = `P1`
      is_status     = VALUE #( active_ucomm = VALUE #( ( `NEXT` ) ) ) ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_program_html CS 'value="COMMAND:BACK"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_program_html CS 'aria-label="Back"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_workbench_html CS 'form="wb-command-workbench"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_workbench_html CS 'value="COMMAND:BACK"' ) ).
  ENDMETHOD.

  METHOD renders_top.
    DATA(lv_html) = zcl_gg_workbench_utility=>render_top( ).
    DATA(lv_custom_html) = zcl_gg_workbench_utility=>render_top( iv_title = `<Example & title>` ).
    DATA(lv_untrusted_html) = zcl_gg_workbench_utility=>render_top( iv_title = `</h1><style>.wb-appbar{display:none}</style>` ).
    DATA(lv_icon_html) = zcl_gg_workbench_utility=>render_top(
      is_status = VALUE #( icon_bar = VALUE #( ( label = `Refresh` icon = `refresh` ) ) ) ).
    DATA(lv_dynpro_html) = zcl_gg_workbench_utility=>render_top(
      iv_title        = `Dynpro`
      iv_content_form = `gg-dynpro-form`
      is_status       = VALUE #( status = `STATUS` ) ).
    DATA(lv_menu_html) = zcl_gg_workbench_utility=>render_top(
      iv_runtime = abap_true
      is_status  = VALUE #( menus = VALUE #(
        ( code = `SAMPLE` text = `Sample` )
        ( code = `OPTIONS` text = `Options` ) ) ) ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-menubar' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-commandbar' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-appbar' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'wb-toolbar' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'wb-toolbar-button' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'Create' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'Add to favorites' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'title="Refresh"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_icon_html CS 'title="Refresh"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_icon_html CS 'wb-icon-refresh' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_icon_html CS 'wb-toolbar-label">Refresh</span>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>Workbench</h1>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_custom_html CS '&lt;Example &amp; title&gt;</h1>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_untrusted_html CS '&lt;/h1&gt;&lt;style&gt;.wb-appbar{display:none}&lt;/style&gt;' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_untrusted_html CS '</h1><style>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_dynpro_html CS '<span class="wb-brand">open-abap</span>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_dynpro_html CS 'id="wb-page-title"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_dynpro_html CS 'data-toolbar-scope="shell-menu"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_dynpro_html CS 'data-toolbar-scope="standard-command"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_menu_html CS '<nav class="wb-menu-items wb-status-menu-items" role="menubar" aria-label="Application menu"><details' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_menu_html CS '>Sample</summary>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_menu_html CS '>Options</summary>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_dynpro_html CS '>Dynpro</h1>' ) ).
* The app bar shows the title only; the CUA status name shows in System > Status.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_dynpro_html CS '>Dynpro</h1></header>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_dynpro_html CS '<dt>GUI status</dt><dd>STATUS</dd>' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '<dt>GUI status</dt>' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_dynpro_html CS 'wb-appbar--dynpro' ) ).
  ENDMETHOD.

  METHOD renders_main_menu.
    DATA(lv_html) = zcl_gg_workbench_utility=>render_top( ).

* The main menu holds System and Help, nothing else.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS
      'aria-haspopup="menu" aria-expanded="false" aria-controls="wb-system-menu" data-system-menu>System</button>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS
      '<a class="wb-menu" role="menuitem" href="https://open-abap.org" target="_blank" rel="noopener noreferrer">Help</a>' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '>Applications<' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '>Favorites<' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '>Tools<' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '/converter/preview' ) ).
* System > Status opens the status dialog, hidden until then.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'aria-controls="wb-system-status" data-system-status-open>Status...</button>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS
      '<div id="wb-system-status" class="wb-dialog" role="dialog" aria-modal="true" aria-labelledby="wb-system-status-title" hidden>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>System: Status</h2>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS |<dt>Client</dt><dd>{ sy-mandt }</dd>| ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS |<dt>User</dt><dd>{ sy-uname }</dd>| ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS |<dt>System ID</dt><dd>{ sy-sysid }</dd>| ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS
      |<dt>System date</dt><dd>{ sy-datum+6(2) }.{ sy-datum+4(2) }.{ sy-datum(4) }</dd>| ) ).
  ENDMETHOD.

  METHOD renders_bottom.
    DATA(lv_html) = zcl_gg_workbench_utility=>render_bottom( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-statusbar' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-status-feedback' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'event.key!=="F3"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'wb-command-button--back:not(:disabled)' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<script>' ) ).
* F4 presses the value help of whichever field holds the cursor.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'event.key!=="F4"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '.gg-dynpro-field,.gg-field,.gg-range' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'gg-help-button:not(:disabled)' ) ).
* F1 posts field help when the focused field has an ABAP name.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'event.key==="F1"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'post(field,"gg_action","HELP:"+name)' ) ).
* F8, Enter, Escape, arrow navigation and modal focus trapping are explicit
* browser parity hooks rather than browser-default behavior.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'event.key==="F8"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'form.requestSubmit' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'event.key==="ArrowDown"' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-value-help-close' ) ).
* Feedback set while the page is open replays the entry animation and drops
* the error colour, so a neutral message is never painted as a failure.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'function announce(text,type)' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'F1: help todo' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'announce((button.getAttribute' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'void feedback.offsetWidth' ) ).
* Announcing drops whichever colour the previous message wore before it paints
* its own, so a success never keeps an error's red.
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'classList.remove("wb-status-error","wb-status-warning","wb-status-success","wb-status-info")' ) ).
  ENDMETHOD.

  METHOD renders_bottom_message_types.
* E, A and X are errors; the remaining types own a colour of their own. The
* icon of the type leads the text, the title holds the text in full.
    DATA(lv_error) = zcl_gg_workbench_utility=>render_bottom( iv_message = 'boom'
                                                              iv_type    = zif_gg_session_types_v1=>message_type_error ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_error CS
      'id="wb-status-message" class="wb-status-feedback wb-status-error" role="alert" aria-live="assertive" title="boom">' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_error CS '<use href="#wb-icon-alert-octagon"></use></svg><span class="wb-status-text">boom</span></span>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool(
      zcl_gg_workbench_utility=>render_bottom( iv_message = 'boom'
                                               iv_type    = zif_gg_session_types_v1=>message_type_abort ) CS
      'wb-status-error' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool(
      zcl_gg_workbench_utility=>render_bottom( iv_message = 'boom'
                                               iv_type    = zif_gg_session_types_v1=>message_type_exit ) CS
      'wb-status-error' ) ).
    DATA(lv_warning) = zcl_gg_workbench_utility=>render_bottom( iv_message = 'careful'
                                                                iv_type    = zif_gg_session_types_v1=>message_type_warning ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_warning CS
      'class="wb-status-feedback wb-status-warning" role="alert" aria-live="assertive" title="careful">' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_warning CS '#wb-icon-alert-triangle' ) ).
    DATA(lv_success) = zcl_gg_workbench_utility=>render_bottom( iv_message = 'saved'
                                                                iv_type    = zif_gg_session_types_v1=>message_type_success ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_success CS
      'class="wb-status-feedback wb-status-success" role="status" aria-live="polite" title="saved">' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_success CS '#wb-icon-circle-check' ) ).
    DATA(lv_info) = zcl_gg_workbench_utility=>render_bottom( iv_message = 'note'
                                                             iv_type    = zif_gg_session_types_v1=>message_type_info ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_info CS
      'class="wb-status-feedback wb-status-info" role="status" aria-live="polite" title="note">' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_info CS '#wb-icon-info-circle' ) ).
* The text is escaped in the bar and in the title alike.
    cl_abap_unit_assert=>assert_true( act = xsdbool(
      zcl_gg_workbench_utility=>render_bottom( iv_message = '<b>&'
                                               iv_type    = zif_gg_session_types_v1=>message_type_success ) CS
      'title="&lt;b&gt;&amp;"><svg' ) ).
* An empty bar stays a plain, uncoloured slot.
    DATA(lv_empty) = zcl_gg_workbench_utility=>render_bottom( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool(
      lv_empty CS '<span id="wb-status-message" class="wb-status-feedback" aria-live="polite"></span>' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_empty CS 'wb-status-text' ) ).
  ENDMETHOD.

  METHOD renders_message_details.
* The message as the program sent it gives the technical information behind
* the bar: its type, message class, number and variables.
    DATA(lv_html) = zcl_gg_workbench_utility=>render_bottom(
      iv_message = 'alpha beta'
      iv_type    = zif_gg_session_types_v1=>message_type_info
      is_message = VALUE #( type = zif_gg_session_types_v1=>message_type_info id = 'ZGG_EX' number = '001'
                            v1 = 'alpha' v2 = '<b>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS
      'title="alpha beta" aria-haspopup="dialog" aria-controls="wb-message-details">' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS
      '<div id="wb-message-details" class="wb-dialog" role="dialog" aria-modal="true" aria-labelledby="wb-message-details-title" hidden>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<dt>Message type</dt><dd>I</dd>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<dt>Message class</dt><dd>ZGG_EX</dd>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<dt>Message number</dt><dd>001</dd>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<dt>Variable 1</dt><dd>alpha</dd>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<dt>Variable 2</dt><dd>&lt;b&gt;</dd>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<dt>Variable 4</dt><dd></dd>' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '<dt>Field</dt>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'message.addEventListener("dblclick"' ) ).

* A free text message has no class; DISPLAY LIKE and the field it is about
* show as they were sent.
    lv_html = zcl_gg_workbench_utility=>render_bottom(
      iv_message = 'careful'
      iv_type    = zif_gg_session_types_v1=>message_type_warning
      is_message = VALUE #( type = zif_gg_session_types_v1=>message_type_success text = 'careful'
                            display_like = zif_gg_session_types_v1=>message_type_warning field = 'P_COUNT' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS
      '<dl><dt>Message type</dt><dd>S</dd><dt>Displayed like</dt><dd>W</dd><dt>Field</dt><dd>P_COUNT</dd></dl>' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '<dt>Message class</dt>' ) ).

* Without the program's message, as on the workbench, there is nothing to show.
    lv_html = zcl_gg_workbench_utility=>render_bottom( iv_message = 'boom' ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'id="wb-message-details"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'aria-haspopup' ) ).
  ENDMETHOD.

ENDCLASS.
