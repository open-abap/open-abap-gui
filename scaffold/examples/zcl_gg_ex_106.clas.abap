CLASS zcl_gg_ex_106 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_dynpro_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_106 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '106' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_106' description = 'Editable table control' ).
  ENDMETHOD.
ENDCLASS.
