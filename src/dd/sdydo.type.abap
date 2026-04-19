TYPE-POOL sdydo.

TYPES sdydo_attribute TYPE c LENGTH 50.
TYPES sdydo_flag TYPE c LENGTH 1.
TYPES sdydo_text_element TYPE c LENGTH 255.
TYPES sdydo_text_table TYPE STANDARD TABLE OF sdydo_text_element WITH DEFAULT KEY.
TYPES sdydo_value TYPE c LENGTH 250.

TYPES: BEGIN OF sdydo_html_line,
         line TYPE c LENGTH 255,
       END OF sdydo_html_line.
TYPES sdydo_html_table TYPE STANDARD TABLE OF sdydo_html_line WITH DEFAULT KEY.