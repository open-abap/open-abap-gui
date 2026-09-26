REPORT zexample_ddic.

* Parameters typed with data elements: abaplint resolves each to its
* built-in type through the dictionary objects next to the report, so an
* integer data element renders as a number field and a date one as a date.
DATA gv_date TYPE zexample_date.

PARAMETERS p_count TYPE zexample_count DEFAULT 3.
PARAMETERS p_amount TYPE zexample_amount.
PARAMETERS p_date TYPE zexample_date.
PARAMETERS p_carr TYPE zexample_carrier.
SELECT-OPTIONS s_date FOR gv_date.

START-OF-SELECTION.
  WRITE: / 'Runs:', p_count.
  WRITE: / 'Amount:', p_amount.
  WRITE: / 'Date:', p_date.
  WRITE: / 'Carrier:', p_carr.
