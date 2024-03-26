CLASS cl_gui_picture DEFINITION INHERITING FROM cl_gui_control PUBLIC.
  PUBLIC SECTION.
    CONSTANTS display_mode_fit TYPE i VALUE 2.

    METHODS constructor
      IMPORTING
        parent TYPE REF TO cl_gui_container.

    METHODS clear_picture.

    METHODS free.

    METHODS set_display_mode
      IMPORTING
        display_mode TYPE i.

    METHODS load_picture_from_url_async
      IMPORTING
        url TYPE c.
ENDCLASS.

CLASS cl_gui_picture IMPLEMENTATION.

  METHOD load_picture_from_url_async.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD free.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD clear_picture.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD constructor.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_display_mode.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

ENDCLASS.