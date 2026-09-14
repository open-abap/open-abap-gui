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

    METHODS set_alt_text
      IMPORTING
        alt_text TYPE string.

    METHODS set_display_mode
      IMPORTING
        display_mode TYPE i.

    METHODS load_picture_from_url_async
      IMPORTING
        url TYPE string.

    METHODS load_picture_from_url
      IMPORTING
        url    TYPE string
      EXPORTING
        result TYPE i.

    METHODS set_3d_border
      IMPORTING
        border TYPE i.

  PRIVATE SECTION.
    DATA mv_url TYPE string.
    DATA mv_display_mode TYPE i.
    DATA mv_border TYPE i.
    DATA mv_state TYPE string.
    DATA mv_alt_text TYPE string.

    METHODS refresh_state.
    METHODS is_safe_asset
      RETURNING
        VALUE(result) TYPE abap_bool.
ENDCLASS.

CLASS cl_gui_picture IMPLEMENTATION.
  METHOD set_3d_border.
    mv_border = border.
    refresh_state( ).
  ENDMETHOD.

  METHOD set_alt_text.
    mv_alt_text = alt_text.
    refresh_state( ).
  ENDMETHOD.

  METHOD load_picture_from_url.
    mv_url = url.
    IF is_safe_asset( ) = abap_true.
      mv_state = 'loaded'.
      result = 0.
    ELSE.
      mv_state = 'rejected'.
      result = 4.
    ENDIF.
    refresh_state( ).
  ENDMETHOD.

  METHOD load_picture_from_url_async.
    mv_url = url.
    mv_state = COND #( WHEN is_safe_asset( ) = abap_true THEN 'loaded' ELSE 'rejected' ).
    refresh_state( ).
  ENDMETHOD.

  METHOD clear_picture.
    CLEAR: mv_url, mv_state.
    refresh_state( ).
  ENDMETHOD.

  METHOD constructor.
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'PICTURE' ).
    parent->add_child( me ).
  ENDMETHOD.

  METHOD set_display_mode.
    mv_display_mode = COND #( WHEN display_mode >= display_mode_normal
                                AND display_mode <= display_mode_fit_center
                              THEN display_mode ELSE display_mode_normal ).
    refresh_state( ).
  ENDMETHOD.

  METHOD refresh_state.
    cl_gui_control=>set_payload( control = me
                                 payload = mv_url ).
    cl_gui_control=>set_picture_state(
      control      = me
      display_mode = mv_display_mode
      border       = mv_border
      state        = mv_state
      alt_text     = mv_alt_text ).
  ENDMETHOD.

  METHOD is_safe_asset.
    DATA(lv_url) = to_lower( mv_url ).
    result = xsdbool( lv_url CP '/assets/*' ).
  ENDMETHOD.

ENDCLASS.
