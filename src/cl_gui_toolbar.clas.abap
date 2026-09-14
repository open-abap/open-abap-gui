CLASS cl_gui_toolbar DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.

    CONSTANTS m_id_function_selected TYPE i VALUE 1.
    CONSTANTS m_id_dropdown_clicked TYPE i VALUE 2.

    CONSTANTS m_mode_vertical TYPE i VALUE 1.
    CONSTANTS m_mode_horizontal TYPE i VALUE 0.

    DATA m_table_button TYPE ttb_button READ-ONLY.

    METHODS constructor
      IMPORTING
        parent       TYPE REF TO cl_gui_container
        display_mode TYPE i OPTIONAL.

    METHODS add_button
      IMPORTING
        fcode       TYPE clike
        icon        TYPE c
        is_disabled TYPE abap_bool OPTIONAL
        butn_type   TYPE i
        text        TYPE char40 OPTIONAL
        quickinfo   TYPE text30 OPTIONAL
        is_checked  TYPE c OPTIONAL
      EXCEPTIONS
        cntl_error
        cntb_btype_error
        cntb_error_fcode.

    EVENTS dropdown_clicked
      EXPORTING
        VALUE(fcode) TYPE ui_func
        VALUE(posx)  TYPE i
        VALUE(posy)  TYPE i.

    METHODS assign_static_ctxmenu_table
      IMPORTING
        table_ctxmenu TYPE any.

    METHODS track_context_menu
      IMPORTING
        context_menu TYPE REF TO cl_ctmenu
        posx         TYPE i
        posy         TYPE i
      EXCEPTIONS
        ctmenu_error.

    METHODS set_button_info
      IMPORTING
        fcode     TYPE ui_func
        icon      TYPE any OPTIONAL
        text      TYPE char40 OPTIONAL
        quickinfo TYPE char30 OPTIONAL.

    METHODS set_static_ctxmenu
      IMPORTING
        fcode   TYPE clike
        icon    TYPE clike OPTIONAL
        ctxmenu TYPE any OPTIONAL
        btntype TYPE i OPTIONAL.

    EVENTS function_selected
      EXPORTING
        VALUE(fcode) TYPE any.

    METHODS add_button_group
      IMPORTING
        data_table                TYPE ttb_button
        g_target_editor_maximized TYPE abap_bool OPTIONAL.

    CLASS-METHODS fill_buttons_data_table
      IMPORTING
        fcode      TYPE ui_func
        icon       TYPE c
        disabled   TYPE c OPTIONAL
        butn_type  TYPE i
        text       TYPE clike OPTIONAL
        quickinfo  TYPE clike OPTIONAL
        checked    TYPE c OPTIONAL
      CHANGING
        data_table TYPE ttb_button
      EXCEPTIONS
        cntb_btype_error.

    METHODS set_button_state
      IMPORTING
        enabled TYPE c DEFAULT 'X'
        checked TYPE c DEFAULT ' '
        fcode   TYPE ui_func
      EXCEPTIONS
        cntl_error
        cntb_error_fcode.

    METHODS delete_button
      IMPORTING
        fcode TYPE ui_func
      EXCEPTIONS
        cntl_error
        cntb_error_fcode.

    METHODS set_button_visible
      IMPORTING
        visible TYPE c DEFAULT 'X'
        fcode   TYPE ui_func
      EXCEPTIONS
        cntl_error
        cntb_error_fcode.

    METHODS press_button
      IMPORTING
        fcode TYPE ui_func.

    METHODS press_dropdown
      IMPORTING
        fcode TYPE ui_func
        posx  TYPE i DEFAULT 0
        posy  TYPE i DEFAULT 0.

  PRIVATE SECTION.
    DATA mt_hidden_buttons TYPE ttb_button.
    DATA mt_context_items TYPE zcl_gg_context_menu_state=>ty_items.
    DATA mv_context_left TYPE i.
    DATA mv_context_top TYPE i.

    METHODS render_context_items.
ENDCLASS.

