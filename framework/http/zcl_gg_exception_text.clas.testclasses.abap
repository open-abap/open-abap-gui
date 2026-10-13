CLASS ltcl_gg_exception_text DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS names_class_and_attributes FOR TESTING.
    METHODS uses_the_exception_text FOR TESTING.
    METHODS follows_previous FOR TESTING.
    METHODS falls_back_without_exception FOR TESTING.
    METHODS details_one_per_line FOR TESTING.
    METHODS details_follow_previous FOR TESTING.
    METHODS details_show_raise_position FOR TESTING.

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

  METHOD details_one_per_line.
    DATA(lx_error) = NEW cx_sy_dyn_call_illegal_func( function = 'RPY_TRANSACTION_READ' ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_exception_text=>details( lx_error )
      exp = |Unhandled exception CX_SY_DYN_CALL_ILLEGAL_FUNC\n|
         && |FUNCTION = RPY_TRANSACTION_READ| ).
  ENDMETHOD.

  METHOD details_follow_previous.
    DATA(lx_inner) = NEW cx_sy_move_cast_error( ).
    DATA(lx_outer) = NEW cx_sy_dyn_call_illegal_func(
      function = 'Z_CALLER'
      previous = lx_inner ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_exception_text=>details( lx_outer )
      exp = |Unhandled exception CX_SY_DYN_CALL_ILLEGAL_FUNC\n|
         && |FUNCTION = Z_CALLER\n|
         && |\n|
         && |Caused by CX_SY_MOVE_CAST_ERROR\n|
         && |Casting failed, types not compatible| ).
  ENDMETHOD.

  METHOD details_show_raise_position.
* An exception a RAISE EXCEPTION statement raised knows where; one only
* created, like those above, does not, and shows no position.
    DATA lv_program TYPE syrepid.
    DATA lv_line TYPE i.

    TRY.
        RAISE EXCEPTION TYPE zcx_gg_transaction_error
          EXPORTING
            iv_message = `Raised here`.
      CATCH zcx_gg_transaction_error INTO DATA(lx_error).
    ENDTRY.
    lx_error->get_source_position(
      IMPORTING
        program_name = lv_program
        source_line  = lv_line ).
    DATA(lv_details) = zcl_gg_exception_text=>details( lx_error ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_details CP |Unhandled exception ZCX_GG_TRANSACTION_ERROR\nRaised at { lv_program }*, line { lv_line }\n*| ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_line > 1 ) ).
  ENDMETHOD.

  METHOD falls_back_without_exception.
    DATA lx_none TYPE REF TO cx_root.

    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_exception_text=>describe( lx_none )
      exp = `Unknown error (no message available)` ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_exception_text=>details( lx_none )
      exp = `Unknown error (no message available)` ).
  ENDMETHOD.

ENDCLASS.
