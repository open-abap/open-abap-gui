CLASS zcl_gg_db_helper DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS create.
    CLASS-METHODS reset.
    CLASS-METHODS clear.
    CLASS-METHODS destroy.

  PRIVATE SECTION.
    CLASS-DATA environment TYPE REF TO if_osql_test_environment.

ENDCLASS.

CLASS zcl_gg_db_helper IMPLEMENTATION.

  METHOD create.
    environment = cl_osql_test_environment=>create( VALUE #( ( 'ZSFLIGHT' ) ) ).
  ENDMETHOD.

  METHOD reset.
    environment->clear_doubles( ).
    environment->insert_test_data( zcl_gg_demo_data=>flights( ) ).
  ENDMETHOD.

  METHOD clear.
    environment->clear_doubles( ).
  ENDMETHOD.

  METHOD destroy.
    environment->destroy( ).
    CLEAR environment.
  ENDMETHOD.

ENDCLASS.
