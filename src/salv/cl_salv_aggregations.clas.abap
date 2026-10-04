CLASS cl_salv_aggregations DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS add_aggregation
      IMPORTING
        columnname  TYPE any
        aggregation TYPE i DEFAULT if_salv_c_aggregation=>total.

    METHODS is_aggregated
      IMPORTING
        columnname   TYPE any
      RETURNING
        VALUE(value) TYPE abap_bool.

  PRIVATE SECTION.
    DATA mt_columns TYPE STANDARD TABLE OF lvc_fname WITH DEFAULT KEY.
ENDCLASS.

CLASS cl_salv_aggregations IMPLEMENTATION.
  METHOD add_aggregation.
    DATA lv_columnname TYPE lvc_fname.

    lv_columnname = to_upper( columnname ).
    IF NOT line_exists( mt_columns[ table_line = lv_columnname ] ).
      APPEND lv_columnname TO mt_columns.
    ENDIF.
  ENDMETHOD.

  METHOD is_aggregated.
    DATA lv_columnname TYPE lvc_fname.

    lv_columnname = to_upper( columnname ).
    value = xsdbool( line_exists( mt_columns[ table_line = lv_columnname ] ) ).
  ENDMETHOD.
ENDCLASS.
