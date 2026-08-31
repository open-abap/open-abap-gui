CLASS zcl_gg_ex_095 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_list_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_095 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '95' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_095' description = 'List download' ).
  ENDMETHOD.
ENDCLASS.
