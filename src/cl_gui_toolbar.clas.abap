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

    METHODS set_static_ctxmenu
      IMPORTING
        fcode   TYPE clike
        icon    TYPE clike OPTIONAL
        ctxmenu TYPE any OPTIONAL
        btntype TYPE i OPTIONAL.

    EVENTS function_selected
      EXPORTING
        VALUE(fcode) TYPE any.
ENDCLASS.

CLASS cl_gui_toolbar IMPLEMENTATION.
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