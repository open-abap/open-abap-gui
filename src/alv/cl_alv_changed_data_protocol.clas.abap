CLASS cl_alv_changed_data_protocol DEFINITION PUBLIC.
  PUBLIC SECTION.
    DATA mt_mod_cells TYPE lvc_t_modi.
    DATA mt_deleted_rows TYPE lvc_t_moce.
    DATA mt_inserted_rows TYPE lvc_t_moce.
    DATA mt_good_cells TYPE lvc_t_modi.

    METHODS display_protocol
      IMPORTING
        i_container        TYPE REF TO cl_gui_container OPTIONAL
        i_display_toolbar  TYPE  abap_bool OPTIONAL
        i_optimize_columns TYPE abap_bool OPTIONAL
      PREFERRED PARAMETER i_container.

    METHODS add_protocol_entry
      IMPORTING
        i_msgid     TYPE symsgid
        i_msgty     TYPE symsgty
        i_msgno     TYPE symsgno
        i_msgv1     TYPE any OPTIONAL
        i_msgv2     TYPE any OPTIONAL
        i_msgv3     TYPE any OPTIONAL
        i_msgv4     TYPE any OPTIONAL
        i_fieldname TYPE any
        i_row_id    TYPE int4 OPTIONAL
        i_tabix     TYPE int4 OPTIONAL.

    METHODS get_cell_value
      IMPORTING
        i_row_id    TYPE int4 OPTIONAL
        i_tabix     TYPE int4 OPTIONAL
        i_fieldname TYPE lvc_fname
      EXPORTING
        !e_value    TYPE any.

    METHODS modify_cell
      IMPORTING
        i_row_id    TYPE int4 OPTIONAL
        i_tabix     TYPE int4 OPTIONAL
        i_fieldname TYPE lvc_fname OPTIONAL
        i_value     TYPE any.
ENDCLASS.

CLASS cl_alv_changed_data_protocol IMPLEMENTATION.

  METHOD modify_cell.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD get_cell_value.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD add_protocol_entry.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

  METHOD display_protocol.
    ASSERT 1 = 'todo'.
  ENDMETHOD.

ENDCLASS.