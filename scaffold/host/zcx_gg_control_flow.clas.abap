CLASS zcx_gg_control_flow DEFINITION PUBLIC INHERITING FROM cx_no_check FINAL CREATE PUBLIC.

* Non-local control transfer. The session operations that do not return to the
* calling application callback raise this, and the host catches it at the
* callback boundary. Deriving from cx_no_check keeps the scaffold interfaces
* free of RAISING clauses, which the ABAP statements they model do not have
* either.

  PUBLIC SECTION.
    TYPES ty_kind TYPE string.

    CONSTANTS kind_stop          TYPE ty_kind VALUE 'STOP'.
    CONSTANTS kind_message       TYPE ty_kind VALUE 'MESSAGE'.
    CONSTANTS kind_leave_program TYPE ty_kind VALUE 'LEAVE_PROGRAM'.
    CONSTANTS kind_unsupported   TYPE ty_kind VALUE 'UNSUPPORTED'.

    DATA mv_kind      TYPE ty_kind READ-ONLY.
    DATA mv_operation TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING
        iv_kind      TYPE ty_kind
        iv_operation TYPE string OPTIONAL.

ENDCLASS.

CLASS zcx_gg_control_flow IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    mv_kind      = iv_kind.
    mv_operation = iv_operation.
  ENDMETHOD.

ENDCLASS.
