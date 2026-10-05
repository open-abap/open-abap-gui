REPORT zgg_ex_170.

* Fills the selection screen of ZGG_EX_073 from an RSPARAMS table: the
* obligatory parameter P_REQ and two lines for the select-option S_MUL.

DATA ls_stable TYPE rsparams.
DATA lt_stable TYPE STANDARD TABLE OF rsparams WITH DEFAULT KEY.

START-OF-SELECTION.
  ls_stable-selname = 'P_REQ'.
  ls_stable-kind = 'P'.
  ls_stable-low = 'Weekly report'.
  APPEND ls_stable TO lt_stable.

  CLEAR ls_stable.
  ls_stable-selname = 'S_MUL'.
  ls_stable-kind = 'S'.
  ls_stable-sign = 'I'.
  ls_stable-option = 'EQ'.
  ls_stable-low = 'LH'.
  APPEND ls_stable TO lt_stable.

  ls_stable-option = 'BT'.
  ls_stable-low = 'AA'.
  ls_stable-high = 'BA'.
  APPEND ls_stable TO lt_stable.

  SUBMIT zgg_ex_073 WITH SELECTION-TABLE lt_stable AND RETURN.
  WRITE / 'back'.
