CLASS zcl_gg_ex_122 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_control_showcase_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.

CLASS zcl_gg_ex_122 IMPLEMENTATION.

  METHOD constructor.
    super->constructor( iv_mode = '122' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_122' description = 'Text editor' ).
  ENDMETHOD.

ENDCLASS.

