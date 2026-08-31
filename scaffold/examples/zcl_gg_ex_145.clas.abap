CLASS zcl_gg_ex_145 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_table_tree_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_145 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '145' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_145' description = 'SALV sort filter and aggregation' ).
  ENDMETHOD.
ENDCLASS.