CLASS cl_gui_toolbar IMPLEMENTATION.
  METHOD set_button_visible.
    DATA lv_hidden_index TYPE sy-tabix.

    READ TABLE m_table_button INTO DATA(ls_button) WITH KEY function = fcode.
    IF visible IS INITIAL.
      IF sy-subrc = 0.
        APPEND ls_button TO mt_hidden_buttons.
        DELETE m_table_button INDEX sy-tabix.
      ENDIF.
    ELSE.
      READ TABLE mt_hidden_buttons INTO ls_button WITH KEY function = fcode.
      IF sy-subrc = 0.
        lv_hidden_index = sy-tabix.
        APPEND ls_button TO m_table_button.
        DELETE mt_hidden_buttons INDEX lv_hidden_index.
      ENDIF.
    ENDIF.
    cl_gui_control=>set_buttons( control = me
                                 buttons = m_table_button ).
  ENDMETHOD.

  METHOD delete_button.
    DELETE m_table_button WHERE function = fcode.
    DELETE mt_hidden_buttons WHERE function = fcode.
    cl_gui_control=>set_buttons( control = me
                                 buttons = m_table_button ).
  ENDMETHOD.

  METHOD set_button_state.
    READ TABLE m_table_button ASSIGNING FIELD-SYMBOL(<button>)
      WITH KEY function = fcode.
    IF sy-subrc = 0.
      <button>-disabled = COND #( WHEN enabled IS INITIAL THEN 'X' ELSE ' ' ).
      <button>-checked = checked.
      cl_gui_control=>set_buttons( control = me
                                   buttons = m_table_button ).
      RETURN.
    ENDIF.
    READ TABLE mt_hidden_buttons ASSIGNING <button> WITH KEY function = fcode.
    IF sy-subrc = 0.
      <button>-disabled = COND #( WHEN enabled IS INITIAL THEN 'X' ELSE ' ' ).
      <button>-checked = checked.
    ENDIF.
  ENDMETHOD.

  METHOD track_context_menu.
    CLEAR mt_context_items.
    IF context_menu IS BOUND.
      mt_context_items = zcl_gg_context_menu_state=>get_items( context_menu ).
    ENDIF.
    mv_context_left = posx.
    mv_context_top = posy.
    cl_gui_control=>set_payload(
      control = me
      payload = |buttons={ lines( m_table_button ) }; context-items={ lines( mt_context_items ) }; context-left={ mv_context_left }; context-top={ mv_context_top }| ).
    render_context_items( ).
  ENDMETHOD.

  METHOD press_button.
    READ TABLE m_table_button INTO DATA(ls_button)
      WITH KEY function = fcode.
    IF sy-subrc = 0 AND ls_button-disabled IS INITIAL.
      RAISE EVENT function_selected EXPORTING fcode = fcode.
    ENDIF.
  ENDMETHOD.

  METHOD press_dropdown.
    READ TABLE m_table_button INTO DATA(ls_button)
      WITH KEY function = fcode.
    IF sy-subrc = 0 AND ls_button-disabled IS INITIAL
        AND ( ls_button-butn_type = 3 OR ls_button-butn_type = 4 ).
      RAISE EVENT dropdown_clicked
        EXPORTING
          fcode = fcode
          posx  = posx
          posy  = posy.
    ENDIF.
  ENDMETHOD.

  METHOD render_context_items.
    DATA lv_html TYPE string.

    IF mt_context_items IS INITIAL.
      cl_gui_control=>set_html(
        control = me
        html    = `` ).
      RETURN.
    ENDIF.
    lv_html = |<ul class="gg-toolbar-menu" id="{ control_id }-menu" role="menu" aria-label="Toolbar menu">|.
    LOOP AT mt_context_items INTO DATA(ls_item).
      IF ls_item-hidden = abap_true.
        CONTINUE.
      ENDIF.
      IF ls_item-separator = abap_true.
        lv_html = lv_html && '<li role="separator" class="gg-toolbar-menu-separator"></li>'.
        CONTINUE.
      ENDIF.
      lv_html = lv_html && |<li role="none"><button type="submit" role="menuitem" name="gg_action" value="COMMAND:{ cl_gui_control=>escape_html( ls_item-fcode ) }"{ COND string( WHEN ls_item-disabled = abap_true THEN ' disabled aria-disabled="true"' ELSE '' ) }>{ cl_gui_control=>escape_html( ls_item-text ) }</button></li>|.
    ENDLOOP.
    lv_html = lv_html && '</ul>'.
    cl_gui_control=>set_html(
      control = me
      html    = lv_html ).
  ENDMETHOD.

  METHOD fill_buttons_data_table.
    APPEND VALUE #(
      function  = fcode
      icon      = icon
      disabled  = disabled
      butn_type = butn_type
      text      = text
      quickinfo = quickinfo
      checked   = checked ) TO data_table.
  ENDMETHOD.

  METHOD assign_static_ctxmenu_table.
    FIELD-SYMBOLS <table> TYPE ttb_button.
    ASSIGN table_ctxmenu TO <table>.
    IF sy-subrc = 0.
      CLEAR mt_context_items.
      LOOP AT <table> INTO DATA(ls_button).
        APPEND VALUE #( fcode    = CONV string( ls_button-function )
                        text     = CONV string( ls_button-text )
                        icon     = CONV string( ls_button-icon )
                        disabled = xsdbool( ls_button-disabled IS NOT INITIAL )
                        hidden   = abap_false ) TO mt_context_items.
      ENDLOOP.
      cl_gui_control=>set_payload(
        control = me
        payload = |buttons={ lines( m_table_button ) }; context-items={ lines( mt_context_items ) }| ).
      render_context_items( ).
    ENDIF.
  ENDMETHOD.

  METHOD add_button_group.
    APPEND LINES OF data_table TO m_table_button.
    cl_gui_control=>set_buttons( control = me
                                 buttons = m_table_button ).
  ENDMETHOD.

  METHOD set_button_info.
    READ TABLE m_table_button ASSIGNING FIELD-SYMBOL(<button>)
      WITH KEY function = fcode.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    IF icon IS SUPPLIED.
      <button>-icon = CONV #( icon ).
    ENDIF.
    IF text IS SUPPLIED.
      <button>-text = text.
    ENDIF.
    IF quickinfo IS SUPPLIED.
      <button>-quickinfo = quickinfo.
    ENDIF.
    cl_gui_control=>set_buttons( control = me
                                 buttons = m_table_button ).
  ENDMETHOD.

  METHOD constructor.
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'TOOLBAR' ).
    parent->add_child( me ).
  ENDMETHOD.

  METHOD set_static_ctxmenu.
    DATA lo_menu TYPE REF TO cl_ctmenu.
    TRY.
        lo_menu ?= ctxmenu.
      CATCH cx_root.
        CLEAR lo_menu.
    ENDTRY.
    IF lo_menu IS BOUND.
      mt_context_items = zcl_gg_context_menu_state=>get_items( lo_menu ).
    ENDIF.
    cl_gui_control=>set_payload(
      control = me
      payload = |static-context={ fcode }; items={ lines( mt_context_items ) }; type={ btntype }| ).
    render_context_items( ).
  ENDMETHOD.

  METHOD free.
    super->free( ).
  ENDMETHOD.

  METHOD add_button.
    fill_buttons_data_table(
      EXPORTING
        fcode      = fcode
        icon       = icon
        disabled   = COND #( WHEN is_disabled = abap_true THEN 'X' ELSE ' ' )
        butn_type  = butn_type
        text       = text
        quickinfo  = quickinfo
        checked    = is_checked
      CHANGING
        data_table = m_table_button ).
    cl_gui_control=>set_payload(
      control = me
      payload = |{ fcode } { text }| ).
    cl_gui_control=>set_buttons( control = me
                                 buttons = m_table_button ).
  ENDMETHOD.

ENDCLASS.
