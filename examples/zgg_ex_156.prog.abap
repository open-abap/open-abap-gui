REPORT zgg_ex_156.

TYPES: BEGIN OF ty_connection,
         text TYPE c LENGTH 40,
       END OF ty_connection.

DATA gv_ok_code TYPE sy-ucomm.
DATA gv_answer TYPE c LENGTH 1.
DATA gv_returncode TYPE c LENGTH 1.
DATA gv_choice TYPE sy-tabix.
DATA gt_fields TYPE STANDARD TABLE OF sval WITH DEFAULT KEY.
DATA gs_field TYPE sval.
DATA gt_connections TYPE STANDARD TABLE OF ty_connection WITH DEFAULT KEY.
DATA gs_connection TYPE ty_connection.
DATA gv_result TYPE c LENGTH 60.

START-OF-SELECTION.
  gt_connections = VALUE #(
    ( text = 'LH 0400 Frankfurt - New York' )
    ( text = 'UA 0941 Frankfurt - San Francisco' )
    ( text = 'AF 0010 Paris - New York' ) ).
  CALL SCREEN 100.

MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'CONFIRM'.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = 'Cancel booking'
          text_question         = 'Cancel the booking for LH 0400?'
          text_button_1         = 'Yes'
          text_button_2         = 'No'
          display_cancel_button = abap_false
        IMPORTING
          answer                = gv_answer
        EXCEPTIONS
          text_not_found        = 1
          OTHERS                = 2.
      IF sy-subrc <> 0.
        gv_result = 'Popup failed'.
      ELSEIF gv_answer = '1'.
        gv_result = 'Booking cancelled'.
      ELSE.
        gv_result = 'Booking kept'.
      ENDIF.
    WHEN 'INFORM'.
      CALL FUNCTION 'POPUP_TO_INFORM'
        EXPORTING
          titel = 'Flight status'
          txt1  = 'Flight LH 0400 is fully booked.'
          txt2  = 'Choose another connection.'.
      gv_result = 'Information acknowledged'.
    WHEN 'VALUES'.
      CLEAR gt_fields.
      gs_field-tabname = 'SCARR'.
      gs_field-fieldname = 'CARRID'.
      gs_field-fieldtext = 'Airline'.
      gs_field-value = 'LH'.
      APPEND gs_field TO gt_fields.
      CALL FUNCTION 'POPUP_GET_VALUES'
        EXPORTING
          popup_title     = 'Choose airline'
        IMPORTING
          returncode      = gv_returncode
        TABLES
          fields          = gt_fields
        EXCEPTIONS
          error_in_fields = 1
          OTHERS          = 2.
      IF sy-subrc <> 0 OR gv_returncode = 'A'.
        gv_result = 'Input cancelled'.
      ELSE.
        READ TABLE gt_fields INTO gs_field INDEX 1.
        gv_result = |Airline { gs_field-value }|.
      ENDIF.
    WHEN 'TABLE'.
      CALL FUNCTION 'POPUP_WITH_TABLE_DISPLAY'
        EXPORTING
          endpos_col   = 60
          endpos_row   = 10
          startpos_col = 10
          startpos_row = 5
          titletext    = 'Choose connection'
        IMPORTING
          choise       = gv_choice
        TABLES
          valuetab     = gt_connections
        EXCEPTIONS
          break_off    = 1
          OTHERS       = 2.
      IF sy-subrc <> 0.
        gv_result = 'Selection cancelled'.
      ELSE.
        READ TABLE gt_connections INTO gs_connection INDEX gv_choice.
        gv_result = gs_connection-text.
      ENDIF.
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.
