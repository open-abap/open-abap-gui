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
        wordwrap_to_linebreak_mode TYPE i DEFAULT 0
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
        only_when_modified TYPE i DEFAULT 0
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
        only_when_modified TYPE i DEFAULT 0
      EXPORTING
        text               TYPE string
        is_modified        TYPE i.

    METHODS set_readonly_mode
      IMPORTING
        readonly_mode TYPE i DEFAULT 1.

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
        mode TYPE i DEFAULT 1.

    METHODS set_textstream
      IMPORTING
        text TYPE string OPTIONAL.

    METHODS set_selection_pos
      IMPORTING
        from_line TYPE i
        from_pos  TYPE i
        to_line   TYPE i
        to_pos    TYPE i.

    METHODS clear_text.

    METHODS restore.

    METHODS load_file
      IMPORTING
        filename      TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS save_file
      IMPORTING
        filename      TYPE string
      RETURNING
        VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    DATA mv_text TYPE string.
    DATA mv_saved_text TYPE string.
    DATA mv_modified TYPE i.
    DATA mv_readonly TYPE i.
    DATA mv_cursor_line TYPE i.
    DATA mv_cursor_pos TYPE i.
    DATA mv_selection_from_line TYPE i.
    DATA mv_selection_from_pos TYPE i.
    DATA mv_selection_to_line TYPE i.
    DATA mv_selection_to_pos TYPE i.
    DATA mv_toolbar_mode TYPE i.
    DATA mv_statusbar_mode TYPE i.
    DATA mv_wordwrap_mode TYPE i.
    DATA mv_wordwrap_position TYPE i.
    DATA mv_wordwrap_to_linebreak TYPE i.
    DATA mv_fixed_font TYPE i.
    DATA mv_protected_from TYPE i.
    DATA mv_protected_to TYPE i.

ENDCLASS.

