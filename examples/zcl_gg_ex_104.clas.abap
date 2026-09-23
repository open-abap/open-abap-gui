CLASS zcl_gg_ex_104 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_dynpro_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_104 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '104' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_104' description = 'Dynpro CHAIN validation' ).
  ENDMETHOD.
ENDCLASS.
