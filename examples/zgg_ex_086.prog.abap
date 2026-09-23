REPORT zgg_ex_086.
START-OF-SELECTION.
  WRITE / 'Row one fragment A'.
  WRITE / 'Row two fragment B'.
AT USER-COMMAND.
  FORMAT INTENSIFIED ON.
  WRITE / 'modified line one'.
  FORMAT INVERSE ON.
  WRITE / 'modified line two'.
