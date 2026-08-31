CLASS zcl_gg_ex_87 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_list_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_87 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '87' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_87' description = 'Fragment-level colors and emphasis' ).
  ENDMETHOD.
ENDCLASS.
