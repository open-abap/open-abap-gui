CLASS zcl_gg_ex_92 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_list_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_92 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '92' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_92' description = 'Browser list paging controls' ).
  ENDMETHOD.
ENDCLASS.
