REPORT zgg_ex_054.

DATA gt_carr TYPE RANGE OF zsflight-carrid.

START-OF-SELECTION.
  gt_carr = VALUE #( ( sign = 'I' option = 'EQ' low = 'LH' ) ).
  SUBMIT zgg_ex_020
    USING SELECTION-SET 'STANDARD'
    WITH s_carr IN gt_carr
    AND RETURN.
  WRITE 'back'.
