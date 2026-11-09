REPORT zgg_ex_207.

* Method-local TYPES in a local class, the same name in several methods
* and in the report.

TYPES: BEGIN OF ty_record,
         name TYPE c LENGTH 20,
         qty  TYPE i,
       END OF ty_record.

CLASS lcl_records DEFINITION.
  PUBLIC SECTION.
    METHODS export IMPORTING is_record TYPE ty_record.
    METHODS validate.
    METHODS summarize.
ENDCLASS.

CLASS lcl_records IMPLEMENTATION.
  METHOD export.
    DATA ls_record TYPE ty_record.
    ls_record = is_record.
    WRITE: / 'Export', ls_record-name, ls_record-qty.
  ENDMETHOD.

  METHOD validate.
    TYPES: BEGIN OF ty_record,
             status TYPE c LENGTH 1,
           END OF ty_record.
    DATA ls_record TYPE ty_record.
    ls_record-status = 'X'.
    WRITE: / 'Validate', ls_record-status.
  ENDMETHOD.

  METHOD summarize.
    TYPES: BEGIN OF ty_record,
             name TYPE c LENGTH 10,
             id   TYPE n LENGTH 4,
           END OF ty_record.
    DATA ls_record TYPE ty_record.
    ls_record-name = 'Total'.
    ls_record-id = 42.
    WRITE: / 'Summarize', ls_record-name, ls_record-id.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  DATA go_records TYPE REF TO lcl_records.
  DATA gs_record TYPE ty_record.
  go_records = NEW #( ).
  gs_record-name = 'Widget'.
  gs_record-qty = 5.
  go_records->export( gs_record ).
  go_records->validate( ).
  go_records->summarize( ).
