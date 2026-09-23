CLASS zcx_gg_transaction_error DEFINITION PUBLIC INHERITING FROM cx_no_check FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    DATA mv_message TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING
        iv_message TYPE string.

ENDCLASS.

CLASS zcx_gg_transaction_error IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    mv_message = iv_message.
  ENDMETHOD.

ENDCLASS.
