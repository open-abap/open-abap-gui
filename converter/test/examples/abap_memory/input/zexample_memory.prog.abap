REPORT zexample_memory.

DATA gv_counter TYPE i.
DATA gv_text TYPE string.

START-OF-SELECTION.
  gv_counter = 42.
  gv_text = `stored`.
  EXPORT gv_counter gv_text TO MEMORY ID 'ZEXAMPLE'.
  CLEAR: gv_counter, gv_text.
  IMPORT gv_counter gv_text FROM MEMORY ID 'ZEXAMPLE'.
  WRITE: / gv_counter, gv_text.
  FREE MEMORY ID 'ZEXAMPLE'.
