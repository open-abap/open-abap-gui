REPORT zgg_ex_192.

* Two FORMs that each declare the same inline DATA after a popup.

START-OF-SELECTION.
  PERFORM ask_first.
  PERFORM ask_second.

FORM ask_first.
  DATA lv_answer TYPE c LENGTH 1.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      text_question = 'First?'
    IMPORTING
      answer        = lv_answer.
  DATA(lv_text) = |First: { lv_answer }|.
  WRITE / lv_text.
ENDFORM.

FORM ask_second.
  DATA lv_answer TYPE c LENGTH 1.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      text_question = 'Second?'
    IMPORTING
      answer        = lv_answer.
  DATA(lv_text) = strlen( lv_answer ).
  WRITE / lv_text.
ENDFORM.
