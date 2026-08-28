CLASS zcl_gg_host_dynpro DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_result,
             screen   TYPE zif_gg_dynpro_types_v1=>ty_screen_number,
             terminal TYPE string,
             values   TYPE zif_gg_dynpro_types_v1=>ty_values,
           END OF ty_result.

    CLASS-METHODS run
      IMPORTING
        io_program       TYPE REF TO zif_gg_dynpro_v1
        iv_ucomm         TYPE zif_gg_dynpro_types_v1=>ty_ucomm DEFAULT 'BACK'
      RETURNING
        VALUE(rs_result) TYPE ty_result.

ENDCLASS.

CLASS zcl_gg_host_dynpro IMPLEMENTATION.

  METHOD run.
    DATA lo_builder TYPE REF TO zcl_gg_host_dynpro_builder.
    DATA lo_flow TYPE REF TO zcl_gg_host_dynpro_flow.
    DATA lo_list TYPE REF TO zcl_gg_host_list.
    DATA lo_session TYPE REF TO zcl_gg_host_session.
    DATA lt_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    DATA lt_states TYPE zif_gg_dynpro_types_v1=>ty_states.
    DATA lv_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.
    DATA lx_flow TYPE REF TO zcx_gg_control_flow.

    lo_builder = NEW zcl_gg_host_dynpro_builder( ).
    lo_flow = NEW zcl_gg_host_dynpro_flow( ).
    lo_list = NEW zcl_gg_host_list( ).
    lo_session = NEW zcl_gg_host_session( io_list = lo_list ).

    io_program->build_screens( lo_builder ).
    io_program->build_flow_logic( lo_flow ).
    io_program->initialization(
      EXPORTING
        io_session = lo_session
      CHANGING
        ct_values  = lt_values ).

    lv_screen = io_program->get_initial_screen( ).
    TRY.
        LOOP AT lo_flow->get_modules( ) INTO DATA(ls_module)
            WHERE screen = lv_screen AND phase = 'PBO'.
          lo_session->set_event( 'PROCESS BEFORE OUTPUT' ).
          io_program->process_output_module(
            EXPORTING
              is_context = VALUE #( screen = lv_screen module = ls_module-module-name )
              io_session = lo_session
            CHANGING
              ct_values  = lt_values
              ct_states  = lt_states ).
        ENDLOOP.

        LOOP AT lo_flow->get_modules( ) INTO ls_module
            WHERE screen = lv_screen AND phase = 'PAI'.
          lo_session->set_event( 'PROCESS AFTER INPUT' ).
          io_program->process_input_module(
            EXPORTING
              is_context = VALUE #( screen = lv_screen module = ls_module-module-name ucomm = iv_ucomm )
              io_session = lo_session
            CHANGING
              ct_values = lt_values ).
        ENDLOOP.
      CATCH zcx_gg_control_flow INTO lx_flow.
        rs_result-terminal = lx_flow->mv_operation.
        CASE lx_flow->mv_kind.
          WHEN zcx_gg_control_flow=>kind_leave_screen.
            lv_screen = lo_session->get_next_screen( ).
            IF lv_screen IS INITIAL.
              lv_screen = io_program->get_initial_screen( ).
            ENDIF.
          WHEN zcx_gg_control_flow=>kind_leave_to_screen.
            lv_screen = lo_session->get_next_screen( ).
        ENDCASE.
    ENDTRY.

    rs_result-screen = lv_screen.
    rs_result-values = lt_values.
  ENDMETHOD.

ENDCLASS.
