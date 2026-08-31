CLASS zcl_gg_ex_78 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_selection_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.

CLASS zcl_gg_ex_78 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '78' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_78' description = 'Field and range value help' ).
  ENDMETHOD.
ENDCLASS.