CLASS cl_gui_textedit IMPLEMENTATION.
  METHOD set_wordwrap_behavior.
    IF wordwrap_mode >= 0.
      mv_wordwrap_mode = wordwrap_mode.
    ENDIF.
    IF wordwrap_position >= 0.
      mv_wordwrap_position = wordwrap_position.
    ENDIF.
    mv_wordwrap_to_linebreak = wordwrap_to_linebreak_mode.
    cl_gui_control=>set_text_state(
      control           = me
      wordwrap_mode     = mv_wordwrap_mode
      wordwrap_position = mv_wordwrap_position
      wrap_to_linebreak = mv_wordwrap_to_linebreak ).
  ENDMETHOD.

  METHOD get_text_as_r3table.
    DATA lt_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    CLEAR table.
    is_modified = mv_modified.
    IF only_when_modified <> 0 AND mv_modified = 0.
      RETURN.
    ENDIF.
    SPLIT mv_text AT cl_abap_char_utilities=>newline INTO TABLE lt_lines.
    LOOP AT lt_lines ASSIGNING FIELD-SYMBOL(<line>).
      APPEND CONV string( <line> ) TO table.
    ENDLOOP.
    is_modified = mv_modified.
  ENDMETHOD.

  METHOD set_text_as_r3table.
    mv_saved_text = mv_text.
    CLEAR mv_text.
    LOOP AT table ASSIGNING FIELD-SYMBOL(<line>).
      IF mv_text IS NOT INITIAL.
        mv_text = mv_text && cl_abap_char_utilities=>newline.
      ENDIF.
      mv_text = mv_text && CONV string( <line> ).
    ENDLOOP.
    mv_modified = 1.
    mv_cursor_line = 1.
    mv_cursor_pos = 0.
    set_selection_pos( from_line = 1
                       from_pos  = 0
                       to_line   = 1
                       to_pos    = 0 ).
    cl_gui_control=>set_payload( control = me
                                 payload = mv_text ).
    cl_gui_control=>set_text_state(
      control     = me
      modified    = mv_modified
      cursor_line = mv_cursor_line
      cursor_pos  = mv_cursor_pos ).
  ENDMETHOD.

  METHOD set_textstream.
    mv_saved_text = mv_text.
    mv_text = text.
    mv_modified = 1.
    mv_cursor_line = 1.
    mv_cursor_pos = 0.
    set_selection_pos( from_line = 1
                       from_pos  = 0
                       to_line   = 1
                       to_pos    = 0 ).
    cl_gui_control=>set_payload( control = me
                                 payload = mv_text ).
    cl_gui_control=>set_text_state(
      control     = me
      modified    = mv_modified
      cursor_line = mv_cursor_line
      cursor_pos  = mv_cursor_pos ).
  ENDMETHOD.

  METHOD set_font_fixed.
    mv_fixed_font = mode.
    cl_gui_control=>set_text_state( control    = me
                                    fixed_font = mv_fixed_font ).
  ENDMETHOD.

  METHOD set_text_as_stream.
    set_text_as_r3table( text ).
  ENDMETHOD.

  METHOD delete_text.
    mv_saved_text = mv_text.
    CLEAR mv_text.
    mv_modified = 1.
    cl_gui_control=>set_payload( control = me
                                 payload = mv_text ).
    cl_gui_control=>set_text_state( control  = me
                                    modified = mv_modified ).
  ENDMETHOD.

  METHOD get_selection_pos.
    from_line = mv_selection_from_line.
    to_line = mv_selection_to_line.
    from_pos = mv_selection_from_pos.
    to_pos = mv_selection_to_pos.
  ENDMETHOD.

  METHOD set_selection_pos.
    mv_selection_from_line = COND #( WHEN from_line > 0 THEN from_line ELSE 1 ).
    mv_selection_from_pos = COND #( WHEN from_pos >= 0 THEN from_pos ELSE 0 ).
    mv_selection_to_line = COND #( WHEN to_line > 0 THEN to_line ELSE mv_selection_from_line ).
    mv_selection_to_pos = COND #( WHEN to_pos >= 0 THEN to_pos ELSE mv_selection_from_pos ).
    mv_cursor_line = mv_selection_to_line.
    mv_cursor_pos = mv_selection_to_pos.
    cl_gui_control=>set_text_state(
      control     = me
      cursor_line = mv_cursor_line
      cursor_pos  = mv_cursor_pos ).
  ENDMETHOD.

  METHOD protect_lines.
    IF protect_mode = 0.
      CLEAR: mv_protected_from, mv_protected_to.
    ELSE.
      mv_protected_from = COND #( WHEN from_line > 0 THEN from_line ELSE 1 ).
      mv_protected_to = COND #( WHEN to_line >= mv_protected_from THEN to_line ELSE mv_protected_from ).
    ENDIF.
    cl_gui_control=>set_text_state(
      control        = me
      protected_from = mv_protected_from
      protected_to   = mv_protected_to ).
  ENDMETHOD.

  METHOD go_to_line.
    DATA lv_line_count TYPE i.
    DATA lt_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    SPLIT mv_text AT cl_abap_char_utilities=>newline INTO TABLE lt_lines.
    lv_line_count = lines( lt_lines ).
    mv_cursor_line = COND #( WHEN line < 1 THEN 1
                             WHEN line > lv_line_count THEN lv_line_count
                             ELSE line ).
    mv_selection_from_line = mv_cursor_line.
    mv_selection_to_line = mv_cursor_line.
    mv_selection_from_pos = 0.
    mv_selection_to_pos = 0.
    mv_cursor_pos = 0.
    cl_gui_control=>set_text_state(
      control     = me
      cursor_line = mv_cursor_line
      cursor_pos  = mv_cursor_pos ).
  ENDMETHOD.

  METHOD set_readonly_mode.
    mv_readonly = readonly_mode.
    set_enable( COND #( WHEN readonly_mode = true THEN ' ' ELSE 'X' ) ).
    cl_gui_control=>set_text_state(
      control  = me
      readonly = xsdbool( mv_readonly <> 0 ) ).
  ENDMETHOD.

  METHOD constructor.
    mv_wordwrap_mode = wordwrap_mode.
    mv_wordwrap_position = wordwrap_position.
    mv_wordwrap_to_linebreak = wordwrap_to_linebreak_mode.
    mv_cursor_line = 1.
    mv_selection_from_line = 1.
    mv_selection_to_line = 1.
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'TEXTEDIT' ).
    parent->add_child( me ).
    cl_gui_control=>set_text_state(
      control           = me
      wordwrap_mode     = mv_wordwrap_mode
      wordwrap_position = mv_wordwrap_position
      wrap_to_linebreak = mv_wordwrap_to_linebreak
      cursor_line       = mv_cursor_line
      cursor_pos        = mv_cursor_pos
      modified          = mv_modified
      readonly          = xsdbool( mv_readonly <> 0 ) ).
  ENDMETHOD.

  METHOD set_toolbar_mode.
    mv_toolbar_mode = toolbar_mode.
    cl_gui_control=>set_text_state(
      control      = me
      toolbar_mode = xsdbool( mv_toolbar_mode <> 0 ) ).
  ENDMETHOD.

  METHOD set_statusbar_mode.
    mv_statusbar_mode = statusbar_mode.
    cl_gui_control=>set_text_state(
      control        = me
      statusbar_mode = xsdbool( mv_statusbar_mode <> 0 ) ).
  ENDMETHOD.

  METHOD get_textstream.
    is_modified = mv_modified.
    IF only_when_modified <> 0 AND mv_modified = 0.
      CLEAR text.
      RETURN.
    ENDIF.
    text = mv_text.
  ENDMETHOD.

  METHOD clear_text.
    delete_text( ).
  ENDMETHOD.

  METHOD restore.
    mv_text = mv_saved_text.
    mv_modified = 0.
    cl_gui_control=>set_payload( control = me
                                 payload = mv_text ).
    cl_gui_control=>set_text_state( control  = me
                                    modified = mv_modified ).
  ENDMETHOD.

  METHOD load_file.
    result = abap_false.
    RETURN.
  ENDMETHOD.

  METHOD save_file.
    result = abap_false.
    RETURN.
  ENDMETHOD.

ENDCLASS.
