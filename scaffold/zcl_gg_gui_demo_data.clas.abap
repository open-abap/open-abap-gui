CLASS zcl_gg_gui_demo_data DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_product,
        id          TYPE c LENGTH 8,
        name        TYPE c LENGTH 30,
        category    TYPE c LENGTH 20,
        quantity    TYPE i,
        price       TYPE p LENGTH 8 DECIMALS 2,
        currency    TYPE c LENGTH 3,
        active      TYPE abap_bool,
        status      TYPE c LENGTH 1,
        description TYPE string,
      END OF ty_product,
      ty_products TYPE STANDARD TABLE OF ty_product WITH EMPTY KEY.

    CLASS-METHODS products
      RETURNING
        VALUE(result) TYPE ty_products.
ENDCLASS.

CLASS zcl_gg_gui_demo_data IMPLEMENTATION.
  METHOD products.
    result = VALUE #(
      ( id = 'P100' name = 'Mechanical Keyboard' category = 'Input'
        quantity = 12 price = '129.90' currency = 'EUR' active = abap_true
        status = 'A' description = 'Compact keyboard with tactile switches' )
      ( id = 'P110' name = 'Ergonomic Mouse' category = 'Input'
        quantity = 7 price = '74.50' currency = 'EUR' active = abap_true
        status = 'A' description = 'Wireless vertical mouse' )
      ( id = 'P200' name = '27 Inch Display' category = 'Display'
        quantity = 4 price = '389.00' currency = 'EUR' active = abap_true
        status = 'L' description = 'High resolution office display' )
      ( id = 'P300' name = 'USB-C Dock' category = 'Connectivity'
        quantity = 0 price = '219.00' currency = 'EUR' active = abap_false
        status = 'O' description = 'Docking station with power delivery' )
      ( id = 'P400' name = 'Conference Speaker' category = 'Audio'
        quantity = 9 price = '159.00' currency = 'EUR' active = abap_true
        status = 'A' description = 'Portable speakerphone for meeting rooms' ) ).
  ENDMETHOD.
ENDCLASS.
