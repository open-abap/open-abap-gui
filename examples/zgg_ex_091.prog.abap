REPORT zgg_ex_091 LINE-COUNT 4(1) NO STANDARD PAGE HEADING.

END-OF-PAGE.
WRITE / |footer page { sy-pagno }|.

TOP-OF-PAGE.
  WRITE / |header page { sy-pagno }|.

START-OF-SELECTION.
  DO 8 TIMES.
    WRITE / |body { sy-index }|.
  ENDDO.
