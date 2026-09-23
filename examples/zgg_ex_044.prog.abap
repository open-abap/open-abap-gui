REPORT zgg_ex_044.

START-OF-SELECTION.
  SET PF-STATUS 'LIST' EXCLUDING 'DEL'.
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
