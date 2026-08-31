CLASS zcl_gg_ex_111 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_dynpro_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_111 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '111' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_111' description = 'Nested screen calls' ).
  ENDMETHOD.
ENDCLASS.
