CLASS cl_gui_html_viewer DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.

    CONSTANTS uiflag_no3dborder TYPE i VALUE 4.
    CONSTANTS m_id_sapevent TYPE i VALUE 1.

    EVENTS sapevent
      EXPORTING
        VALUE(action)      TYPE c OPTIONAL
        VALUE(frame)       TYPE c OPTIONAL
        VALUE(getdata)     TYPE c OPTIONAL
        VALUE(postdata)    TYPE cnht_post_data_tab OPTIONAL
        VALUE(query_table) TYPE cnht_query_table OPTIONAL.

    METHODS constructor
      IMPORTING
        parent               TYPE REF TO cl_gui_container
        query_table_disabled TYPE c OPTIONAL.

    METHODS set_registered_events REDEFINITION.

    METHODS go_back.

    METHODS go_forward
      EXCEPTIONS
        cntl_error.

    METHODS do_refresh
      EXCEPTIONS
        cntl_error.

    METHODS close_document.

    METHODS get_current_url
      EXPORTING
        url TYPE c.

    METHODS load_data
      IMPORTING
        url          TYPE c OPTIONAL
        type         TYPE c DEFAULT 'text'
        subtype      TYPE c DEFAULT 'html'
        size         TYPE i DEFAULT 0
      EXPORTING
        assigned_url TYPE c
      CHANGING
        data_table   TYPE STANDARD TABLE
      EXCEPTIONS
        dp_invalid_parameter
        dp_error_general
        cntl_error
        html_syntax_notcorrect.

    METHODS show_url
      IMPORTING
        in_place TYPE abap_bool OPTIONAL
        url      TYPE c
      EXCEPTIONS
        cntl_error
        cnht_error_not_allowed
        cnht_error_parameter
        dp_error_general.

    METHODS set_ui_flag
      IMPORTING
        uiflag TYPE i DEFAULT 0
      EXCEPTIONS
        cntl_error.

    METHODS show_data
      IMPORTING
        url      TYPE c
        frame    TYPE c OPTIONAL
        in_place TYPE c DEFAULT 'X '
      EXCEPTIONS
        cntl_error
        cnht_error_not_allowed
        cnht_error_parameter
        dp_error_general.

  PROTECTED SECTION.
* An anchor or a form with the sapevent scheme posts SAPEVENT with what
* follows the scheme; the part after ? is the getdata of the event. The fields
* of a form arrive as frontend values just before, and become its postdata.
    METHODS receive_frontend_values REDEFINITION.
    METHODS dispatch_frontend_event REDEFINITION.
    METHODS is_application_event REDEFINITION.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_history,
             url         TYPE string,
             payload     TYPE string,
             is_external TYPE abap_bool,
           END OF ty_history.
    TYPES ty_history_tab TYPE STANDARD TABLE OF ty_history WITH DEFAULT KEY.

* How many characters of postdata go into one line. The line type is 1024
* wide, but abapGit, the consumer this was measured against, redeclares the
* table with 256-character lines and converts the event's table into it line
* by line, and works on every real system; so a frontend never hands it more
* than 256 characters per line, or every long form would lose its tail there.
    CONSTANTS c_post_data_chunk TYPE i VALUE 256.

    DATA mv_document TYPE string.
    DATA mv_current_url TYPE string.
    DATA mv_payload TYPE string.
    DATA mv_external_url TYPE abap_bool.
    DATA mv_ui_flag TYPE i.
    DATA mt_history TYPE ty_history_tab.
    DATA mv_history_index TYPE i.
    DATA mv_query_table_disabled TYPE abap_bool.
    DATA mt_form_fields TYPE zcl_gg_gui_runtime=>ty_fields.

    METHODS remember_current.
    METHODS publish_history.
    CLASS-METHODS escape_post_data
      IMPORTING
        text          TYPE string
      RETURNING
        VALUE(result) TYPE string.
    CLASS-METHODS unescape_query
      IMPORTING
        text          TYPE string
      RETURNING
        VALUE(result) TYPE string.
ENDCLASS.

CLASS cl_gui_html_viewer IMPLEMENTATION.
  METHOD set_registered_events.
* sapevent is the only event this control raises, so registering events on it
* means the loaded document wants its sapevent anchors dispatched. The generic
* events table of the base class is not inspected any further.
    super->set_registered_events( events ).
    cl_gui_control=>set_sapevent( control    = me
                                  registered = abap_true ).
  ENDMETHOD.

  METHOD receive_frontend_values.
    mt_form_fields = values.
  ENDMETHOD.

  METHOD dispatch_frontend_event.
    DATA lv_action      TYPE string.
    DATA lv_getdata     TYPE string.
    DATA lv_body        TYPE string.
    DATA lv_offset      TYPE i.
    DATA lv_line        TYPE cnht_post_data_line.
    DATA lt_postdata    TYPE cnht_post_data_tab.
    DATA lt_query_table TYPE cnht_query_table.
    DATA ls_query       TYPE cnht_query_struct.
    DATA lt_pairs       TYPE string_table.
    DATA lv_pair        TYPE string.
    DATA lv_name        TYPE string.
    DATA lv_value       TYPE string.
    DATA lt_fields      TYPE zcl_gg_gui_runtime=>ty_fields.
    DATA ls_field       TYPE zcl_gg_gui_runtime=>ty_field.

    lt_fields = mt_form_fields.
    CLEAR mt_form_fields.
    IF event <> 'SAPEVENT'
        OR NOT line_exists( mt_frontend_events[ eventid = m_id_sapevent ] ).
      RETURN.
    ENDIF.
    SPLIT concat_lines_of( table = params
                           sep   = `|` ) AT '?' INTO lv_action lv_getdata.

