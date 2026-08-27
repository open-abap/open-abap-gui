INTERFACE zif_gg_dynpro_flow_builder_v1 PUBLIC.

* Ordered dynpro flow-logic command sink. Every processing block is declared
* between begin_screen and end_screen. FIELD and MODULE calls may be nested in
* CHAIN and table-control LOOP blocks exactly where transport must occur.

  METHODS begin_screen
    IMPORTING
      iv_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.

  METHODS begin_pbo.

  METHODS begin_pai.

  METHODS begin_value_request
    IMPORTING
      iv_field TYPE zif_gg_dynpro_types_v1=>ty_name.

  METHODS begin_help_request
    IMPORTING
      iv_field TYPE zif_gg_dynpro_types_v1=>ty_name.

  METHODS add_field
    IMPORTING
      iv_field TYPE zif_gg_dynpro_types_v1=>ty_name.

  METHODS add_module
    IMPORTING
      is_module TYPE zif_gg_dynpro_types_v1=>ty_flow_module.

  METHODS call_subscreen
    IMPORTING
      is_subscreen TYPE zif_gg_dynpro_types_v1=>ty_subscreen_call.

  METHODS begin_chain.

  METHODS end_chain.

  METHODS begin_table_loop
    IMPORTING
      is_table_loop TYPE zif_gg_dynpro_types_v1=>ty_table_loop.

  METHODS end_table_loop.

  METHODS end_processing.

  METHODS end_screen.

ENDINTERFACE.
