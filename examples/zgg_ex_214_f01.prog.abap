* Routines of ZGG_EX_214, written with the macros of the main program.

FORM fill.
  add_item `Apple` 3.
  add_item `Pear` 5.
  log `Filled`.
ENDFORM.

FORM bump USING iv_name TYPE csequence.
  point_at iv_name.
  IF sy-subrc = 0.
    <gs_item>-qty = <gs_item>-qty + 1.
    gv_changes = gv_changes + 1.
    log `Bumped`.
  ENDIF.
ENDFORM.

FORM show.
  LOOP AT gt_items ASSIGNING <gs_item>.
    WRITE: / <gs_item>-name, <gs_item>-qty.
  ENDLOOP.
  WRITE: / 'Changes:', gv_changes.
  LOOP AT gt_log INTO DATA(lv_log).
    WRITE / lv_log.
  ENDLOOP.
ENDFORM.

FORM add_log USING iv_text TYPE string.
  APPEND iv_text TO gt_log.
ENDFORM.

FORM protect.
  lock_group 'NAM'.
ENDFORM.
