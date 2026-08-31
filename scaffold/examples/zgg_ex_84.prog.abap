REPORT zgg_ex_84.
START-OF-SELECTION.
  HIDE: 'A', 'alpha'.
  WRITE / 'Repeated row'.
  HIDE: 'B', 'bravo'.
  WRITE / 'Repeated row'.
AT LINE-SELECTION.
  WRITE / 'Selected hidden value'.
