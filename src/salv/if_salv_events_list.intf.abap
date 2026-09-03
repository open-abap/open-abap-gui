INTERFACE if_salv_events_list PUBLIC.

  EVENTS end_of_page
    EXPORTING
      VALUE(page)          TYPE i
      VALUE(r_end_of_page) TYPE REF TO cl_salv_form_element.

  EVENTS top_of_page
    EXPORTING
      VALUE(page)          TYPE i
      VALUE(r_top_of_page) TYPE REF TO cl_salv_form_element
      VALUE(table_index)   TYPE i.

ENDINTERFACE.
