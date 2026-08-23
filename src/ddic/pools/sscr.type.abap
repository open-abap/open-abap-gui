TYPE-POOL sscr.

TYPES: BEGIN OF sscr_opt_list,
         name    TYPE c LENGTH 10,
         options TYPE rsoptions,
       END OF sscr_opt_list.

TYPES sscr_opt_list_tab TYPE STANDARD TABLE OF sscr_opt_list WITH DEFAULT KEY.

TYPES: BEGIN OF sscr_ass,
         kind    TYPE c LENGTH 1,
         name    TYPE c LENGTH 30,
         sg_main TYPE c LENGTH 1,
         sg_addy TYPE c LENGTH 1,
         op_main TYPE c LENGTH 10,
         op_addy TYPE c LENGTH 10,
       END OF sscr_ass.

TYPES sscr_ass_tab TYPE STANDARD TABLE OF sscr_ass WITH DEFAULT KEY.

TYPES: BEGIN OF sscr_restrict,
         opt_list_tab TYPE sscr_opt_list_tab,
         ass_tab      TYPE sscr_ass_tab,
       END OF sscr_restrict.
