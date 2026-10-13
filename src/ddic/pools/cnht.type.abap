TYPE-POOL cnht.

* The types of the sapevent of cl_gui_html_viewer, as SAP declares them: the
* form fields of a POST as fixed-width lines, and the parsed name/value pairs.
TYPES cnht_post_data_line TYPE c LENGTH 1024.
TYPES cnht_post_data_tab TYPE STANDARD TABLE OF cnht_post_data_line WITH DEFAULT KEY.

TYPES: BEGIN OF cnht_query_struct,
         name  TYPE c LENGTH 30,
         value TYPE c LENGTH 250,
       END OF cnht_query_struct.
TYPES cnht_query_table TYPE STANDARD TABLE OF cnht_query_struct WITH DEFAULT KEY.
