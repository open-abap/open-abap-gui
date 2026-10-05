REPORT zgg_ex_070.

PARAMETERS p_all RADIOBUTTON GROUP g1 DEFAULT 'X' USER-COMMAND branch.
PARAMETERS p_one RADIOBUTTON GROUP g1.

SELECTION-SCREEN BEGIN OF BLOCK b_all WITH FRAME TITLE TEXT-001.
PARAMETERS p_allv TYPE c LENGTH 20 MODIF ID all.
SELECTION-SCREEN END OF BLOCK b_all.

SELECTION-SCREEN BEGIN OF BLOCK b_one WITH FRAME TITLE TEXT-002.
PARAMETERS p_onev TYPE c LENGTH 20 MODIF ID one.
SELECTION-SCREEN END OF BLOCK b_one.

PARAMETERS p_req TYPE c LENGTH 20 OBLIGATORY.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'ALL'.
        screen-active = COND #( WHEN p_all = abap_true THEN 1 ELSE 0 ).
        MODIFY SCREEN.
      WHEN 'ONE'.
        screen-active = COND #( WHEN p_one = abap_true THEN 1 ELSE 0 ).
        MODIFY SCREEN.
    ENDCASE.
  ENDLOOP.

AT SELECTION-SCREEN ON BLOCK b_all.
  IF p_all = abap_true AND p_allv IS INITIAL AND sy-ucomm = 'ONLI'.
    MESSAGE 'Enter a value for all flights' TYPE 'E'.
  ENDIF.

AT SELECTION-SCREEN ON BLOCK b_one.
  IF p_one = abap_true AND p_onev IS INITIAL AND sy-ucomm = 'ONLI'.
    MESSAGE 'Enter a value for one flight' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  IF p_one = abap_true.
    WRITE p_onev.
  ELSE.
    WRITE p_allv.
  ENDIF.
