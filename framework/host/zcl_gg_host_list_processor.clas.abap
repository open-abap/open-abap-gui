CLASS zcl_gg_host_list_processor DEFINITION PUBLIC FINAL CREATE PUBLIC.

* The functions the list processor runs itself. They act on the list and
* never reach AT USER-COMMAND: paging (P--, P-, P+, P++) and Print (PRI) run
* in the browser, which holds the list window; Find (%SC, %SC+) and Save to
* local file (%PC) ask in a dialog box and are answered here.

  PUBLIC SECTION.
    CONSTANTS find        TYPE zif_gg_session_types_v1=>ty_ucomm VALUE '%SC'.
    CONSTANTS find_next   TYPE zif_gg_session_types_v1=>ty_ucomm VALUE '%SC+'.
    CONSTANTS save_file   TYPE zif_gg_session_types_v1=>ty_ucomm VALUE '%PC'.
    CONSTANTS dialog_find TYPE string VALUE 'FIND'.
    CONSTANTS dialog_save TYPE string VALUE 'SAVE'.
    CONSTANTS format_unconverted TYPE string VALUE 'UNCONVERTED'.
    CONSTANTS format_spreadsheet TYPE string VALUE 'SPREADSHEET'.
    CONSTANTS format_richtext TYPE string VALUE 'RICHTEXT'.
    CONSTANTS format_html        TYPE string VALUE 'HTML'.

* term: what Find looks for; line: the list line of the last hit.
    TYPES: BEGIN OF ty_find,
             term       TYPE string,
             line       TYPE i,
             match_case TYPE abap_bool,
           END OF ty_find.
    TYPES: BEGIN OF ty_outcome,
             dialog    TYPE string,
             find      TYPE ty_find,
             found     TYPE i,
             hits      TYPE zcl_gg_host_list=>ty_render_lines,
             message   TYPE string,
             downloads TYPE zcl_gg_host_compatibility=>ty_downloads,
           END OF ty_outcome.

    CLASS-METHODS is_function
      IMPORTING
        iv_ucomm           TYPE zif_gg_session_types_v1=>ty_ucomm
      RETURNING
        VALUE(rv_function) TYPE abap_bool.

    "! The status of a list whose program sets none.
    CLASS-METHODS standard_status
      RETURNING
        VALUE(rs_status) TYPE zif_gg_session_types_v1=>ty_gui_status.

    "! iv_value is what the dialog box asked for: the search term of Find, the
    "! format of Save; iv_target the file name of Save.
    CLASS-METHODS process
      IMPORTING
        iv_ucomm          TYPE zif_gg_session_types_v1=>ty_ucomm
        iv_value          TYPE string OPTIONAL
        iv_target         TYPE string OPTIONAL
        iv_cursor         TYPE i OPTIONAL
        is_find           TYPE ty_find OPTIONAL
        it_lines          TYPE zcl_gg_host_list=>ty_render_lines
      RETURNING
        VALUE(rs_outcome) TYPE ty_outcome.

  PRIVATE SECTION.
    CLASS-METHODS line_text
      IMPORTING
        is_line        TYPE zcl_gg_host_list=>ty_render_line
        iv_separator   TYPE string OPTIONAL
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS search
      IMPORTING
        iv_term        TYPE string
        iv_after       TYPE i
        iv_match_case  TYPE abap_bool OPTIONAL
        it_lines       TYPE zcl_gg_host_list=>ty_render_lines
      RETURNING
        VALUE(rv_line) TYPE i.

    CLASS-METHODS file_content
      IMPORTING
        iv_format      TYPE string
        it_lines       TYPE zcl_gg_host_list=>ty_render_lines
      RETURNING
        VALUE(rv_text) TYPE string.

ENDCLASS.

CLASS zcl_gg_host_list_processor IMPLEMENTATION.

  METHOD is_function.
    rv_function = xsdbool(
      iv_ucomm = zif_gg_session_types_v1=>command_first_page
      OR iv_ucomm = zif_gg_session_types_v1=>command_previous_page
      OR iv_ucomm = zif_gg_session_types_v1=>command_next_page
      OR iv_ucomm = zif_gg_session_types_v1=>command_last_page
      OR iv_ucomm = zif_gg_session_types_v1=>command_print
      OR iv_ucomm = find
      OR iv_ucomm = find_next
      OR iv_ucomm = save_file ).
  ENDMETHOD.

  METHOD standard_status.
