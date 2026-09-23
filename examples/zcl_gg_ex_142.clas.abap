CLASS zcl_gg_ex_142 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_table_tree_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_142 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '142' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_142' description = 'Interactive tree events' ).
  ENDMETHOD.
ENDCLASS.
