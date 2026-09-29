CLASS zcl_gg_ex_162 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Feature 162, an ALV grid created in a PBO module on
* cl_gui_container=>default_screen. Counterpart of zgg_ex_162.prog.abap. The
* screen has no custom control area: the grid fills the dynpro itself, so it
* renders at the top level of the screen instead of inside a named container.
* Self contained: no superclass, every callback present.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_v1.
    INTERFACES zif_gg_transaction_v1.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_event,
             event     TYPE c LENGTH 30,
             object    TYPE c LENGTH 20,
             paused_by TYPE c LENGTH 12,
           END OF ty_event.
    TYPES ty_events TYPE STANDARD TABLE OF ty_event WITH DEFAULT KEY.

    DATA mt_events TYPE ty_events.
    DATA mo_grid TYPE REF TO cl_gui_alv_grid.

    METHODS grid_is_alive
      RETURNING
        VALUE(rv_alive) TYPE abap_bool.
ENDCLASS.

CLASS zcl_gg_ex_162 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'ZGG_EX_162' description = 'ALV grid on the default screen' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = '0100'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    io_builder->begin_screen( VALUE #( number = '0100' title = 'Paused events' ) ).
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
    mt_events = VALUE #(
      ( event = 'CREATED' object = 'BUS2032' paused_by = 'DEVELOPER' )
      ( event = 'CHANGED' object = 'BUS2105' paused_by = 'BASIS' ) ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    DATA lt_fcat TYPE lvc_t_fcat.

    IF is_context-module <> 'STATUS_0100'.
      RETURN.
    ENDIF.
    io_session->get_dialog( )->set_title( 'Paused events' ).
    io_session->get_dialog( )->set_status( VALUE #(
      status       = 'STATUS162'
      active_ucomm = VALUE #( ( 'REFRESH' ) )
      icon_bar     = VALUE #( ( ucomm = 'REFRESH' label = 'Refresh' icon = 'refresh' ) ) ) ).

* The program creates the grid once, the first time PBO runs. The HTML host
* empties the control registry between requests, so a grid that is no longer
* registered is built again on the same default screen.
    IF grid_is_alive( ) = abap_true.
      mo_grid->refresh_table_display( ).
      RETURN.
    ENDIF.
    lt_fcat = VALUE #(
      ( fieldname = 'EVENT'     coltext = 'Event'     inttype = 'C' )
      ( fieldname = 'OBJECT'    coltext = 'Object'    inttype = 'C' )
      ( fieldname = 'PAUSED_BY' coltext = 'Paused by' inttype = 'C' ) ).
    mo_grid = NEW cl_gui_alv_grid( i_parent = cl_gui_container=>default_screen ).
    mo_grid->set_table_for_first_display(
      CHANGING
        it_outtab       = mt_events
        it_fieldcatalog = lt_fcat ).
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

  METHOD grid_is_alive.
    IF mo_grid IS NOT BOUND.
      RETURN.
    ENDIF.
    rv_alive = xsdbool( mo_grid->is_alive( ) = cl_gui_control=>state_alive ).
  ENDMETHOD.

ENDCLASS.
