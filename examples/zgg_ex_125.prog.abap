REPORT zgg_ex_125.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_function FOR EVENT function_selected OF cl_gui_toolbar
      IMPORTING fcode.
ENDCLASS.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_toolbar TYPE REF TO cl_gui_toolbar.
DATA go_menu TYPE REF TO cl_ctmenu.
DATA gt_events TYPE cntl_simple_events.
DATA gv_state TYPE c LENGTH 60.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_function.
    gv_state = |Toolbar function { fcode }|.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    CREATE OBJECT go_container
      EXPORTING
        container_name = 'CC_MAIN'.
    CREATE OBJECT go_toolbar
      EXPORTING
        parent = go_container.
    go_toolbar->add_button( fcode     = 'RUN'
                            icon      = icon_execute_object
                            butn_type = cntb_btype_button
                            text      = 'Run'
                            quickinfo = 'Run toolbar action' ).
    go_toolbar->add_button( fcode       = 'DISABLED'
                            icon        = icon_cancel
                            butn_type   = cntb_btype_button
                            text        = 'Disabled'
                            quickinfo   = 'Disabled action'
                            is_disabled = abap_true ).
    go_toolbar->add_button( fcode     = 'SEP1'
                            icon      = space
                            butn_type = cntb_btype_sep ).
    go_toolbar->add_button( fcode     = 'MENU'
                            icon      = icon_display
                            butn_type = cntb_btype_dropdown
                            text      = 'Menu'
                            quickinfo = 'Open toolbar menu' ).
    CREATE OBJECT go_menu.
    go_menu->add_function( fcode = 'MENU_ACTION'
                           text  = 'Menu action' ).
    go_toolbar->set_static_ctxmenu( fcode   = 'MENU'
                                    ctxmenu = go_menu ).
    gt_events = VALUE #( ( eventid    = cl_gui_toolbar=>m_id_function_selected
                           appl_event = abap_true ) ).
    go_toolbar->set_registered_events( gt_events ).
    SET HANDLER lcl_handler=>on_function FOR go_toolbar.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  cl_gui_cfw=>dispatch( ).
ENDMODULE.
