REPORT zgg_ex_59.

START-OF-SELECTION.
  SET PF-STATUS 'SHELL59'.
  WRITE 'body'.

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'REFR'.
      WRITE / 'refreshed'.
    WHEN 'PRI'.
      WRITE / 'printed'.
    WHEN OTHERS.
      RETURN.
  ENDCASE.
