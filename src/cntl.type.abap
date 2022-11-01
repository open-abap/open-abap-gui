TYPE-POOL cntl.

TYPES: BEGIN OF cntl_simple_event,
         eventid    TYPE i,
         appl_event TYPE c,
       END OF cntl_simple_event.

TYPES cntl_simple_events TYPE TABLE OF cntl_simple_event.