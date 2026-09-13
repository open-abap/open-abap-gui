CLASS cl_gui_easy_splitter_container DEFINITION PUBLIC INHERITING FROM cl_gui_container.
  PUBLIC SECTION.

    CONSTANTS orientation_vertical TYPE i VALUE 0.
    CONSTANTS orientation_horizontal TYPE i VALUE 1.

    DATA top_left_container TYPE REF TO cl_gui_container READ-ONLY.
    DATA bottom_right_container TYPE REF TO cl_gui_container READ-ONLY.

    METHODS constructor
      IMPORTING
        parent        TYPE REF TO cl_gui_container OPTIONAL
        orientation   TYPE i DEFAULT orientation_vertical
        sash_position TYPE i DEFAULT 50
        with_border   TYPE i DEFAULT 1
        link_dynnr    TYPE sy-dynnr OPTIONAL
        link_repid    TYPE sy-repid OPTIONAL
        metric        TYPE i OPTIONAL
        name          TYPE string OPTIONAL
      EXCEPTIONS
        cntl_error
        cntl_system_error.

ENDCLASS.

CLASS cl_gui_easy_splitter_container IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'EASY_SPLITTER' ).
    IF parent IS BOUND.
      parent->add_child( me ).
    ENDIF.
    top_left_container = NEW cl_gui_custom_container(
      container_name = |EASY-{ control_id }-TOP-LEFT|
      parent         = me ).
    bottom_right_container = NEW cl_gui_custom_container(
      container_name = |EASY-{ control_id }-BOTTOM-RIGHT|
      parent         = me ).
    cl_gui_control=>set_payload(
      control = me
      payload = |orientation={ orientation }; sash={ sash_position }; border={ with_border }| ).
  ENDMETHOD.

ENDCLASS.
