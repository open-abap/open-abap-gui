CLASS zcl_gg_host_report_dynpro DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Adapter from the auxiliary report screen-provider contract to the
* executable dynpro contract consumed by zcl_gg_host_dynpro.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        io_provider  TYPE REF TO zif_gg_screen_provider_v1
        io_resumable TYPE REF TO zif_gg_resumable_v1 OPTIONAL
        io_context   TYPE REF TO zif_gg_context_menu_v1 OPTIONAL.

    INTERFACES zif_gg_dynpro_v1.
    INTERFACES zif_gg_resumable_v1.
    INTERFACES zif_gg_context_menu_v1.

* The program of the report the screens belong to, sy-repid in its modules.
    METHODS get_program
      RETURNING
        VALUE(rv_program) TYPE zif_gg_session_types_v1=>ty_program.

  PRIVATE SECTION.
    DATA mo_provider TYPE REF TO zif_gg_screen_provider_v1.
    DATA mo_resumable TYPE REF TO zif_gg_resumable_v1.
    DATA mo_context TYPE REF TO zif_gg_context_menu_v1.
ENDCLASS.

CLASS zcl_gg_host_report_dynpro IMPLEMENTATION.

  METHOD constructor.
    mo_provider = io_provider.
    mo_resumable = io_resumable.
    mo_context = io_context.
  ENDMETHOD.

  METHOD get_program.
    DATA lo_transaction TYPE REF TO zif_gg_transaction_v1.

    TRY.
        lo_transaction ?= mo_provider.
        rv_program = lo_transaction->get_transaction( )-program.
      CATCH cx_sy_move_cast_error.
        CLEAR rv_program.
    ENDTRY.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = mo_provider->get_initial_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    mo_provider->build_screens( io_builder = io_builder ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_flow_logic.
    mo_provider->build_flow_logic( io_builder = io_builder ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~initialization.
    mo_provider->initialization(
      EXPORTING
        io_session = io_session
      CHANGING
        ct_values  = ct_values ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    mo_provider->process_output_module(
      EXPORTING
        is_context = is_context
        io_session = io_session
      CHANGING
        ct_values  = ct_values
        ct_states  = ct_states ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    mo_provider->process_input_module(
      EXPORTING
        is_context = is_context
        io_session = io_session
      CHANGING
        ct_values  = ct_values ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_value_request.
    rt_values = mo_provider->process_on_value_request(
      is_context = is_context
      it_values  = it_values
      io_session = io_session ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_help_request.
    rv_text = mo_provider->process_on_help_request(
      is_context = is_context
      it_values  = it_values
      io_session = io_session ).
  ENDMETHOD.

  METHOD zif_gg_resumable_v1~resume.
    IF mo_resumable IS BOUND.
      mo_resumable->resume(
        is_resume  = is_resume
        io_session = io_session ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_context_menu_v1~get_context_menu.
    IF mo_context IS BOUND.
      ro_menu = mo_context->get_context_menu(
        iv_field   = iv_field
        io_session = io_session ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
