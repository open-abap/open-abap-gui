FORM show_factor.
  DATA(lv_result) = p_factor * 3.
  WRITE / lv_result.
  LOOP AT s_date INTO DATA(ls_date).
    WRITE / ls_date-low.
  ENDLOOP.
ENDFORM.
