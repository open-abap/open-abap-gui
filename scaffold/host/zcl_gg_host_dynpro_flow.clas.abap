CLASS zcl_gg_host_dynpro_flow DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_flow_builder_v1.

    TYPES: BEGIN OF ty_module,
             screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number,
             phase  TYPE string,
             module TYPE zif_gg_dynpro_types_v1=>ty_flow_module,
           END OF ty_module.
    TYPES ty_modules TYPE STANDARD TABLE OF ty_module WITH DEFAULT KEY.

    METHODS get_modules
      RETURNING
        VALUE(rt_modules) TYPE ty_modules.

  PRIVATE SECTION.
    DATA mv_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.
    DATA mv_phase TYPE string.
    DATA mt_modules TYPE ty_modules.

ENDCLASS.

CLASS zcl_gg_host_dynpro_flow IMPLEMENTATION.

  METHOD get_modules.
    rt_modules = mt_modules.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~begin_screen.
    mv_screen = iv_screen.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~begin_pbo.
    mv_phase = 'PBO'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~begin_pai.
    mv_phase = 'PAI'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~begin_value_request.
    mv_phase = 'POV'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~begin_help_request.
    mv_phase = 'POH'.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~add_field.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~add_module.
    APPEND VALUE #( screen = mv_screen phase = mv_phase module = is_module ) TO mt_modules.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~call_subscreen.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~begin_chain.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~end_chain.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~begin_table_loop.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~end_table_loop.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~end_processing.
    mv_phase = ''.
  ENDMETHOD.

  METHOD zif_gg_dynpro_flow_builder_v1~end_screen.
    mv_screen = ''.
    mv_phase = ''.
  ENDMETHOD.

ENDCLASS.
