REPORT zgg_ex_213.

* A local class becomes a helper class that reaches the report's data
* through its owner. A method's own DATA(lv_count) hides the report's
* lv_count, and TYPE zsflight names the dictionary structure, not the
* TABLES work area of the same name.

TYPES: BEGIN OF ty_row,
         id   TYPE i,
         name TYPE string,
       END OF ty_row.

TABLES zsflight.

DATA gt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
DATA lv_count TYPE i.

CLASS lcl_app DEFINITION.
  PUBLIC SECTION.
    METHODS run.
    METHODS show IMPORTING is_flight TYPE zsflight.
ENDCLASS.

CLASS lcl_app IMPLEMENTATION.
  METHOD run.
    DATA ls_flight TYPE zsflight.
    DATA lv_carrid TYPE zsflight-carrid.
    DATA(lv_count) = lines( gt_rows ).
    ls_flight-carrid = 'LH'.
    lv_carrid = ls_flight-carrid.
    zsflight = ls_flight.
    show( ls_flight ).
    WRITE / lv_carrid.
    WRITE / lv_count.
  ENDMETHOD.

  METHOD show.
    WRITE / is_flight-carrid.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  APPEND VALUE #( id = 1 name = `One` ) TO gt_rows.
  NEW lcl_app( )->run( ).
  WRITE / zsflight-carrid.
