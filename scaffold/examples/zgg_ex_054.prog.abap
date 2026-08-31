REPORT zgg_ex_054.

START-OF-SELECTION.
  SUBMIT zgg_ex_020
    USING SELECTION-SET 'STANDARD'
    WITH s_carr IN VALUE #( ( sign = 'I' option = 'EQ' low = 'LH' ) )
    AND RETURN.
  WRITE 'back'.
