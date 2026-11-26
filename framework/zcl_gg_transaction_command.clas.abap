CLASS zcl_gg_transaction_command DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS c_unsupported TYPE string
      VALUE 'Unsupported command. Use /n or /o followed by a transaction code, or /i.'.

    TYPES: BEGIN OF ty_result,
             valid        TYPE abap_bool,
             tcode        TYPE zif_gg_transaction_v1=>ty_tcode,
             menu         TYPE abap_bool,
* /o opens the transaction in a new session, /i ends the current session.
             open_session TYPE abap_bool,
             end_session  TYPE abap_bool,
             error        TYPE string,
           END OF ty_result.

    CLASS-METHODS parse
      IMPORTING
        iv_command       TYPE string
      RETURNING
        VALUE(rs_result) TYPE ty_result.

ENDCLASS.

CLASS zcl_gg_transaction_command IMPLEMENTATION.

  METHOD parse.
    DATA lv_command TYPE string.
    DATA lv_prefix TYPE string.
    DATA lv_tcode TYPE string.
    DATA lv_length TYPE i.
    DATA lv_offset TYPE i.
    DATA lv_char TYPE c LENGTH 1.
    DATA lv_has_space TYPE abap_bool.
    DATA ls_transaction TYPE zcl_gg_transaction_registry=>ty_transaction.

    lv_command = iv_command.
    SHIFT lv_command LEFT DELETING LEADING space.
    lv_length = strlen( lv_command ).
    WHILE lv_length > 0.
      lv_offset = lv_length - 1.
      IF substring( val = lv_command
                    off = lv_offset
                    len = 1 ) <> ` `.
        EXIT.
      ENDIF.
      lv_length = lv_length - 1.
    ENDWHILE.
    IF lv_length < strlen( lv_command ).
      lv_command = substring( val = lv_command
                              off = 0
                              len = lv_length ).
    ENDIF.
    IF strlen( lv_command ) < 2.
      rs_result-error = c_unsupported.
      RETURN.
    ENDIF.
    lv_prefix = substring( val = lv_command
                           off = 0
                           len = 2 ).
    TRANSLATE lv_prefix TO UPPER CASE.
    IF lv_prefix = '/I'.
      IF strlen( lv_command ) > 2.
        rs_result-error = 'Nothing may follow /i.'.
        RETURN.
      ENDIF.
      rs_result-valid = abap_true.
      rs_result-end_session = abap_true.
      RETURN.
    ENDIF.
    IF lv_prefix <> '/N' AND lv_prefix <> '/O'.
      rs_result-error = c_unsupported.
      RETURN.
    ENDIF.
    rs_result-open_session = xsdbool( lv_prefix = '/O' ).
    TRANSLATE lv_prefix TO LOWER CASE.
    lv_tcode = substring( val = lv_command
                          off = 2 ).
*   A bare /n ends the current transaction and returns to the menu; a bare /o
*   opens the menu in a new session.
    IF condense( lv_tcode ) = ``.
      rs_result-valid = abap_true.
      rs_result-menu = abap_true.
      RETURN.
    ENDIF.
*   A string literal: a blank of type c would drop out of the comparison.
    IF substring( val = lv_tcode
                  len = 1 ) = ` `.
      rs_result-error = |The transaction code must immediately follow { lv_prefix }.|.
      RETURN.
    ENDIF.
    ls_transaction = zcl_gg_transaction_registry=>lookup( iv_tcode = lv_tcode ).
    IF ls_transaction-tcode IS INITIAL.
      CLEAR lv_has_space.
      DO strlen( lv_tcode ) TIMES.
        lv_offset = sy-index - 1.
        lv_char = lv_tcode+lv_offset(1).
        IF lv_char = ' '.
          lv_has_space = abap_true.
          EXIT.
        ENDIF.
      ENDDO.
      IF lv_has_space = abap_true.
        rs_result-error = 'Trailing tokens are not allowed after the transaction code.'.
      ELSE.
        rs_result-error = |Unknown transaction code: { lv_tcode }|.
      ENDIF.
      RETURN.
    ENDIF.
    rs_result-valid = abap_true.
    rs_result-tcode = ls_transaction-tcode.
  ENDMETHOD.

ENDCLASS.
