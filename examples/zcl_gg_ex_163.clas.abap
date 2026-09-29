CLASS zcl_gg_ex_163 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 163, a SALV table whose program downcasts a column to
* cl_salv_column_table to mark it as an icon column. Counterpart of
* zgg_ex_163.prog.abap. get_column returns REF TO cl_salv_column, and on a
* real system the object behind it is a cl_salv_column_table, so the ?= cast
* succeeds. Self contained: no superclass, every callback present.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_v1.
    INTERFACES zif_gg_transaction_v1.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_status,
             traffic_light TYPE c LENGTH 4,
             event         TYPE c LENGTH 30,
             object        TYPE c LENGTH 20,
           END OF ty_status.
    TYPES ty_statuses TYPE STANDARD TABLE OF ty_status WITH DEFAULT KEY.

    DATA mt_statuses TYPE ty_statuses.
ENDCLASS.

CLASS zcl_gg_ex_163 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_163' description = 'SALV column cast to column table' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = '0100'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    io_builder->begin_screen( VALUE #( number = '0100' title = 'Event status' ) ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_flow_logic.
    io_builder->begin_screen( '0100' ).
    io_builder->begin_pbo( ).
    io_builder->add_module( VALUE #( name = 'STATUS_0100' ) ).
    io_builder->end_processing( ).
    io_builder->begin_pai( ).
    io_builder->add_module( VALUE #( name = 'USER_COMMAND_0100' ) ).
    io_builder->end_processing( ).
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~initialization.
    mt_statuses = VALUE #(
      ( traffic_light = '@08@' event = 'CREATED' object = 'BUS2032' )
      ( traffic_light = '@0A@' event = 'CHANGED' object = 'BUS2105' ) ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    DATA lo_salv TYPE REF TO cl_salv_table.
    DATA lo_column TYPE REF TO cl_salv_column_table.

    IF is_context-module <> 'STATUS_0100'.
      RETURN.
    ENDIF.
    io_session->get_dialog( )->set_title( 'Event status' ).

    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = lo_salv
          CHANGING
            t_table      = mt_statuses ).
        lo_column ?= lo_salv->get_columns( )->get_column( 'TRAFFIC_LIGHT' ).
        lo_column->set_icon( abap_true ).
        lo_column->set_short_text( 'Status' ).
      CATCH cx_salv_msg cx_salv_not_found.
        RETURN.
    ENDTRY.
    lo_salv->set_list_header( 'Event status' ).
    lo_salv->display( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_value_request.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_help_request.
    RETURN.
  ENDMETHOD.

ENDCLASS.
