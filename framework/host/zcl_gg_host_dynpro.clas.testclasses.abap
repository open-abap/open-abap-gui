* A dialog program whose screens declare different OK-code fields: 0100 uses
* MY_OK, 0200 uses OTHER_OK and 0300 declares none. Each PAI copies the field
* its screen declares into SEEN, so a test sees what PAI received.
CLASS lcl_ok_code_program DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_v1.
ENDCLASS.

CLASS lcl_ok_code_program IMPLEMENTATION.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = '0100'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    io_builder->begin_screen( VALUE #( number = '0100' next_screen = '0100' ok_code = 'MY_OK' ) ).
    io_builder->end_screen( ).
    io_builder->begin_screen( VALUE #( number = '0200' next_screen = '0200' ok_code = 'OTHER_OK' ) ).
    io_builder->end_screen( ).
    io_builder->begin_screen( VALUE #( number = '0300' next_screen = '0300' ) ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_flow_logic.
    DATA lt_screens TYPE STANDARD TABLE OF zif_gg_dynpro_types_v1=>ty_screen_number WITH DEFAULT KEY.

    lt_screens = VALUE #( ( '0100' ) ( '0200' ) ( '0300' ) ).
    LOOP AT lt_screens INTO DATA(lv_screen).
      io_builder->begin_screen( lv_screen ).
      io_builder->begin_pbo( ).
      io_builder->add_module( VALUE #( name = 'STATUS' ) ).
      io_builder->end_processing( ).
      io_builder->begin_pai( ).
      io_builder->add_module( VALUE #( name = 'USER_COMMAND' ) ).
      io_builder->end_processing( ).
      io_builder->end_screen( ).
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~initialization.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    io_session->get_dialog( )->set_status( VALUE #(
      status       = 'MAIN'
      active_ucomm = VALUE #( ( 'BACK' ) ( 'EXIT' ) ( 'CANC' ) ( 'CFW' ) ) ) ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    DATA lv_field TYPE zif_gg_dynpro_types_v1=>ty_name.
    DATA lv_seen TYPE string.

    lv_field = SWITCH #( is_context-screen
      WHEN '0100' THEN 'MY_OK'
      WHEN '0200' THEN 'OTHER_OK'
      ELSE 'GV_OK_CODE' ).
    READ TABLE ct_values INTO DATA(ls_value) WITH KEY container = `` name = lv_field row = 0.
    IF sy-subrc = 0.
      lv_seen = ls_value-value.
    ENDIF.
    INSERT VALUE #( name = 'SEEN' value = lv_seen ) INTO TABLE ct_values.
    IF lv_seen = 'CFW'.
      cl_gui_cfw=>set_new_ok_code( 'FROM_CFW' ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_value_request.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_help_request.
    RETURN.
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_gg_host_dynpro DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

* The host fills the OK-code field the current screen declares with the
* submitted function code before PAI; a screen without one gets GV_OK_CODE.

  PRIVATE SECTION.
    METHODS delivers_exit_commands FOR TESTING.
    METHODS uses_the_screens_own_field FOR TESTING.
    METHODS falls_back_to_gv_ok_code FOR TESTING.
    METHODS writes_cfw_code_to_field FOR TESTING.

    METHODS run
      IMPORTING
        iv_screen        TYPE zif_gg_dynpro_types_v1=>ty_screen_number
        iv_ucomm         TYPE zif_gg_dynpro_types_v1=>ty_ucomm
      RETURNING
        VALUE(rs_result) TYPE zcl_gg_host_dynpro=>ty_result.

    METHODS value
      IMPORTING
        is_result       TYPE zcl_gg_host_dynpro=>ty_result
        iv_name         TYPE zif_gg_dynpro_types_v1=>ty_name
      RETURNING
        VALUE(rv_value) TYPE string.

ENDCLASS.

CLASS ltcl_gg_host_dynpro IMPLEMENTATION.

  METHOD run.
    rs_result = zcl_gg_host_dynpro=>run(
      io_program = NEW lcl_ok_code_program( )
      iv_screen  = iv_screen
      iv_ucomm   = iv_ucomm ).
  ENDMETHOD.

  METHOD value.
    READ TABLE is_result-values INTO DATA(ls_value) WITH KEY container = `` name = iv_name row = 0.
    IF sy-subrc = 0.
      rv_value = ls_value-value.
    ENDIF.
  ENDMETHOD.

  METHOD delivers_exit_commands.
    DATA lt_ucomms TYPE STANDARD TABLE OF zif_gg_dynpro_types_v1=>ty_ucomm WITH DEFAULT KEY.

    lt_ucomms = VALUE #( ( 'BACK' ) ( 'EXIT' ) ( 'CANC' ) ).
    LOOP AT lt_ucomms INTO DATA(lv_ucomm).
      DATA(ls_result) = run( iv_screen = '0100'
                             iv_ucomm  = lv_ucomm ).
      cl_abap_unit_assert=>assert_equals(
        act = value( is_result = ls_result
                     iv_name   = 'SEEN' )
        exp = CONV string( lv_ucomm )
        msg = |PAI on 0100 did not receive { lv_ucomm } in MY_OK| ).
      cl_abap_unit_assert=>assert_false(
        act = xsdbool( line_exists( ls_result-values[ name = 'GV_OK_CODE' ] ) )
        msg = |{ lv_ucomm } was also written to GV_OK_CODE| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD uses_the_screens_own_field.
    DATA(ls_result) = run( iv_screen = '0200'
                           iv_ucomm  = 'BACK' ).

    cl_abap_unit_assert=>assert_equals(
      act = value( is_result = ls_result
                   iv_name   = 'SEEN' )
      exp = `BACK` ).
    cl_abap_unit_assert=>assert_equals(
      act = value( is_result = ls_result
                   iv_name   = 'OTHER_OK' )
      exp = `BACK` ).
    cl_abap_unit_assert=>assert_false(
      act = xsdbool( line_exists( ls_result-values[ name = 'MY_OK' ] ) )
      msg = 'Screen 0200 wrote the OK-code field of screen 0100' ).
  ENDMETHOD.

  METHOD falls_back_to_gv_ok_code.
    DATA(ls_result) = run( iv_screen = '0300'
                           iv_ucomm  = 'CANC' ).

    cl_abap_unit_assert=>assert_equals(
      act = value( is_result = ls_result
                   iv_name   = 'SEEN' )
      exp = `CANC` ).
  ENDMETHOD.

  METHOD writes_cfw_code_to_field.
    DATA(ls_result) = run( iv_screen = '0100'
                           iv_ucomm  = 'CFW' ).

    cl_abap_unit_assert=>assert_equals(
      act = value( is_result = ls_result
                   iv_name   = 'MY_OK' )
      exp = `FROM_CFW` ).
  ENDMETHOD.

ENDCLASS.
