CLASS zcl_gg_demo_data DEFINITION PUBLIC FINAL CREATE PUBLIC.

* The flights the example programs show. The host writes them to ZSFLIGHT
* before the first program starts; unit tests insert them into an OSQL test
* double, see zcl_gg_db_helper.

  PUBLIC SECTION.
    INTERFACES zif_gg_host_environment_v1.

    TYPES ty_flights TYPE STANDARD TABLE OF zsflight WITH DEFAULT KEY.

    CLASS-METHODS flights RETURNING VALUE(result) TYPE ty_flights.

ENDCLASS.

CLASS zcl_gg_demo_data IMPLEMENTATION.

  METHOD zif_gg_host_environment_v1~setup.
    MODIFY zsflight FROM TABLE @( flights( ) ).
  ENDMETHOD.

  METHOD zif_gg_host_environment_v1~teardown.
    DELETE zsflight FROM TABLE @( flights( ) ).
  ENDMETHOD.

  METHOD flights.
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
