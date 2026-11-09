* Types and data of ZGG_EX_214.

TYPES: BEGIN OF ty_item,
         name TYPE string,
         qty  TYPE i,
       END OF ty_item.

DATA gt_items TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.
DATA gt_log TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

FIELD-SYMBOLS <gs_item> TYPE ty_item.
