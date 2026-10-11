CLASS zcl_gg_gui_runtime DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_field,
             name  TYPE string,
             value TYPE string,
           END OF ty_field.
    TYPES ty_fields TYPE STANDARD TABLE OF ty_field WITH DEFAULT KEY.
    TYPES: BEGIN OF ty_sapevent,
             url          TYPE string,
             action_field TYPE string,
             fields       TYPE ty_fields,
           END OF ty_sapevent.

    CLASS-METHODS initialize
      IMPORTING
        control TYPE REF TO cl_gui_control
        parent  TYPE REF TO cl_gui_container OPTIONAL
        kind    TYPE string DEFAULT 'CONTROL'.

    CLASS-METHODS render_html
      IMPORTING
        iv_document        TYPE abap_bool DEFAULT abap_true
        iv_container_name  TYPE string OPTIONAL
        is_sapevent        TYPE ty_sapevent OPTIONAL
        iv_without_dialogs TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result)      TYPE string.

    CLASS-METHODS render_dialogs_html
      IMPORTING
        is_sapevent   TYPE ty_sapevent OPTIONAL
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS has_content
      RETURNING
        VALUE(result) TYPE abap_bool.

    CLASS-METHODS clear.

    CLASS-METHODS save_state
      RETURNING
        VALUE(result) TYPE REF TO data.

    CLASS-METHODS restore_state
      IMPORTING
        state TYPE REF TO data.

    CLASS-METHODS set_external_html
      IMPORTING
        html TYPE string.

    CLASS-METHODS clear_external_html.

    CLASS-METHODS escape_html
      IMPORTING
        text          TYPE string
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS get_control_id
      IMPORTING
        control       TYPE REF TO cl_gui_control
      RETURNING
        VALUE(result) TYPE string.
ENDCLASS.

CLASS zcl_gg_gui_runtime IMPLEMENTATION.
  METHOD initialize.
    cl_gui_control=>initialize(
      control = control
      parent  = parent
      kind    = kind ).
  ENDMETHOD.

  METHOD render_html.
    result = cl_gui_control=>render_html(
      iv_document        = iv_document
      iv_container_name  = iv_container_name
      is_sapevent        = is_sapevent
      iv_without_dialogs = iv_without_dialogs ).
  ENDMETHOD.

  METHOD render_dialogs_html.
    result = cl_gui_control=>render_dialogs_html( is_sapevent = is_sapevent ).
  ENDMETHOD.

  METHOD has_content.
    result = cl_gui_control=>has_content( ).
  ENDMETHOD.

  METHOD clear.
    cl_gui_control=>clear( ).
  ENDMETHOD.

  METHOD save_state.
    result = cl_gui_control=>save_state( ).
  ENDMETHOD.

  METHOD restore_state.
    cl_gui_control=>restore_state( state ).
  ENDMETHOD.

  METHOD set_external_html.
    cl_gui_control=>set_external_html( html ).
  ENDMETHOD.

  METHOD clear_external_html.
    cl_gui_control=>clear_external_html( ).
  ENDMETHOD.

  METHOD escape_html.
    result = cl_gui_control=>escape_html( text ).
  ENDMETHOD.

  METHOD get_control_id.
    result = control->control_id.
  ENDMETHOD.
ENDCLASS.
