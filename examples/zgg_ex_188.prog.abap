REPORT zgg_ex_188.

* Tables declared LIKE an OCCURS table with a header line.

DATA : BEGIN OF bufline OCCURS 10 ,
         line(5000) ,        "Angela - era 2000
       END OF bufline .
DATA : i_batch LIKE bufline OCCURS 10 WITH HEADER LINE.
DATA : i_dosfile LIKE bufline OCCURS 10 WITH HEADER LINE.

START-OF-SELECTION.
  i_batch-line = 'batch'.
  APPEND i_batch.
  i_dosfile-line = 'dosfile'.
  APPEND i_dosfile.
  LOOP AT i_batch.
    WRITE / i_batch-line(10).
  ENDLOOP.
  LOOP AT i_dosfile.
    WRITE / i_dosfile-line(10).
  ENDLOOP.
