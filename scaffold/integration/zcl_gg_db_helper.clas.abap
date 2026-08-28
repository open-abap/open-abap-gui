CLASS zcl_gg_db_helper DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS create.
    CLASS-METHODS reset.
    CLASS-METHODS clear.
    CLASS-METHODS destroy.

  PRIVATE SECTION.
    TYPES ty_flights TYPE STANDARD TABLE OF zsflight WITH DEFAULT KEY.
    CLASS-DATA environment TYPE REF TO if_osql_test_environment.
    CLASS-METHODS fixture RETURNING VALUE(result) TYPE ty_flights.

ENDCLASS.

CLASS zcl_gg_db_helper IMPLEMENTATION.

  METHOD create.
    environment = cl_osql_test_environment=>create( VALUE #( ( 'ZSFLIGHT' ) ) ).
  ENDMETHOD.

  METHOD reset.
    environment->clear_doubles( ).
    environment->insert_test_data( fixture( ) ).
  ENDMETHOD.

  METHOD clear.
    environment->clear_doubles( ).
  ENDMETHOD.

  METHOD destroy.
    environment->destroy( ).
    CLEAR environment.
  ENDMETHOD.

  METHOD fixture.
    result = VALUE #(
      ( carrid = 'AA' connid = '0017' fldate = '20260101'
        price = '0.00' currency = 'USD' planetype = 'BOEING 747'
        cityfrom = 'New York' cityto = 'London' )
      ( carrid = 'AA' connid = '0018' fldate = '20260115'
        price = '123.45' currency = 'USD' planetype = 'AIRBUS A320'
        cityfrom = 'Chicago' cityto = 'Paris' )
      ( carrid = 'LH' connid = '0400' fldate = '20260228'
        price = '999999999.99' currency = 'EUR' planetype = 'AIRBUS A350'
        cityfrom = 'Frankfurt' cityto = 'Tokyo' )
      ( carrid = 'LH' connid = '0401' fldate = '20991231'
        price = '42.50' currency = 'EUR' planetype = 'BOEING 737'
        cityfrom = 'Munich' cityto = 'Rome' )
      ( carrid = 'SQ' connid = '0020' fldate = '20260331'
        price = '12.34' currency = 'SGD' planetype = 'AIRBUS A380'
        cityfrom = 'Singapore' cityto = 'International Hub' ) ).
  ENDMETHOD.

ENDCLASS.
