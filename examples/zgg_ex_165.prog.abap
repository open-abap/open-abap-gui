REPORT zgg_ex_165.

DATA gv_line TYPE string.

PARAMETERS p_file TYPE string LOWER CASE DEFAULT '/tmp/zgg_ex_165.txt'.

START-OF-SELECTION.
  OPEN DATASET p_file FOR INPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc <> 0.
    WRITE / 'File could not be opened'.
    RETURN.
  ENDIF.
  DO.
    READ DATASET p_file INTO gv_line.
    IF sy-subrc <> 0.
      EXIT.
    ENDIF.
    WRITE / gv_line.
  ENDDO.
  CLOSE DATASET p_file.
