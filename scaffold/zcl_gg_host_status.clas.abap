CLASS zcl_gg_host_status DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Validation shared by list and dialog status setters. Icon metadata remains
* runtime application state; this class only rejects ambiguous snapshots before
* they reach a page renderer.

  PUBLIC SECTION.
    CLASS-METHODS validate
      IMPORTING
        is_status       TYPE zif_gg_session_types_v1=>ty_gui_status
      RETURNING
        VALUE(rv_error) TYPE string.
ENDCLASS.

CLASS zcl_gg_host_status IMPLEMENTATION.

  METHOD validate.
    DATA lt_ucomms TYPE zif_gg_session_types_v1=>ty_ucomms.

    LOOP AT is_status-icon_bar INTO DATA(ls_icon).
      IF ls_icon-ucomm IS INITIAL.
        rv_error = 'Application icon-bar entries require a function code'.
        RETURN.
      ENDIF.
      IF ls_icon-label IS INITIAL.
        rv_error = |Application icon { ls_icon-ucomm } requires a label|.
        RETURN.
      ENDIF.
      IF ls_icon-icon IS INITIAL.
        rv_error = |Application icon { ls_icon-ucomm } requires an icon name|.
        RETURN.
      ENDIF.
      IF line_exists( lt_ucomms[ table_line = ls_icon-ucomm ] ).
        rv_error = |Duplicate application icon command { ls_icon-ucomm }|.
        RETURN.
      ENDIF.
      APPEND ls_icon-ucomm TO lt_ucomms.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
