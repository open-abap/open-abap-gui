CLASS zcl_gg_ex_090 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_list_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_090 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '90' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_090' description = 'Unicode wide-list layout' ).
  ENDMETHOD.
ENDCLASS.
