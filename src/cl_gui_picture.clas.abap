CLASS cl_gui_picture DEFINITION INHERITING FROM cl_gui_control PUBLIC.
  PUBLIC SECTION.
    CONSTANTS display_mode_fit TYPE i VALUE 2.

    METHODS constructor
      IMPORTING
        i_parent TYPE REF TO cl_gui_container.

    METHODS set_display_mode
      IMPORTING
        display_mode TYPE i.
ENDCLASS.

CLASS cl_gui_picture IMPLEMENTATION.

  METHOD constructor.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_display_mode.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

ENDCLASS.