* postdata is the form as name=value pairs joined with "&", in lines of a
* fixed width, filled to the end, so that a consumer joins them back with the
* blanks kept. The text stays as typed, spaces and all: only the three
* characters the pairs are built from are escaped, so that a value can hold
* them, and those are among the escapes every consumer of this event undoes.
    LOOP AT lt_fields INTO ls_field.
      IF lv_body IS NOT INITIAL.
        lv_body = lv_body && `&`.
      ENDIF.
      lv_body = lv_body && escape_post_data( ls_field-name ) && `=` && escape_post_data( ls_field-value ).
    ENDLOOP.
    WHILE lv_offset < strlen( lv_body ).
      lv_line = substring( val = lv_body
                           off = lv_offset
                           len = nmin( val1 = c_post_data_chunk
                                       val2 = strlen( lv_body ) - lv_offset ) ).
      APPEND lv_line TO lt_postdata.
      lv_offset = lv_offset + c_post_data_chunk.
    ENDWHILE.

* query_table is the same data parsed, the pairs of getdata first, unless the
* viewer was constructed with query_table_disabled, as abapGit constructs it.
    IF mv_query_table_disabled = abap_false.
      SPLIT lv_getdata AT '&' INTO TABLE lt_pairs.
      LOOP AT lt_pairs INTO lv_pair.
        IF lv_pair IS INITIAL.
          CONTINUE.
        ENDIF.
        CLEAR lv_value.
        SPLIT lv_pair AT '=' INTO lv_name lv_value.
        ls_query-name = unescape_query( lv_name ).
        ls_query-value = unescape_query( lv_value ).
        APPEND ls_query TO lt_query_table.
      ENDLOOP.
      LOOP AT lt_fields INTO ls_field.
        ls_query-name = ls_field-name.
        ls_query-value = ls_field-value.
        APPEND ls_query TO lt_query_table.
      ENDLOOP.
    ENDIF.

    RAISE EVENT sapevent
      EXPORTING
        action      = lv_action
        getdata     = lv_getdata
        postdata    = lt_postdata
        query_table = lt_query_table.
  ENDMETHOD.

  METHOD escape_post_data.
    result = text.
    REPLACE ALL OCCURRENCES OF '%' IN result WITH '%25'.
    REPLACE ALL OCCURRENCES OF '&' IN result WITH '%26'.
    REPLACE ALL OCCURRENCES OF '=' IN result WITH '%3D'.
  ENDMETHOD.

  METHOD unescape_query.
