CLASS zcl_gg_ex_116 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_dynpro_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_116 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '116' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_116' description = 'Two-screen flight editor' ).
  ENDMETHOD.
ENDCLASS.
