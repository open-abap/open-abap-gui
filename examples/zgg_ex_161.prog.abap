REPORT zgg_ex_161.

* Two checkboxes in one chained PARAMETERS statement after a blank line. Each
* sits on a line of its own, as neither is inside BEGIN OF LINE.
SELECTION-SCREEN SKIP 1.
PARAMETERS: p_clean AS CHECKBOX DEFAULT abap_true,
            p_tsave AS CHECKBOX DEFAULT abap_false.

START-OF-SELECTION.
  IF p_clean = abap_true.
    WRITE / TEXT-001.
  ELSE.
    WRITE / TEXT-002.
  ENDIF.
  IF p_tsave = abap_true.
    WRITE / TEXT-003.
  ELSE.
    WRITE / TEXT-004.
  ENDIF.
