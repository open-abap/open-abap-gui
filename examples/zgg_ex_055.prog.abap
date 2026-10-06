REPORT zgg_ex_055.

DATA gt_list TYPE STANDARD TABLE OF abaplist WITH DEFAULT KEY.
DATA gt_ascii TYPE STANDARD TABLE OF char255 WITH DEFAULT KEY.

START-OF-SELECTION.
  SUBMIT zgg_ex_001 EXPORTING LIST TO MEMORY AND RETURN.
  CALL FUNCTION 'LIST_FROM_MEMORY'
    TABLES
      listobject = gt_list.
  CALL FUNCTION 'LIST_TO_ASCI'
    TABLES
      listobject = gt_list
      listasci   = gt_ascii.
  LOOP AT gt_ascii INTO DATA(lv_line).
    WRITE / lv_line.
  ENDLOOP.
