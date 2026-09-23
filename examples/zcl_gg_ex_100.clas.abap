CLASS zcl_gg_ex_100 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_dynpro_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_100 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '100' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_100' description = 'PBO and PAI field transport' ).
  ENDMETHOD.
ENDCLASS.
