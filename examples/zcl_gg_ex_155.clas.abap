CLASS zcl_gg_ex_155 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_plan9_examples_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.

CLASS zcl_gg_ex_155 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '155' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_155' description = 'Modeless dialog container' ).
  ENDMETHOD.
ENDCLASS.
