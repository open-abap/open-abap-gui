CLASS cl_alv_changed_data_protocol DEFINITION PUBLIC.
  PUBLIC SECTION.
    DATA mp_mod_rows      TYPE REF TO data.
    DATA mt_deleted_rows  TYPE lvc_t_moce.
    DATA mt_fieldcatalog  TYPE lvc_t_fcat.
    DATA mt_good_cells    TYPE lvc_t_modi.
    DATA mt_inserted_rows TYPE lvc_t_moce.
    DATA mt_mod_cells     TYPE lvc_t_modi.
    DATA mt_protocol      TYPE lvc_t_msg1.
    DATA mt_roid_front    TYPE lvc_t_roid.

    METHODS constructor
      IMPORTING
        i_container   TYPE REF TO cl_gui_container OPTIONAL
        i_calling_alv TYPE REF TO cl_gui_alv_grid OPTIONAL.

    METHODS display_protocol
      IMPORTING
        i_container        TYPE REF TO cl_gui_container OPTIONAL
        i_display_toolbar  TYPE  abap_bool OPTIONAL
        i_optimize_columns TYPE abap_bool OPTIONAL
      PREFERRED PARAMETER i_container.

    METHODS refresh_protocol.

    METHODS modify_style
      IMPORTING
        i_row_id    TYPE int4
        i_fieldname TYPE lvc_fname
        i_style     TYPE xsequence.

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
        e_value     TYPE any.

    METHODS modify_cell
      IMPORTING
        i_row_id    TYPE int4 OPTIONAL
        i_tabix     TYPE int4 OPTIONAL
        i_fieldname TYPE lvc_fname OPTIONAL
        i_value     TYPE any.
ENDCLASS.

CLASS cl_alv_changed_data_protocol IMPLEMENTATION.
  METHOD refresh_protocol.
    RETURN.
  ENDMETHOD.

  METHOD constructor.
    IF i_calling_alv IS BOUND.
      i_calling_alv->get_frontend_fieldcatalog( IMPORTING et_fieldcatalog = mt_fieldcatalog ).
    ENDIF.
  ENDMETHOD.

  METHOD modify_style.
    READ TABLE mt_mod_cells ASSIGNING FIELD-SYMBOL(<cell>)
      WITH KEY row_id = i_row_id fieldname = i_fieldname.
    IF sy-subrc = 0.
      <cell>-style = i_style.
    ELSE.
      APPEND VALUE #( row_id    = i_row_id
                      fieldname = i_fieldname
                      style     = i_style ) TO mt_mod_cells.
    ENDIF.
  ENDMETHOD.

  METHOD modify_cell.
    APPEND VALUE #( row_id    = COND #( WHEN i_row_id IS INITIAL THEN i_tabix ELSE i_row_id )
                    tabix     = i_tabix
                    fieldname = i_fieldname
                    value     = i_value ) TO mt_mod_cells.
  ENDMETHOD.

  METHOD get_cell_value.
    READ TABLE mt_mod_cells INTO DATA(ls_cell)
      WITH KEY row_id = COND #( WHEN i_row_id IS INITIAL THEN i_tabix ELSE i_row_id )
               fieldname = i_fieldname.
    IF sy-subrc = 0.
      e_value = ls_cell-value.
    ELSE.
      CLEAR e_value.
    ENDIF.
  ENDMETHOD.

  METHOD add_protocol_entry.
    APPEND VALUE #( msgid     = i_msgid
                    msgno     = i_msgno
                    msgv1     = i_msgv1
                    msgv2     = i_msgv2
                    msgv3     = i_msgv3
                    msgv4     = i_msgv4
                    msgty     = i_msgty
                    fieldname = i_fieldname
                    row_id    = i_row_id ) TO mt_protocol.
  ENDMETHOD.

  METHOD display_protocol.
    RETURN.
  ENDMETHOD.

ENDCLASS.
