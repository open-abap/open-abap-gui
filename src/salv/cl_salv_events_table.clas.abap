CLASS cl_salv_events_table DEFINITION PUBLIC INHERITING FROM cl_salv_events FRIENDS cl_salv_table.
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

  PROTECTED SECTION.
    METHODS raise_double_click
      IMPORTING
        row    TYPE salv_de_row
        column TYPE salv_de_column.

    METHODS raise_link_click
      IMPORTING
        row    TYPE salv_de_row
        column TYPE salv_de_column.

ENDCLASS.

CLASS cl_salv_events_table IMPLEMENTATION.

  METHOD raise_double_click.
    RAISE EVENT double_click
      EXPORTING
        row    = row
        column = column.
  ENDMETHOD.

  METHOD raise_link_click.
    RAISE EVENT link_click
      EXPORTING
        row    = row
        column = column.
  ENDMETHOD.

ENDCLASS.
