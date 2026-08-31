REPORT zgg_ex_060.

START-OF-SELECTION.
  SET PF-STATUS 'SHELL60'.
  WRITE 'body'.

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'FIRST'.
      WRITE / 'first'.
    WHEN 'SECOND'.
      WRITE / 'second'.
    WHEN 'PRI'.
      WRITE / 'printed'.
    WHEN OTHERS.
      RETURN.
  ENDCASE.
