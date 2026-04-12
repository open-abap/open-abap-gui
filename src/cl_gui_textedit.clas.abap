CLASS cl_gui_textedit DEFINITION INHERITING FROM cl_gui_control PUBLIC.
  PUBLIC SECTION.
    CONSTANTS false TYPE i VALUE 0.
    CONSTANTS true  TYPE i VALUE 1.

    CONSTANTS wordwrap_at_fixed_position TYPE i VALUE 1.
    CONSTANTS wordwrap_at_windowborder TYPE i VALUE 2.
    CONSTANTS wordwrap_off TYPE i VALUE 3.

    METHODS constructor
      IMPORTING
        max_number_chars           TYPE i OPTIONAL
        wordwrap_mode              TYPE i DEFAULT wordwrap_at_windowborder
        wordwrap_to_linebreak_mode TYPE i DEFAULT false
        wordwrap_position          TYPE i DEFAULT -1
        parent                     TYPE REF TO cl_gui_container.

    METHODS set_toolbar_mode
      IMPORTING
        toolbar_mode TYPE i DEFAULT false.

    METHODS set_text_as_r3table
      IMPORTING
        table TYPE STANDARD TABLE OPTIONAL.

    METHODS set_statusbar_mode
      IMPORTING
        statusbar_mode TYPE i DEFAULT false.

    METHODS get_textstream
      IMPORTING
        only_when_modified TYPE i DEFAULT false
      EXPORTING
        text               TYPE string
        is_modified        TYPE i.

    METHODS set_readonly_mode
      IMPORTING
        readonly_mode TYPE i DEFAULT true.

    METHODS delete_text.

    METHODS set_text_as_stream
      IMPORTING
        text TYPE STANDARD TABLE OPTIONAL.

    METHODS set_font_fixed
      IMPORTING
        mode TYPE i DEFAULT true.

    METHODS set_textstream
      IMPORTING
        text TYPE string OPTIONAL.

ENDCLASS.

CLASS cl_gui_textedit IMPLEMENTATION.
  METHOD set_text_as_r3table.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_textstream.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_font_fixed.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_text_as_stream.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD delete_text.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_readonly_mode.
    RETURN. " todo, implement method
  ENDMETHOD.

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