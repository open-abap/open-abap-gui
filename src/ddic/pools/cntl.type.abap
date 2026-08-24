TYPE-POOL cntl.

CONSTANTS cntl_lifetime_default TYPE i VALUE 0.
CONSTANTS cntl_lifetime_dynpro TYPE i VALUE 1.
CONSTANTS cntl_lifetime_imode TYPE i VALUE 2.

TYPES: BEGIN OF cntl_simple_event,
         eventid    TYPE i,
         appl_event TYPE c,
       END OF cntl_simple_event.

TYPES cntl_simple_events TYPE STANDARD TABLE OF cntl_simple_event WITH DEFAULT KEY.