CLASS zcl_gg_ex_083 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_list_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_083 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '83' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_083' description = 'Multi-level drill-down' ).
  ENDMETHOD.
ENDCLASS.
