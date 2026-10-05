CLASS ltcl_ex_96 DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS publishes_contract FOR TESTING.
    METHODS stacks_messages FOR TESTING.

ENDCLASS.

CLASS ltcl_ex_96 IMPLEMENTATION.

  METHOD publishes_contract.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    lo_metadata ?= NEW zcl_gg_ex_096( ).
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_transaction-tcode
      exp = 'ZGG_EX_096' ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_transaction-description ).
  ENDMETHOD.

  METHOD stacks_messages.
    DATA(ls_result) = zcl_gg_host=>run( io_report = NEW zcl_gg_ex_096( ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-messages )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-messages[ 1 ]-text
                                        exp = 'Saved successfully' ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-messages[ 2 ]-display_like
                                        exp = zif_gg_session_types_v1=>message_type_warning ).
  ENDMETHOD.

ENDCLASS.
