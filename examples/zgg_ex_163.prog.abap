REPORT zgg_ex_163.

TYPES: BEGIN OF ty_status,
         traffic_light TYPE c LENGTH 4,
         event         TYPE c LENGTH 30,
         object        TYPE c LENGTH 20,
       END OF ty_status.

DATA gt_statuses TYPE STANDARD TABLE OF ty_status WITH DEFAULT KEY.
DATA ok_code TYPE sy-ucomm.

START-OF-SELECTION.
  gt_statuses = VALUE #(
    ( traffic_light = '@08@' event = 'CREATED' object = 'BUS2032' )
    ( traffic_light = '@0A@' event = 'CHANGED' object = 'BUS2105' ) ).
  CALL SCREEN 0100.

MODULE status_0100 OUTPUT.
  DATA lo_salv TYPE REF TO cl_salv_table.
  DATA lo_column TYPE REF TO cl_salv_column_table.

  SET TITLEBAR 'TITLE163'.
  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = lo_salv
        CHANGING
          t_table      = gt_statuses ).
      lo_column ?= lo_salv->get_columns( )->get_column( 'TRAFFIC_LIGHT' ).
      lo_column->set_icon( abap_true ).
      lo_column->set_short_text( 'Status' ).
    CATCH cx_salv_msg cx_salv_not_found.
      RETURN.
  ENDTRY.
  lo_salv->display( ).
ENDMODULE.

MODULE user_command_0100 INPUT.
  CLEAR ok_code.
ENDMODULE.
