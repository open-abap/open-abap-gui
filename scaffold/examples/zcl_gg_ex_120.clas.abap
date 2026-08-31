CLASS zcl_gg_ex_120 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_control_showcase_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.

CLASS zcl_gg_ex_120 IMPLEMENTATION.

  METHOD constructor.
    super->constructor( iv_mode = '120' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_120' description = 'Docking container' ).
  ENDMETHOD.

ENDCLASS.

