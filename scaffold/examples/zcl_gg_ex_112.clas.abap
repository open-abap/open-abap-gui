CLASS zcl_gg_ex_112 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_dynpro_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_112 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '112' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_112' description = 'SET SCREEN versus LEAVE TO SCREEN' ).
  ENDMETHOD.
ENDCLASS.
