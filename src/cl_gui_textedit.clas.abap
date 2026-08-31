CLASS cl_gui_textedit DEFINITION INHERITING FROM cl_gui_control PUBLIC.
  PUBLIC SECTION.
    CONSTANTS false TYPE i VALUE 0.
    CONSTANTS true  TYPE i VALUE 1.

    CONSTANTS wordwrap_at_fixed_position TYPE i VALUE 1.
    CONSTANTS wordwrap_at_windowborder TYPE i VALUE 2.
    CONSTANTS wordwrap_off TYPE i VALUE 3.

    CONSTANTS event_double_click TYPE i VALUE -601.

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

    METHODS get_text_as_r3table
      IMPORTING
        only_when_modified TYPE i DEFAULT false
      EXPORTING
        table              TYPE STANDARD TABLE
        is_modified        TYPE i.

    METHODS set_wordwrap_behavior
      IMPORTING
        wordwrap_mode              TYPE i DEFAULT -1
        wordwrap_position          TYPE i DEFAULT -1
        wordwrap_to_linebreak_mode TYPE i DEFAULT 0
      EXCEPTIONS
        error_cntl_call_method.

    METHODS get_textstream
      IMPORTING
        only_when_modified TYPE i DEFAULT false
      EXPORTING
        text               TYPE string
        is_modified        TYPE i.

    METHODS set_readonly_mode
      IMPORTING
        readonly_mode TYPE i DEFAULT true.

    METHODS get_selection_pos
      EXPORTING
        from_line TYPE i
        from_pos  TYPE i
        to_line   TYPE i
        to_pos    TYPE i
      EXCEPTIONS
        error_cntl_call_method.

    METHODS protect_lines
      IMPORTING
        from_line                     TYPE i
        to_line                       TYPE i
        protect_mode                  TYPE i DEFAULT 1
        enable_editing_protected_text TYPE i OPTIONAL
      EXCEPTIONS
        error_cntl_call_method.

    METHODS go_to_line
      IMPORTING
        line TYPE i
      EXCEPTIONS
        error_cntl_call_method.

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

  PRIVATE SECTION.
    DATA mv_text TYPE string.
    DATA mv_modified TYPE i.
    DATA mv_readonly TYPE i.
    DATA mv_cursor_line TYPE i.
    DATA mv_cursor_pos TYPE i.

ENDCLASS.

CLASS cl_gui_textedit IMPLEMENTATION.
  METHOD set_wordwrap_behavior.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_text_as_r3table.
    CLEAR table.
    APPEND mv_text TO table.
    is_modified = mv_modified.
  ENDMETHOD.

  METHOD set_text_as_r3table.
    CLEAR mv_text.
    LOOP AT table ASSIGNING FIELD-SYMBOL(<line>).
      IF mv_text IS NOT INITIAL.
        mv_text = mv_text && cl_abap_char_utilities=>newline.
      ENDIF.
      mv_text = mv_text && CONV string( <line> ).
    ENDLOOP.
    mv_modified = 1.
    cl_gui_control=>set_payload( control = me
                                 payload = mv_text ).
  ENDMETHOD.

  METHOD set_textstream.
    mv_text = text.
    mv_modified = 1.
    cl_gui_control=>set_payload( control = me
                                 payload = mv_text ).
  ENDMETHOD.

  METHOD set_font_fixed.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_text_as_stream.
    set_text_as_r3table( text ).
  ENDMETHOD.

  METHOD delete_text.
    CLEAR mv_text.
    mv_modified = 1.
    cl_gui_control=>set_payload( control = me
                                 payload = mv_text ).
  ENDMETHOD.

  METHOD get_selection_pos.
    from_line = mv_cursor_line.
    to_line = mv_cursor_line.
    from_pos = mv_cursor_pos.
    to_pos = mv_cursor_pos.
  ENDMETHOD.

  METHOD protect_lines.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD go_to_line.
    mv_cursor_line = line.
  ENDMETHOD.

  METHOD set_readonly_mode.
    mv_readonly = readonly_mode.
    set_enable( COND #( WHEN readonly_mode = true THEN ' ' ELSE 'X' ) ).
  ENDMETHOD.

  METHOD constructor.
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'TEXTEDIT' ).
    parent->add_child( me ).
  ENDMETHOD.

  METHOD set_toolbar_mode.
    ASSERT 1 = 2.
  ENDMETHOD.

  METHOD set_statusbar_mode.
    ASSERT 1 = 2.
  ENDMETHOD.

  METHOD get_textstream.
    text = mv_text.
    is_modified = mv_modified.
  ENDMETHOD.

ENDCLASS.
