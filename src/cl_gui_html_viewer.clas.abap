CLASS cl_gui_html_viewer DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.

    CONSTANTS uiflag_no3dborder TYPE i VALUE 4.
    CONSTANTS m_id_sapevent TYPE i VALUE 1.

    EVENTS sapevent
      EXPORTING
        VALUE(action)      TYPE c OPTIONAL
        VALUE(frame)       TYPE c OPTIONAL
        VALUE(getdata)     TYPE c OPTIONAL
        VALUE(postdata)    TYPE any OPTIONAL
        VALUE(query_table) TYPE any OPTIONAL.

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
        data_table   TYPE STANDARD TABLE.

    METHODS show_url
      IMPORTING
        in_place TYPE abap_bool OPTIONAL
        url      TYPE c.

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

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_history,
             url     TYPE string,
             payload TYPE string,
           END OF ty_history.
    TYPES ty_history_tab TYPE STANDARD TABLE OF ty_history WITH DEFAULT KEY.
    DATA mv_document TYPE string.
    DATA mv_current_url TYPE string.
    DATA mv_payload TYPE string.
    DATA mv_ui_flag TYPE i.
    DATA mt_history TYPE ty_history_tab.
    DATA mv_history_index TYPE i.

    METHODS remember_current.
    METHODS publish_history.
ENDCLASS.

CLASS cl_gui_html_viewer IMPLEMENTATION.
  METHOD set_registered_events.
* sapevent is the only event this control raises, so registering events on it
* means the loaded document wants its sapevent anchors dispatched. The generic
* events table of the base class is not inspected any further.
    cl_gui_control=>set_sapevent( control    = me
                                  registered = abap_true ).
  ENDMETHOD.

  METHOD set_ui_flag.
    mv_ui_flag = uiflag.
  ENDMETHOD.

  METHOD show_data.
    mv_current_url = url.
    mv_payload = mv_document.
    cl_gui_control=>set_payload( control = me
                                 payload = mv_document ).
    remember_current( ).
  ENDMETHOD.

  METHOD show_url.
    mv_current_url = url.
    mv_payload = CONV string( url ).
    cl_gui_control=>set_payload( control = me
                                 payload = CONV string( url ) ).
    remember_current( ).
  ENDMETHOD.

  METHOD load_data.
    CLEAR mv_document.
    LOOP AT data_table ASSIGNING FIELD-SYMBOL(<line>).
      mv_document = mv_document && CONV string( <line> ).
    ENDLOOP.
    assigned_url = url.
    mv_current_url = url.
    mv_payload = mv_document.
    cl_gui_control=>set_payload( control = me
                                 payload = mv_document ).
    remember_current( ).
  ENDMETHOD.

  METHOD get_current_url.
    url = mv_current_url.
  ENDMETHOD.

  METHOD close_document.
    CLEAR: mv_document, mv_current_url, mv_payload, mt_history, mv_history_index.
    cl_gui_control=>set_payload( control = me
                                 payload = `` ).
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
          AND ls_history-payload = mv_payload.
        RETURN.
      ENDIF.
    ENDIF.

    ls_history-url = mv_current_url.
    ls_history-payload = mv_payload.
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
    IF ls_history-payload = ls_history-url AND ls_history-url IS NOT INITIAL.
      CLEAR mv_document.
    ELSE.
      mv_document = ls_history-payload.
    ENDIF.
    cl_gui_control=>set_payload( control = me
                                 payload = ls_history-payload ).
  ENDMETHOD.

  METHOD constructor.
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'HTML_VIEWER' ).
    parent->add_child( me ).
  ENDMETHOD.

ENDCLASS.
