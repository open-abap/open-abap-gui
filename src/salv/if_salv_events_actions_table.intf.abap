INTERFACE if_salv_events_actions_table PUBLIC.

  EVENTS double_click
    EXPORTING
      VALUE(row)    TYPE salv_de_row
      VALUE(column) TYPE salv_de_column.

  EVENTS link_click
    EXPORTING
      VALUE(row)    TYPE salv_de_row
      VALUE(column) TYPE salv_de_column.

ENDINTERFACE.
