CLASS cl_salv_columns DEFINITION PUBLIC.
  PUBLIC SECTION.
    TYPES ty_column_names TYPE STANDARD TABLE OF lvc_fname WITH DEFAULT KEY.

    METHODS set_column_position
      IMPORTING
        columnname TYPE lvc_fname
        position   TYPE i OPTIONAL.

    METHODS get_column
      IMPORTING
        columnname   TYPE lvc_fname
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_column
      RAISING
        cx_salv_not_found.

    METHODS set_optimize
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS get
      RETURNING
        VALUE(value) TYPE salv_t_column_ref.

    METHODS add_column
      IMPORTING
        columnname TYPE lvc_fname.

    METHODS set_column_names
      IMPORTING
        columnnames TYPE ty_column_names.

  PROTECTED SECTION.
    TYPES: BEGIN OF ty_column_state,
             columnname TYPE lvc_fname,
             column     TYPE REF TO cl_salv_column,
           END OF ty_column_state.
    TYPES ty_column_states TYPE STANDARD TABLE OF ty_column_state WITH DEFAULT KEY.
    DATA mt_columns TYPE ty_column_states.
    DATA mv_optimize TYPE abap_bool.

ENDCLASS.

CLASS cl_salv_columns IMPLEMENTATION.
  METHOD get.
    LOOP AT mt_columns INTO DATA(ls_column).
      APPEND VALUE #( columnname = ls_column-columnname
                      r_column   = ls_column-column ) TO value.
    ENDLOOP.
  ENDMETHOD.

  METHOD set_optimize.
    mv_optimize = value.
  ENDMETHOD.

  METHOD get_column.
    READ TABLE mt_columns INTO DATA(ls_column)
      WITH KEY columnname = columnname.
    IF sy-subrc = 0.
      value = ls_column-column.
    ELSE.
      RAISE EXCEPTION TYPE cx_salv_not_found.
    ENDIF.
  ENDMETHOD.

  METHOD set_column_position.
    DATA lv_position TYPE i.
    DATA ls_column TYPE ty_column_state.
    READ TABLE mt_columns INTO ls_column WITH KEY columnname = columnname.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    DELETE mt_columns INDEX sy-tabix.
    lv_position = position.
    IF lv_position <= 0 OR lv_position > lines( mt_columns ) + 1.
      APPEND ls_column TO mt_columns.
    ELSE.
      INSERT ls_column INTO mt_columns INDEX lv_position.
    ENDIF.
  ENDMETHOD.

  METHOD add_column.
    IF line_exists( mt_columns[ columnname = columnname ] ).
      RETURN.
    ENDIF.
    DATA(lo_column) = NEW cl_salv_column( ).
    lo_column->set_columnname( columnname ).
    APPEND VALUE #( columnname = columnname
                    column     = lo_column ) TO mt_columns.
  ENDMETHOD.

  METHOD set_column_names.
    CLEAR mt_columns.
    LOOP AT columnnames INTO DATA(lv_columnname).
      add_column( lv_columnname ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
