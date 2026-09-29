CLASS cl_salv_columns_list DEFINITION PUBLIC INHERITING FROM cl_salv_columns.
  PUBLIC SECTION.

    METHODS set_key_fixation
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS has_key_fixation
      RETURNING
        VALUE(value) TYPE abap_bool.

  PROTECTED SECTION.
    METHODS create_column REDEFINITION.

  PRIVATE SECTION.
    DATA mv_key_fixation TYPE abap_bool.

ENDCLASS.

CLASS cl_salv_columns_list IMPLEMENTATION.
  METHOD set_key_fixation.
    mv_key_fixation = value.
  ENDMETHOD.

  METHOD has_key_fixation.
    value = mv_key_fixation.
  ENDMETHOD.

  METHOD create_column.
    value = NEW cl_salv_column_list( columnname = columnname ).
  ENDMETHOD.

ENDCLASS.
