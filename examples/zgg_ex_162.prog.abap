REPORT zgg_ex_162.

TYPES: BEGIN OF ty_event,
         event     TYPE c LENGTH 30,
         object    TYPE c LENGTH 20,
         paused_by TYPE c LENGTH 12,
       END OF ty_event.

DATA gt_events TYPE STANDARD TABLE OF ty_event WITH DEFAULT KEY.
DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA ok_code TYPE sy-ucomm.

START-OF-SELECTION.
  gt_events = VALUE #(
    ( event = 'CREATED' object = 'BUS2032' paused_by = 'DEVELOPER' )
    ( event = 'CHANGED' object = 'BUS2105' paused_by = 'BASIS' ) ).
  CALL SCREEN 0100.

MODULE status_0100 OUTPUT.
  DATA lt_fcat TYPE lvc_t_fcat.

  SET PF-STATUS 'STATUS162'.
  SET TITLEBAR 'TITLE162'.
  IF go_grid IS INITIAL.
    lt_fcat = VALUE #(
      ( fieldname = 'EVENT'     coltext = 'Event'     inttype = 'C' )
      ( fieldname = 'OBJECT'    coltext = 'Object'    inttype = 'C' )
      ( fieldname = 'PAUSED_BY' coltext = 'Paused by' inttype = 'C' ) ).
    CREATE OBJECT go_grid
      EXPORTING
        i_parent = cl_gui_container=>default_screen.
    go_grid->set_table_for_first_display(
      CHANGING
        it_outtab       = gt_events
        it_fieldcatalog = lt_fcat ).
  ELSE.
    go_grid->refresh_table_display( ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CLEAR ok_code.
ENDMODULE.
