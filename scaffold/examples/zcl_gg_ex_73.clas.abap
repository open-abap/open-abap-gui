CLASS zcl_gg_ex_73 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_selection_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.

CLASS zcl_gg_ex_73 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '73' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_73' description = 'Multiple select-option rows' ).
  ENDMETHOD.
ENDCLASS.
