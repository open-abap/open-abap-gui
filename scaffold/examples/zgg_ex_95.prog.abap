REPORT zgg_ex_95.
START-OF-SELECTION.
  WRITE: / 'id,name', / '1,"Alpha, Inc."', / '2,"Bravo"'.
AT USER-COMMAND.
  IF sy-ucomm = 'DOWNLOAD'.
    WRITE / 'flights.csv'.
  ENDIF.
