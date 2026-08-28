CLASS zcl_gg_host_dynpro_flow DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_flow_builder_v1.

    TYPES: BEGIN OF ty_module,
             screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number,
             phase  TYPE string,
             module TYPE zif_gg_dynpro_types_v1=>ty_flow_module,
           END OF ty_module.
    TYPES ty_modules TYPE STANDARD TABLE OF ty_module WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_step,
             order       TYPE i,
             screen      TYPE zif_gg_dynpro_types_v1=>ty_screen_number,
             phase       TYPE string,
             kind        TYPE string,
             field       TYPE zif_gg_dynpro_types_v1=>ty_name,
             module      TYPE zif_gg_dynpro_types_v1=>ty_flow_module,
             subscreen   TYPE zif_gg_dynpro_types_v1=>ty_subscreen_call,
             table_loop  TYPE zif_gg_dynpro_types_v1=>ty_table_loop,
             chain_depth TYPE i,
           END OF ty_step.
    TYPES ty_steps TYPE STANDARD TABLE OF ty_step WITH DEFAULT KEY.

    METHODS get_modules
      RETURNING
        VALUE(rt_modules) TYPE ty_modules.

    METHODS get_steps
      RETURNING
        VALUE(rt_steps) TYPE ty_steps.

  PRIVATE SECTION.
    DATA mv_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.
    DATA mv_phase TYPE string.
    DATA mt_modules TYPE ty_modules.
    DATA mt_steps TYPE ty_steps.
    DATA mv_chain_depth TYPE i.
    DATA mv_table_control TYPE zif_gg_dynpro_types_v1=>ty_name.

    METHODS add_step
      IMPORTING
        iv_kind       TYPE string
        iv_field      TYPE zif_gg_dynpro_types_v1=>ty_name OPTIONAL
        is_module     TYPE zif_gg_dynpro_types_v1=>ty_flow_module OPTIONAL
        is_subscreen  TYPE zif_gg_dynpro_types_v1=>ty_subscreen_call OPTIONAL
        is_table_loop TYPE zif_gg_dynpro_types_v1=>ty_table_loop OPTIONAL.

ENDCLASS.

CLASS zcl_gg_host_dynpro_flow IMPLEMENTATION.

  METHOD get_modules.
    rt_modules = mt_modules.
  ENDMETHOD.

  METHOD get_steps.
    rt_steps = mt_steps.
  ENDMETHOD.

  METHOD add_step.
    APPEND VALUE #( order       = lines( mt_steps ) + 1
                    screen      = mv_screen
                    phase       = mv_phase
                    kind        = iv_kind
                    field       = iv_field
                    module      = is_module
                    subscreen   = is_subscreen
                    table_loop  = is_table_loop
                    chain_depth = mv_chain_depth ) TO mt_steps.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~begin_screen.
    mv_screen = iv_screen.
    add_step( iv_kind = 'SCREEN' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~begin_pbo.
    mv_phase = 'PBO'.
    add_step( iv_kind = 'PBO' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~begin_pai.
    mv_phase = 'PAI'.
    add_step( iv_kind = 'PAI' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~begin_value_request.
    mv_phase = 'POV'.
    add_step( iv_kind = 'VALUE_REQUEST' iv_field = iv_field ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~begin_help_request.
    mv_phase = 'POH'.
    add_step( iv_kind = 'HELP_REQUEST' iv_field = iv_field ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~add_field.
    add_step( iv_kind = 'FIELD' iv_field = iv_field ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~add_module.
    APPEND VALUE #( screen = mv_screen phase = mv_phase module = is_module ) TO mt_modules.
    add_step( iv_kind = 'MODULE' is_module = is_module ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~call_subscreen.
    add_step( iv_kind = 'SUBSCREEN' is_subscreen = is_subscreen ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~begin_chain.
    mv_chain_depth = mv_chain_depth + 1.
    add_step( iv_kind = 'BEGIN_CHAIN' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~end_chain.
    add_step( iv_kind = 'END_CHAIN' ).
    IF mv_chain_depth > 0.
      mv_chain_depth = mv_chain_depth - 1.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~begin_table_loop.
    mv_table_control = is_table_loop-table_control.
    add_step( iv_kind = 'BEGIN_TABLE_LOOP' is_table_loop = is_table_loop ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~end_table_loop.
    add_step( iv_kind = 'END_TABLE_LOOP' ).
    CLEAR mv_table_control.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~end_processing.
    add_step( iv_kind = 'END_PROCESSING' ).
    mv_phase = ''.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~end_screen.
    add_step( iv_kind = 'END_SCREEN' ).
    mv_screen = ''.
    mv_phase = ''.
    CLEAR mv_chain_depth.
    CLEAR mv_table_control.
  ENDMETHOD.

ENDCLASS.
