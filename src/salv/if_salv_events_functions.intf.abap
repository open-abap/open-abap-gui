INTERFACE if_salv_events_functions PUBLIC.

  EVENTS added_function
    EXPORTING
      VALUE(e_salv_function) TYPE salv_de_function.

  EVENTS before_salv_function
    EXPORTING
      VALUE(e_salv_function) TYPE salv_de_function.

  EVENTS after_salv_function
    EXPORTING
      VALUE(e_salv_function) TYPE salv_de_function.

ENDINTERFACE.
