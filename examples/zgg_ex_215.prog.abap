REPORT zgg_ex_215.

* An ALV grid on the default screen fills the screen and follows the window
* as it is resized, with no resize handling in the program.

TYPES: BEGIN OF ty_row,
         id     TYPE n LENGTH 4,
         name   TYPE c LENGTH 20,
         city   TYPE c LENGTH 20,
         amount TYPE i,
       END OF ty_row.

DATA go_grid TYPE REF TO cl_gui_alv_grid.
DATA gt_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.

FORM display_alv.
  DATA lt_fieldcat TYPE lvc_t_fcat.

  IF go_grid IS NOT INITIAL.
    RETURN.
  ENDIF.

  go_grid = NEW #( i_parent = cl_gui_container=>default_screen ).

  lt_fieldcat = VALUE #(
    ( fieldname = 'ID'     coltext = 'ID'     inttype = 'N' )
    ( fieldname = 'NAME'   coltext = 'Name'   inttype = 'C' )
    ( fieldname = 'CITY'   coltext = 'City'   inttype = 'C' )
    ( fieldname = 'AMOUNT' coltext = 'Amount' inttype = 'I' ) ).
  gt_rows = VALUE #( FOR i = 1 UNTIL i > 40
    ( id     = i
      name   = |Customer { i }|
      city   = COND #( WHEN i MOD 2 = 0 THEN 'Berlin' ELSE 'Lisbon' )
      amount = i * 100 ) ).

  go_grid->set_table_for_first_display(
    CHANGING
      it_fieldcatalog = lt_fieldcat
      it_outtab       = gt_rows ).
ENDFORM.

START-OF-SELECTION.
  CALL SCREEN 2000.

MODULE screen_output OUTPUT.
  PERFORM display_alv.
ENDMODULE.
