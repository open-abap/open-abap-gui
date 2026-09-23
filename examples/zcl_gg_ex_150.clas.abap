CLASS zcl_gg_ex_150 DEFINITION PUBLIC FINAL INHERITING FROM zcl_gg_analytics_cockpit_base CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_gg_transaction_v1.
    METHODS constructor.
ENDCLASS.
CLASS zcl_gg_ex_150 IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
  ENDMETHOD.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_150' description = 'Analytics cockpit' ).
  ENDMETHOD.
ENDCLASS.
