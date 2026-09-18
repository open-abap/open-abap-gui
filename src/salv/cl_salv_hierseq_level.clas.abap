CLASS cl_salv_hierseq_level DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        binding TYPE salv_t_hierseq_binding OPTIONAL.

    METHODS set_data
      IMPORTING
        value     TYPE REF TO data
        t_binding TYPE salv_t_hierseq_binding.

    METHODS get_columns
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_columns_hierseq.

    METHODS get_selections
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_selections.

    METHODS get_sorts
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_sorts.

    METHODS get_filters
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_filters.

    METHODS get_aggregations
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_aggregations.

    METHODS get_binding
      RETURNING
        VALUE(value) TYPE salv_t_hierseq_binding.

    METHODS set_items_expanded
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS is_items_expanded
      RETURNING
        VALUE(value) TYPE abap_bool.

  PRIVATE SECTION.
    DATA mo_columns TYPE REF TO cl_salv_columns_hierseq.
    DATA mo_selections TYPE REF TO cl_salv_selections.
    DATA mo_sorts TYPE REF TO cl_salv_sorts.
    DATA mo_filters TYPE REF TO cl_salv_filters.
    DATA mo_aggregations TYPE REF TO cl_salv_aggregations.
    DATA mt_binding TYPE salv_t_hierseq_binding.
    DATA mv_items_expanded TYPE abap_bool.
    DATA mr_table TYPE REF TO data.

ENDCLASS.

CLASS cl_salv_hierseq_level IMPLEMENTATION.

  METHOD constructor.
    mt_binding = binding.
    mv_items_expanded = abap_true.
  ENDMETHOD.

  METHOD get_columns.
    IF mo_columns IS NOT BOUND.
      mo_columns = NEW cl_salv_columns_hierseq( ).
    ENDIF.
    value = mo_columns.
  ENDMETHOD.

  METHOD set_data.
    DATA lo_table_descr TYPE REF TO cl_abap_tabledescr.
    DATA lo_line_descr TYPE REF TO cl_abap_datadescr.
    DATA lo_struct_descr TYPE REF TO cl_abap_structdescr.

    mt_binding = t_binding.
    mr_table = value.
    mo_columns = NEW cl_salv_columns_hierseq( ).
    IF mr_table IS NOT BOUND.
      RETURN.
    ENDIF.
    TRY.
        lo_table_descr ?= cl_abap_tabledescr=>describe_by_data( mr_table->* ).
        lo_line_descr = lo_table_descr->get_table_line_type( ).
        IF lo_line_descr->kind = cl_abap_typedescr=>kind_struct.
          lo_struct_descr ?= lo_line_descr.
          LOOP AT lo_struct_descr->get_components( ) INTO DATA(ls_component).
            mo_columns->add_column( CONV lvc_fname( ls_component-name ) ).
          ENDLOOP.
        ELSE.
          mo_columns->add_column( 'VALUE' ).
        ENDIF.
      CATCH cx_root.
        CLEAR mo_columns.
    ENDTRY.
  ENDMETHOD.

  METHOD get_selections.
    IF mo_selections IS NOT BOUND.
      mo_selections = NEW cl_salv_selections( ).
    ENDIF.
    value = mo_selections.
  ENDMETHOD.

  METHOD get_sorts.
    IF mo_sorts IS NOT BOUND.
      mo_sorts = NEW cl_salv_sorts( ).
    ENDIF.
    value = mo_sorts.
  ENDMETHOD.

  METHOD get_filters.
    IF mo_filters IS NOT BOUND.
      mo_filters = NEW cl_salv_filters( ).
    ENDIF.
    value = mo_filters.
  ENDMETHOD.

  METHOD get_aggregations.
    IF mo_aggregations IS NOT BOUND.
      mo_aggregations = NEW cl_salv_aggregations( ).
    ENDIF.
    value = mo_aggregations.
  ENDMETHOD.

  METHOD get_binding.
    value = mt_binding.
  ENDMETHOD.

  METHOD set_items_expanded.
    mv_items_expanded = value.
  ENDMETHOD.

  METHOD is_items_expanded.
    value = mv_items_expanded.
  ENDMETHOD.

ENDCLASS.
