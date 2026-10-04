CLASS cl_gui_dialogbox_container DEFINITION PUBLIC INHERITING FROM cl_gui_container.
  PUBLIC SECTION.

    EVENTS close
      EXPORTING
        VALUE(sender) TYPE REF TO cl_gui_dialogbox_container.

    METHODS constructor
      IMPORTING
        parent                  TYPE REF TO cl_gui_container OPTIONAL
        width                   TYPE i DEFAULT 30
        height                  TYPE i DEFAULT 30
        top                     TYPE i DEFAULT 0
        left                    TYPE i DEFAULT 0
        caption                 TYPE clike OPTIONAL
        style                   TYPE i OPTIONAL
        repid                   TYPE sy-repid OPTIONAL
        dynnr                   TYPE sy-dynnr OPTIONAL
        lifetime                TYPE i OPTIONAL
        metric                  TYPE i DEFAULT 0
        name                    TYPE string OPTIONAL
        no_autodef_progid_dynnr TYPE clike OPTIONAL
      EXCEPTIONS
        cntl_error
        cntl_system_error
        create_error
        lifetime_error
        event_already_registered
        error_regist_event.

    METHODS set_caption
      IMPORTING
        caption TYPE clike
      EXCEPTIONS
        cntl_error
        cntl_system_error.

  PROTECTED SECTION.
* The close button of the window raises CLOSE, a system event: PAI does not
* run for it.
    METHODS dispatch_frontend_event REDEFINITION.
    METHODS is_application_event REDEFINITION.

ENDCLASS.

CLASS cl_gui_dialogbox_container IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'DIALOGBOX_CONTAINER' ).
    cl_gui_control=>set_payload( control = me
                                 payload = CONV string( caption ) ).
    set_position( height = height
                  width  = width
                  left   = left
                  top    = top ).
    IF parent IS BOUND.
      parent->add_child( me ).
    ENDIF.
  ENDMETHOD.

  METHOD set_caption.
    cl_gui_control=>set_payload( control = me
                                 payload = CONV string( caption ) ).
  ENDMETHOD.

  METHOD dispatch_frontend_event.
    IF event = 'CLOSE'.
      RAISE EVENT close EXPORTING sender = me.
    ENDIF.
  ENDMETHOD.

  METHOD is_application_event.
    result = abap_false.
  ENDMETHOD.

ENDCLASS.
