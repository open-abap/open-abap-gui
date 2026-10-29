REPORT zgg_ex_190.

* Two FORMs with a local DATA of the same name but different types.

START-OF-SELECTION.
  PERFORM show_text.
  PERFORM show_number.
  PERFORM show_text.

FORM show_text.
  DATA lv_value TYPE c LENGTH 10.
  lv_value = 'text'.
  WRITE / lv_value.
ENDFORM.

FORM show_number.
  DATA lv_value TYPE i.
  lv_value = 42.
  lv_value = lv_value + 1.
  WRITE / lv_value.
ENDFORM.
