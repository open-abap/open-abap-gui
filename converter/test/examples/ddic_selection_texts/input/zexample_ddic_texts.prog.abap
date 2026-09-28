REPORT zexample_ddic_texts.

* Selection texts with dictionary reference: the text pool holds "." for
* P_CARR and S_DATE, so their labels are the field labels of the data
* elements, read at runtime. P_ROWS has a text of its own.
DATA gv_date TYPE zexample_fldate.

PARAMETERS p_carr TYPE zexample_airline.
SELECT-OPTIONS s_date FOR gv_date.
PARAMETERS p_rows TYPE i DEFAULT 10.

START-OF-SELECTION.
  WRITE: / 'Carrier:', p_carr.
  WRITE: / 'Rows:', p_rows.
