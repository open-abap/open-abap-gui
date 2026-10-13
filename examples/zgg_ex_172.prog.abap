REPORT zgg_ex_172.

* A transaction display that reads the transaction's attributes with the
* function module RPY_TRANSACTION_READ. A system without that function module
* fails the step with CX_SY_DYN_CALL_ILLEGAL_FUNC, and the failure names the
* function module that is missing.

PARAMETERS p_tcode TYPE c LENGTH 20 DEFAULT 'SE38'.

START-OF-SELECTION.
  CALL FUNCTION 'RPY_TRANSACTION_READ'
    EXPORTING
      transaction = p_tcode.
  WRITE / |Transaction { p_tcode } read|.
