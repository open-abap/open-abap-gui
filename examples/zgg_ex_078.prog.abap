REPORT zgg_ex_078.

TABLES zsflight.

TYPES: BEGIN OF ty_carrier,
         carrid TYPE c LENGTH 3,
       END OF ty_carrier.

DATA gt_carriers TYPE STANDARD TABLE OF ty_carrier WITH DEFAULT KEY.

PARAMETERS p_car TYPE c LENGTH 3.
SELECT-OPTIONS s_rng FOR zsflight-carrid.
PARAMETERS p_req TYPE c LENGTH 20 OBLIGATORY.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_car.
  PERFORM carrier_help USING 'P_CAR'.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_rng-low.
  PERFORM carrier_help USING 'S_RNG-LOW'.

START-OF-SELECTION.
  WRITE p_car.
  LOOP AT s_rng.
    WRITE / s_rng-low.
  ENDLOOP.

FORM carrier_help USING iv_field TYPE csequence.
  gt_carriers = VALUE #( ( carrid = 'AA' ) ( carrid = 'LH' ) ( carrid = 'SQ' ) ).
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'CARRID'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = iv_field
      value_org   = 'S'
    TABLES
      value_tab   = gt_carriers.
ENDFORM.
