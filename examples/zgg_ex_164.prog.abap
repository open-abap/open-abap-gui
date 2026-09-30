REPORT zgg_ex_164.

DATA gv_queue TYPE c LENGTH 24.

PARAMETERS: p_in  RADIOBUTTON GROUP dir USER-COMMAND dir DEFAULT 'X',
            p_out RADIOBUTTON GROUP dir.
SELECT-OPTIONS s_inq FOR gv_queue MODIF ID in.
SELECT-OPTIONS s_outq FOR gv_queue MODIF ID out.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'IN'.
        screen-active = COND #( WHEN p_in = abap_true THEN '1' ELSE '0' ).
      WHEN 'OUT'.
        screen-active = COND #( WHEN p_out = abap_true THEN '1' ELSE '0' ).
    ENDCASE.
    MODIFY SCREEN.
  ENDLOOP.

START-OF-SELECTION.
  IF p_in = abap_true.
    WRITE / 'Cleaning inbound queues'.
  ELSE.
    WRITE / 'Cleaning outbound queues'.
  ENDIF.
