CLASS lcx_locked DEFINITION FINAL INHERITING FROM cx_static_check.
  PUBLIC SECTION.
    METHODS get_text REDEFINITION.
ENDCLASS.

CLASS lcx_locked IMPLEMENTATION.
  METHOD get_text.
    result = `Order is locked`.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_gg_host_session DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

* MESSAGE takes either an object or a text as its operand, and the session
* has to tell them apart at runtime.

  PRIVATE SECTION.
    METHODS text_from_message_operand FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_host_session IMPLEMENTATION.

  METHOD text_from_message_operand.
    DATA lo_list TYPE REF TO zcl_gg_host_list.
    DATA lo_session TYPE REF TO zcl_gg_host_session.
    DATA lx_locked TYPE REF TO cx_root.
    DATA lo_unbound TYPE REF TO cx_root.
    DATA lv_text TYPE c LENGTH 10 VALUE 'plain text'.

    lo_list = NEW zcl_gg_host_list( ).
    lo_session = NEW zcl_gg_host_session( io_list = lo_list ).
    lx_locked = NEW lcx_locked( ).

    lo_session->zif_gg_session_v1~message(
      is_message = VALUE #( type = zif_gg_session_types_v1=>message_type_info )
      ia_text    = lx_locked ).
    lo_session->zif_gg_session_v1~message(
      is_message = VALUE #( type = zif_gg_session_types_v1=>message_type_info )
      ia_text    = lv_text ).
    lo_session->zif_gg_session_v1~message(
      is_message = VALUE #( type = zif_gg_session_types_v1=>message_type_info )
      ia_text    = lo_list ).
    lo_session->zif_gg_session_v1~message(
      is_message = VALUE #( type = zif_gg_session_types_v1=>message_type_info text = `replaced` )
      ia_text    = lo_unbound ).

    DATA(lt_messages) = lo_session->get_messages( ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_messages )
      exp = 4 ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_messages[ 1 ]-text
      exp = `Order is locked` ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_messages[ 2 ]-text
      exp = `plain text` ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_messages[ 3 ]-text
      exp = `ZCL_GG_HOST_LIST` ).
    cl_abap_unit_assert=>assert_initial( act = lt_messages[ 4 ]-text ).
  ENDMETHOD.

ENDCLASS.
