CLASS zcl_gg_ex_84 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_list_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_84 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '84' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_84' description = 'Independent hidden values per row' ).
  ENDMETHOD.
ENDCLASS.
