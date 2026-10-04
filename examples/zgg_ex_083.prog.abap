REPORT zgg_ex_083.

DATA gv_node TYPE string.

START-OF-SELECTION.
  gv_node = 'DETAIL'.
  WRITE / 'Basic list'.
  HIDE gv_node.

AT LINE-SELECTION.
  CASE gv_node.
    WHEN 'DETAIL'.
      gv_node = 'SUBDETAIL'.
      WRITE / 'Detail list'.
      HIDE gv_node.
    WHEN 'SUBDETAIL'.
      WRITE / 'Subdetail list'.
  ENDCASE.
