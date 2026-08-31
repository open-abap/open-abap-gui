CLASS zcl_gg_ex_085 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_list_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_085 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '85' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_085' description = 'Command-driven refresh' ).
  ENDMETHOD.
ENDCLASS.
