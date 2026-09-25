REPORT zexample_incl_type.

TYPES: BEGIN OF ty_alv,
         show_payload TYPE icon_d.
         INCLUDE TYPE zlog.
TYPES END OF ty_alv.

DATA: BEGIN OF gs_row.
        INCLUDE STRUCTURE zlog.
DATA:   flag TYPE c LENGTH 1,
      END OF gs_row.

DATA gt_alv TYPE STANDARD TABLE OF ty_alv WITH EMPTY KEY.

START-OF-SELECTION.
  PERFORM fill.
  WRITE: / lines( gt_alv ).

FORM fill.
  TYPES: BEGIN OF ty_local,
           id TYPE i.
           INCLUDE TYPE zlog.
  TYPES END OF ty_local.
  DATA ls_local TYPE ty_local.
  CLEAR ls_local.
ENDFORM.
