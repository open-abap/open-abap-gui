CLASS cl_gui_textedit DEFINITION INHERITING FROM cl_gui_control PUBLIC.
  PUBLIC SECTION.
    CONSTANTS false TYPE i VALUE 0.

    METHODS constructor
      IMPORTING
        max_number_chars TYPE i OPTIONAL
        parent           TYPE REF TO cl_gui_container.

    METHODS set_toolbar_mode
      IMPORTING
        toolbar_mode TYPE i DEFAULT false.

    METHODS set_statusbar_mode
      IMPORTING
        statusbar_mode TYPE i DEFAULT false.

    METHODS get_textstream
      IMPORTING
        only_when_modified TYPE i DEFAULT false
      EXPORTING
        text               TYPE string
        is_modified        TYPE i.

ENDCLASS.

CLASS cl_gui_textedit IMPLEMENTATION.

  METHOD constructor.
    ASSERT 1 = 2.
  ENDMETHOD.

  METHOD set_toolbar_mode.
    ASSERT 1 = 2.
  ENDMETHOD.

  METHOD set_statusbar_mode.
    ASSERT 1 = 2.
  ENDMETHOD.

  METHOD get_textstream.
    ASSERT 1 = 2.
  ENDMETHOD.

ENDCLASS.