* Back, Exit and Cancel leave the list; the other functions are the list
* processor's. The keys are F3, Shift+F3 (F15), F12, Ctrl+P (F86),
* Ctrl+F (F71), Ctrl+G (F84) and F21 to F24 for the pages.
    rs_status = VALUE #(
      active_ucomm   = VALUE #( ( zif_gg_session_types_v1=>command_back )
                                ( zif_gg_session_types_v1=>command_exit )
                                ( zif_gg_session_types_v1=>command_cancel )
                                ( zif_gg_session_types_v1=>command_print )
                                ( find )
                                ( find_next )
                                ( save_file )
                                ( zif_gg_session_types_v1=>command_first_page )
                                ( zif_gg_session_types_v1=>command_previous_page )
                                ( zif_gg_session_types_v1=>command_next_page )
                                ( zif_gg_session_types_v1=>command_last_page ) )
      active_pf_keys = VALUE #( ( 3 ) ( 12 ) ( 15 ) ( 21 ) ( 22 ) ( 23 ) ( 24 ) ( 71 ) ( 84 ) ( 86 ) )
      pf_actions     = VALUE #( ( number = 3  ucomm = zif_gg_session_types_v1=>command_back )
                                ( number = 15 ucomm = zif_gg_session_types_v1=>command_exit )
                                ( number = 12 ucomm = zif_gg_session_types_v1=>command_cancel )
                                ( number = 86 ucomm = zif_gg_session_types_v1=>command_print )
                                ( number = 71 ucomm = find )
                                ( number = 84 ucomm = find_next )
                                ( number = 21 ucomm = zif_gg_session_types_v1=>command_first_page )
                                ( number = 22 ucomm = zif_gg_session_types_v1=>command_previous_page )
                                ( number = 23 ucomm = zif_gg_session_types_v1=>command_next_page )
                                ( number = 24 ucomm = zif_gg_session_types_v1=>command_last_page ) )
      menus          = VALUE #(
        ( code  = 'LIST'
          text  = 'List'
          items = VALUE #( ( ucomm = save_file text = 'Save to local file' )
                           ( ucomm = zif_gg_session_types_v1=>command_print text = 'Print' ) ) )
        ( code  = 'EDIT'
          text  = 'Edit'
          items = VALUE #( ( ucomm = find text = 'Find' )
                           ( ucomm = find_next text = 'Find next' ) ) ) ) ).
  ENDMETHOD.

  METHOD process.
    rs_outcome-find = is_find.
    CASE iv_ucomm.
      WHEN find OR find_next.
        IF iv_ucomm = find AND iv_value IS NOT INITIAL.
          rs_outcome-find = VALUE #( term = iv_value match_case = xsdbool( iv_target CS 'CASE' )
            line = COND #( WHEN iv_target CS 'CURSOR' THEN iv_cursor - 1 ) ).
        ELSEIF iv_ucomm = find OR is_find-term IS INITIAL.
          rs_outcome-dialog = dialog_find.
          RETURN.
        ENDIF.
        rs_outcome-found = search(
          iv_term       = rs_outcome-find-term
          iv_match_case = rs_outcome-find-match_case
          iv_after      = rs_outcome-find-line
          it_lines      = it_lines ).
        IF rs_outcome-found = 0 AND rs_outcome-find-line > 0.
          rs_outcome-found = search( iv_term  = rs_outcome-find-term
                                     iv_after = 0
            iv_match_case                     = rs_outcome-find-match_case
                                     it_lines = it_lines ).
        ENDIF.
        LOOP AT it_lines INTO DATA(ls_hit).
          DATA(lv_hit_text) = line_text( ls_hit ).
          IF ( rs_outcome-find-match_case = abap_false AND lv_hit_text CS rs_outcome-find-term )
              OR ( rs_outcome-find-match_case = abap_true AND contains( val = lv_hit_text
                                                                        sub = rs_outcome-find-term ) ).
            APPEND ls_hit TO rs_outcome-hits.
          ENDIF.
        ENDLOOP.
        IF rs_outcome-found = 0.
          rs_outcome-message = COND #(
            WHEN rs_outcome-find-line = 0 THEN |"{ rs_outcome-find-term }" was not found|
            ELSE |No further hits for "{ rs_outcome-find-term }"| ).
        ELSE.
          rs_outcome-find-line = rs_outcome-found.
        ENDIF.
      WHEN save_file.
        IF iv_value IS INITIAL.
          rs_outcome-dialog = dialog_save.
          RETURN.
        ENDIF.
        APPEND VALUE #(
          filename = COND #( WHEN iv_target IS INITIAL THEN `list.txt` ELSE iv_target )
          content  = cl_abap_codepage=>convert_to( file_content(
            iv_format = iv_value
            it_lines  = it_lines ) ) ) TO rs_outcome-downloads.
        rs_outcome-message = |The list was saved as { COND #( WHEN iv_target IS INITIAL THEN `list.txt` ELSE iv_target ) }|.
    ENDCASE.
  ENDMETHOD.

  METHOD line_text.
    DATA lv_column TYPE i VALUE 1.

    IF is_line-fragments IS INITIAL.
      rv_text = is_line-text.
      RETURN.
    ENDIF.
    LOOP AT is_line-fragments INTO DATA(ls_fragment).
      IF iv_separator IS NOT INITIAL.
        rv_text = rv_text && COND string( WHEN sy-tabix > 1 THEN iv_separator ) && condense( ls_fragment-text ).
        CONTINUE.
      ENDIF.
      IF ls_fragment-position > lv_column.
        rv_text = rv_text && repeat( val = ` `
                                     occ = ls_fragment-position - lv_column ).
      ENDIF.
      rv_text = rv_text && ls_fragment-text.
      lv_column = ls_fragment-position + strlen( ls_fragment-text ).
    ENDLOOP.
  ENDMETHOD.

  METHOD search.
* The search ignores case and goes on from the last hit.
    LOOP AT it_lines INTO DATA(ls_line) WHERE index > iv_after.
      DATA(lv_text) = line_text( ls_line ).
      IF ( iv_match_case = abap_false AND lv_text CS iv_term )
          OR ( iv_match_case = abap_true AND contains( val = lv_text
                                                       sub = iv_term ) ).
        rv_line = ls_line-index.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD file_content.
    DATA(lv_newline) = CONV string( cl_abap_char_utilities=>cr_lf ).
    DATA(lv_tab) = CONV string( cl_abap_char_utilities=>horizontal_tab ).

    CASE iv_format.
      WHEN format_spreadsheet.
        LOOP AT it_lines INTO DATA(ls_cells).
          rv_text = rv_text && line_text( is_line      = ls_cells
                                          iv_separator = lv_tab ) && lv_newline.
        ENDLOOP.
      WHEN format_richtext.
        rv_text = `{\rtf1\ansi\uc1 `.
        LOOP AT it_lines INTO DATA(ls_rtf).
          DATA(lv_rtf) = line_text( ls_rtf ).
          DO strlen( lv_rtf ) TIMES.
            DATA(lv_offset) = sy-index - 1.
            DATA(lv_character) = lv_rtf+lv_offset(1).
            DATA(lv_code) = cl_abap_conv_out_ce=>uccpi( lv_character ).
            IF lv_character = '\' OR lv_character = '{' OR lv_character = '}'.
              rv_text = rv_text && '\' && lv_character.
            ELSEIF lv_code > 127.
              IF lv_code > 32767.
                lv_code = lv_code - 65536.
              ENDIF.
              rv_text = rv_text && '\u' && |{ lv_code }?|.
            ELSE.
              rv_text = rv_text && lv_character.
            ENDIF.
          ENDDO.
          rv_text = rv_text && `\par `.
        ENDLOOP.
        rv_text = rv_text && '}'.
      WHEN format_html.
        rv_text = `<html><body><pre>`.
        LOOP AT it_lines INTO DATA(ls_html).
          rv_text = rv_text && escape( val    = line_text( ls_html )
                                       format = cl_abap_format=>e_html_text ) && lv_newline.
        ENDLOOP.
        rv_text = rv_text && `</pre></body></html>`.
      WHEN OTHERS.
        LOOP AT it_lines INTO DATA(ls_line).
          rv_text = rv_text && line_text( ls_line ) && lv_newline.
        ENDLOOP.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
