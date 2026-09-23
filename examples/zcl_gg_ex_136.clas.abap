CLASS zcl_gg_ex_136 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_table_tree_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_136 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '136' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_136' description = 'Editable ALV grid' ).
  ENDMETHOD.
ENDCLASS.
