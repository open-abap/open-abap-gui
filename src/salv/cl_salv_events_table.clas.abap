CLASS cl_salv_events_table DEFINITION PUBLIC INHERITING FROM cl_salv_events.
  PUBLIC SECTION.

    INTERFACES if_salv_events_actions_table.

    EVENTS double_click
      EXPORTING
        VALUE(row)    TYPE salv_de_row
        VALUE(column) TYPE salv_de_column.

    EVENTS link_click
      EXPORTING
        VALUE(row)    TYPE salv_de_row
        VALUE(column) TYPE salv_de_column.

ENDCLASS.

CLASS cl_salv_events_table IMPLEMENTATION.

ENDCLASS.
