CLASS zcl_gg_ex_109 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_dynpro_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_109 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '109' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_109' description = 'Dynpro tabstrip with subscreens' ).
  ENDMETHOD.
ENDCLASS.
