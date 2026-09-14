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

    METHODS move
      IMPORTING
        left TYPE i
        top  TYPE i.

    METHODS resize
      IMPORTING
        width  TYPE i
        height TYPE i.

    METHODS focus_dialog.

    METHODS close_dialog.

    EVENTS moved
      EXPORTING
        VALUE(left) TYPE i
        VALUE(top)  TYPE i.

    EVENTS resized
      EXPORTING
        VALUE(width)  TYPE i
        VALUE(height) TYPE i.

    EVENTS focused.

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

  METHOD move.
    set_position( left = left
                  top  = top ).
    RAISE EVENT moved
      EXPORTING
        left = left
        top  = top.
  ENDMETHOD.

  METHOD resize.
    set_position( width  = width
                  height = height ).
    RAISE EVENT resized
      EXPORTING
        width  = width
        height = height.
  ENDMETHOD.

  METHOD focus_dialog.
    cl_gui_control=>set_focus( me ).
    RAISE EVENT focused.
  ENDMETHOD.

  METHOD close_dialog.
    free( ).
    RAISE EVENT close EXPORTING sender = me.
  ENDMETHOD.

ENDCLASS.
