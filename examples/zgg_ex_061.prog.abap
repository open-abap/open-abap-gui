REPORT zgg_ex_061.

* Release is only offered once the order is approved: the program excludes
* it, or Approve, depending on the order's state.

DATA gv_approved TYPE abap_bool.
DATA gv_released TYPE abap_bool.
DATA gt_excluded TYPE STANDARD TABLE OF sy-ucomm WITH DEFAULT KEY.

START-OF-SELECTION.
  PERFORM show.

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'APPROVE'.
      gv_approved = abap_true.
    WHEN 'RELEASE'.
      gv_released = abap_true.
  ENDCASE.
  PERFORM show.

FORM show.
  PERFORM set_status.
  WRITE / 'Order 4711'.
  WRITE / |Approved: { gv_approved }, released: { gv_released }|.
ENDFORM.

FORM set_status.
  CLEAR gt_excluded.
  IF gv_approved = abap_false OR gv_released = abap_true.
    APPEND 'RELEASE' TO gt_excluded.
  ENDIF.
  IF gv_approved = abap_true.
    APPEND 'APPROVE' TO gt_excluded.
  ENDIF.
  SET PF-STATUS 'ORDER' EXCLUDING gt_excluded.
ENDFORM.
