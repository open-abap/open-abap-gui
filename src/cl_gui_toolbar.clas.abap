CLASS cl_gui_toolbar DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.

    CONSTANTS m_id_function_selected TYPE i VALUE 1.

    METHODS constructor
      IMPORTING
        parent TYPE REF TO cl_gui_container.

    METHODS add_button
      IMPORTING
        fcode       TYPE clike
        icon        TYPE c
        is_disabled TYPE abap_bool OPTIONAL
        butn_type   TYPE i
        text        TYPE string OPTIONAL
        quickinfo   TYPE string OPTIONAL
        is_checked  TYPE c OPTIONAL
      EXCEPTIONS
        cntl_error
        cntb_btype_error
        cntb_error_fcode.

    METHODS assign_static_ctxmenu_table
      IMPORTING
        table_ctxmenu TYPE any.

    METHODS set_button_info
      IMPORTING
        fcode     TYPE ui_func
        icon      TYPE any OPTIONAL
        text      TYPE any OPTIONAL
        quickinfo TYPE any OPTIONAL.

    METHODS set_static_ctxmenu
      IMPORTING
        fcode   TYPE clike
        icon    TYPE clike OPTIONAL
        ctxmenu TYPE any OPTIONAL
        btntype TYPE i OPTIONAL.

    EVENTS function_selected
      EXPORTING
        VALUE(fcode) TYPE any.

    METHODS add_button_group
      IMPORTING
        data_table                TYPE ttb_button
        g_target_editor_maximized TYPE abap_bool OPTIONAL.
ENDCLASS.

CLASS cl_gui_toolbar IMPLEMENTATION.
  METHOD assign_static_ctxmenu_table.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_button_group.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_button_info.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD constructor.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD set_static_ctxmenu.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD free.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD add_button.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

ENDCLASS.