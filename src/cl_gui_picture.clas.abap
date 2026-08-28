CLASS cl_gui_picture DEFINITION INHERITING FROM cl_gui_control PUBLIC.
  PUBLIC SECTION.
    CONSTANTS display_mode_normal TYPE i VALUE 0.
    CONSTANTS display_mode_fit TYPE i VALUE 2.
    CONSTANTS display_mode_stretch TYPE i VALUE 1.
    CONSTANTS display_mode_normal_center TYPE i VALUE 3.
    CONSTANTS display_mode_fit_center TYPE i VALUE 4.

    CONSTANTS eventid_context_menu TYPE i VALUE 1.
    CONSTANTS eventid_picture_click TYPE i VALUE 2.
    CONSTANTS eventid_picture_dblclick TYPE i VALUE 3.
    CONSTANTS eventid_control_click TYPE i VALUE 4.
    CONSTANTS eventid_control_dblclick TYPE i VALUE 5.
    CONSTANTS eventid_context_menu_selected TYPE i VALUE 6.

    EVENTS picture_click
      EXPORTING
        VALUE(mouse_pos_x) TYPE i
        VALUE(mouse_pos_y) TYPE i.

    EVENTS picture_dblclick
      EXPORTING
        VALUE(mouse_pos_x) TYPE i
        VALUE(mouse_pos_y) TYPE i.

    METHODS constructor
      IMPORTING
        parent TYPE REF TO cl_gui_container.

    METHODS clear_picture.

    METHODS set_display_mode
      IMPORTING
        display_mode TYPE i.

    METHODS load_picture_from_url_async
      IMPORTING
        url TYPE c.

    METHODS load_picture_from_url
      IMPORTING
        url    TYPE c
      EXPORTING
        result TYPE i.

    METHODS set_3d_border
      IMPORTING
        border TYPE i.
ENDCLASS.

CLASS cl_gui_picture IMPLEMENTATION.
  METHOD set_3d_border.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD load_picture_from_url.
    cl_gui_control=>set_payload( control = me payload = CONV string( url ) ).
    result = 0.
  ENDMETHOD.

  METHOD load_picture_from_url_async.
    cl_gui_control=>set_payload( control = me payload = CONV string( url ) ).
  ENDMETHOD.

  METHOD clear_picture.
    cl_gui_control=>set_payload( control = me payload = `` ).
  ENDMETHOD.

  METHOD constructor.
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'PICTURE' ).
    parent->add_child( me ).
  ENDMETHOD.

  METHOD set_display_mode.
    RETURN.
  ENDMETHOD.

ENDCLASS.
