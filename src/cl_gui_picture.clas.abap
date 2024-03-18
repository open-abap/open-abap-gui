CLASS cl_gui_picture DEFINITION INHERITING FROM cl_gui_control PUBLIC.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        i_parent TYPE REF TO cl_gui_container.
ENDCLASS.

CLASS cl_gui_picture IMPLEMENTATION.

  METHOD constructor.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

ENDCLASS.