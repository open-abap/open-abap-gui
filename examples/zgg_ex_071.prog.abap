REPORT zgg_ex_071.

TABLES: zsflight, sscrfields.

DATA gt_values TYPE vrm_values.

PARAMETERS p_car TYPE zsflight-carrid AS LISTBOX VISIBLE LENGTH 12 USER-COMMAND carrier DEFAULT 'AA'.
PARAMETERS p_con TYPE c LENGTH 5 AS LISTBOX VISIBLE LENGTH 12.

AT SELECTION-SCREEN OUTPUT.
  gt_values = VALUE #( ( key = 'AA' text = 'Alpha Air' )
                       ( key = 'LH' text = 'Lufthansa' ) ).
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_CAR'
      values = gt_values.
  IF p_car = 'LH'.
    gt_values = VALUE #( ( key = 'LH-1' text = 'LH-1' )
                         ( key = 'LH-2' text = 'LH-2' ) ).
  ELSE.
    gt_values = VALUE #( ( key = 'AA-1' text = 'AA-1' )
                         ( key = 'AA-2' text = 'AA-2' ) ).
  ENDIF.
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_CON'
      values = gt_values.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'CARRIER'.
      CLEAR p_con.
    WHEN 'ONLI'.
      IF p_con IS INITIAL.
        MESSAGE 'Select a connection' TYPE 'E'.
      ELSEIF p_con(2) <> p_car.
        MESSAGE 'Connection does not belong to the carrier' TYPE 'E'.
      ENDIF.
  ENDCASE.

START-OF-SELECTION.
  WRITE p_car.
  WRITE / p_con.