* A plus sign is a blank and %XX a byte of UTF-8; a percent sign without two
* hex digits after it is kept as it is.
    DATA lv_text  TYPE string.
    DATA lv_index TYPE i.
    DATA lv_char  TYPE string.
    DATA lv_hex   TYPE string.
    DATA lv_byte  TYPE x LENGTH 1.
    DATA lv_bytes TYPE xstring.
    DATA lv_char_bytes TYPE xstring.

    lv_text = replace( val  = text
                       sub  = '+'
                       with = ` `
                       occ  = 0 ).
    WHILE lv_index < strlen( lv_text ).
      lv_char = substring( val = lv_text
                           off = lv_index
                           len = 1 ).
      CLEAR lv_hex.
      IF lv_char = '%' AND lv_index + 3 <= strlen( lv_text ).
        lv_hex = to_upper( substring( val = lv_text
                                      off = lv_index + 1
                                      len = 2 ) ).
      ENDIF.
      IF lv_hex IS NOT INITIAL AND lv_hex CO '0123456789ABCDEF'.
        lv_byte = lv_hex.
        CONCATENATE lv_bytes lv_byte INTO lv_bytes IN BYTE MODE.
        lv_index = lv_index + 3.
      ELSE.
        lv_char_bytes = cl_abap_codepage=>convert_to( lv_char ).
        CONCATENATE lv_bytes lv_char_bytes INTO lv_bytes IN BYTE MODE.
        lv_index = lv_index + 1.
      ENDIF.
    ENDWHILE.
    result = cl_abap_codepage=>convert_from( lv_bytes ).
  ENDMETHOD.

  METHOD is_application_event.
    READ TABLE mt_frontend_events INTO DATA(ls_event) WITH KEY eventid = m_id_sapevent.
    result = xsdbool( sy-subrc = 0 AND ls_event-appl_event = abap_true ).
  ENDMETHOD.

  METHOD set_ui_flag.
    mv_ui_flag = uiflag.
  ENDMETHOD.

  METHOD show_data.
    mv_current_url = url.
    mv_external_url = abap_false.
    mv_payload = mv_document.
    cl_gui_control=>set_payload( control = me
                                 payload = mv_current_url ).
    cl_gui_control=>set_html( control = me
                              html    = COND string( WHEN mv_document IS INITIAL
                                                    THEN '<!doctype html><html><body></body></html>'
                                                    ELSE mv_document ) ).
    remember_current( ).
  ENDMETHOD.

  METHOD show_url.
    IF url <> mv_current_url OR mv_external_url = abap_true.
      mv_current_url = url.
      CLEAR mv_document.
      mv_payload = url.
      mv_external_url = abap_true.
    ELSE.
      mv_payload = mv_document.
    ENDIF.
    cl_gui_control=>set_payload( control = me
                                 payload = mv_current_url ).
    cl_gui_control=>set_html( control = me
                              html    = COND string( WHEN mv_external_url = abap_false
                                                    AND mv_document IS INITIAL
                                                    THEN '<!doctype html><html><body></body></html>'
                                                    WHEN mv_external_url = abap_false
                                                    THEN mv_document
                                                    ELSE `` ) ).
    remember_current( ).
  ENDMETHOD.

  METHOD load_data.
    CLEAR mv_document.
    LOOP AT data_table ASSIGNING FIELD-SYMBOL(<line>).
      mv_document = mv_document && CONV string( <line> ).
    ENDLOOP.
    assigned_url = url.
    mv_current_url = url.
    mv_external_url = abap_false.
    mv_payload = mv_document.
    cl_gui_control=>set_payload( control = me
                                 payload = mv_current_url ).
    cl_gui_control=>set_html( control = me
                              html    = COND string( WHEN mv_document IS INITIAL
                                                    THEN '<!doctype html><html><body></body></html>'
                                                    ELSE mv_document ) ).
    remember_current( ).
  ENDMETHOD.

  METHOD get_current_url.
    url = mv_current_url.
  ENDMETHOD.

  METHOD close_document.
    CLEAR: mv_document, mv_current_url, mv_payload, mv_external_url,
           mt_history, mv_history_index.
    cl_gui_control=>set_payload( control = me
                                 payload = `` ).
    cl_gui_control=>set_html( control = me
                              html    = `` ).
  ENDMETHOD.

  METHOD go_back.
    IF mv_history_index > 1.
      mv_history_index = mv_history_index - 1.
      publish_history( ).
    ENDIF.
  ENDMETHOD.

  METHOD go_forward.
    IF mv_history_index < lines( mt_history ).
      mv_history_index = mv_history_index + 1.
      publish_history( ).
    ENDIF.
  ENDMETHOD.

  METHOD do_refresh.
    publish_history( ).
  ENDMETHOD.

  METHOD remember_current.
    DATA ls_history TYPE ty_history.

    IF mv_history_index > 0.
      WHILE lines( mt_history ) > mv_history_index.
        DELETE mt_history INDEX lines( mt_history ).
      ENDWHILE.
      READ TABLE mt_history INTO ls_history INDEX mv_history_index.
      IF sy-subrc = 0 AND ls_history-url = mv_current_url
          AND ls_history-payload = mv_payload
          AND ls_history-is_external = mv_external_url.
        RETURN.
      ENDIF.
    ENDIF.

    ls_history-url = mv_current_url.
    ls_history-payload = mv_payload.
    ls_history-is_external = mv_external_url.
    APPEND ls_history TO mt_history.
    mv_history_index = lines( mt_history ).
  ENDMETHOD.

  METHOD publish_history.
    READ TABLE mt_history INTO DATA(ls_history) INDEX mv_history_index.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    mv_current_url = ls_history-url.
    mv_payload = ls_history-payload.
    mv_external_url = ls_history-is_external.
    IF mv_external_url = abap_true.
      CLEAR mv_document.
    ELSE.
      mv_document = ls_history-payload.
    ENDIF.
    cl_gui_control=>set_payload( control = me
                                 payload = mv_current_url ).
    cl_gui_control=>set_html(
      control = me
      html    = COND string( WHEN mv_external_url = abap_false AND mv_document IS INITIAL
                              THEN '<!doctype html><html><body></body></html>'
                              WHEN mv_external_url = abap_true
                              THEN ``
                              ELSE mv_document ) ).
  ENDMETHOD.

  METHOD constructor.
    zcl_gg_gui_runtime=>initialize(
      control = me
      parent  = parent
      kind    = 'HTML_VIEWER' ).
    mv_query_table_disabled = xsdbool( query_table_disabled IS NOT INITIAL ).
  ENDMETHOD.

ENDCLASS.
