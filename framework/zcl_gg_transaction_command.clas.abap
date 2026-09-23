CLASS zcl_gg_transaction_command DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_result,
             valid TYPE abap_bool,
             tcode TYPE zif_gg_transaction_v1=>ty_tcode,
             error TYPE string,
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
      IF lv_command+lv_offset(1) <> ' '.
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
      rs_result-error = 'Unsupported command. Use /n followed by a transaction code.'.
      RETURN.
    ENDIF.
    lv_prefix = substring( val = lv_command
                           off = 0
                           len = 2 ).
    TRANSLATE lv_prefix TO UPPER CASE.
    IF lv_prefix <> '/N'.
      rs_result-error = 'Unsupported command. Use /n followed by a transaction code.'.
      RETURN.
    ENDIF.
    lv_tcode = substring( val = lv_command
                          off = 2 ).
    IF lv_tcode IS INITIAL.
      rs_result-error = 'A transaction code is required after /n.'.
      RETURN.
    ENDIF.
    IF lv_tcode(1) = ' '.
      rs_result-error = 'The transaction code must immediately follow /n.'.
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
