CLASS ltcl_gg_exception_text DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS names_class_and_attributes FOR TESTING.
    METHODS uses_the_exception_text FOR TESTING.
    METHODS follows_previous FOR TESTING.
    METHODS falls_back_without_exception FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_exception_text IMPLEMENTATION.

  METHOD names_class_and_attributes.
* A missing function module: no text of its own, only the FUNCTION it names.
    DATA(lx_error) = NEW cx_sy_dyn_call_illegal_func( function = 'RPY_TRANSACTION_READ' ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_exception_text=>describe( lx_error )
      exp = `CX_SY_DYN_CALL_ILLEGAL_FUNC (FUNCTION = RPY_TRANSACTION_READ)` ).
  ENDMETHOD.

  METHOD uses_the_exception_text.
    DATA(lx_error) = NEW zcx_gg_transaction_error( iv_message = `Transaction ZX has an unsupported executable kind` ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_exception_text=>describe( lx_error )
      exp = `ZCX_GG_TRANSACTION_ERROR (MV_MESSAGE = Transaction ZX has an unsupported executable kind)` ).
  ENDMETHOD.

  METHOD follows_previous.
    DATA(lx_inner) = NEW cx_sy_dyn_call_illegal_func( function = 'RPY_TRANSACTION_READ' ).
    DATA(lx_outer) = NEW cx_sy_dyn_call_illegal_func(
      function = 'Z_CALLER'
      previous = lx_inner ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_exception_text=>describe( lx_outer )
      exp = |CX_SY_DYN_CALL_ILLEGAL_FUNC (FUNCTION = Z_CALLER)\n|
         && |Caused by: CX_SY_DYN_CALL_ILLEGAL_FUNC (FUNCTION = RPY_TRANSACTION_READ)| ).
  ENDMETHOD.

  METHOD falls_back_without_exception.
    DATA lx_none TYPE REF TO cx_root.

    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_exception_text=>describe( lx_none )
      exp = `Unknown error (no message available)` ).
  ENDMETHOD.

ENDCLASS.
