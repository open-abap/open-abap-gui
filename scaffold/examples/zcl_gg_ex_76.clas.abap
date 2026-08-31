CLASS zcl_gg_ex_76 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_rich_selection_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.

CLASS zcl_gg_ex_76 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_mode = '76' ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_76' description = 'Selection-screen pushbutton workflow' ).
  ENDMETHOD.
ENDCLASS.
