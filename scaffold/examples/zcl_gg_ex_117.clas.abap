CLASS zcl_gg_ex_117 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_control_showcase_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.

CLASS zcl_gg_ex_117 IMPLEMENTATION.

  METHOD constructor.
    super->constructor( iv_mode = '117' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_117' description = 'Custom container' ).
  ENDMETHOD.

ENDCLASS.

