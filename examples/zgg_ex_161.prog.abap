REPORT zgg_ex_161.

SELECTION-SCREEN SKIP 1.
PARAMETERS: p_clean AS CHECKBOX DEFAULT abap_true,
            p_tsave AS CHECKBOX DEFAULT abap_false.

START-OF-SELECTION.
  WRITE / p_clean.
  WRITE / p_tsave.
