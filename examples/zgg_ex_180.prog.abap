REPORT zgg_ex_180.

* Declarations typed LIKE a dictionary structure or one of its components,
* which a report allows and a class does not.

DATA: gv_text   LIKE t100-text,
      gt_return LIKE STANDARD TABLE OF bapiret2 WITH DEFAULT KEY WITH HEADER LINE,
      gt_lines  LIKE STANDARD TABLE OF t100 WITH DEFAULT KEY,
      gs_line   LIKE LINE OF gt_lines.

FORM show.
  DATA lv_class LIKE symsg-msgid VALUE 'ZGG'.
  DATA ls_client LIKE t000.
  gt_return-message = lv_class.
  APPEND gt_return.
  gs_line-text = gt_return-message.
  APPEND gs_line TO gt_lines.
  gv_text = gs_line-text.
  WRITE / |{ ls_client-mandt } { gv_text } { lines( gt_return ) } { lines( gt_lines ) }|.
ENDFORM.

START-OF-SELECTION.
  PERFORM show.
