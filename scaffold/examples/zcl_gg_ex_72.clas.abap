CLASS zcl_gg_ex_72 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_selection_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.

CLASS zcl_gg_ex_72 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '72' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_72' description = 'Include and exclude select-option ranges' ).
  ENDMETHOD.
ENDCLASS.
