CLASS cl_gui_custom_container DEFINITION PUBLIC INHERITING FROM cl_gui_container.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        container_name TYPE c.
ENDCLASS.

CLASS cl_gui_custom_container IMPLEMENTATION.

  METHOD constructor.
    ASSERT 1 = 2.
  ENDMETHOD.

ENDCLASS.