INTERFACE zif_gg_compatibility_v1 PUBLIC.

* Typed compatibility boundary for classic SAP GUI function modules. The
* converter maps only the finite, known families below. Unknown function
* modules remain conversion diagnostics instead of being dispatched by name.

  TYPES ty_answer TYPE c LENGTH 1.

  TYPES: BEGIN OF ty_popup_confirm_request,
           titlebar              TYPE string,
           text_question         TYPE string,
           text_button_1         TYPE string,
           icon_button_1         TYPE string,
           text_button_2         TYPE string,
           icon_button_2         TYPE string,
           default_button        TYPE ty_answer,
           display_cancel_button TYPE abap_bool,
           start_column          TYPE i,
           start_row             TYPE i,
         END OF ty_popup_confirm_request.

  TYPES: BEGIN OF ty_popup_inform_request,
           title TYPE string,
           text1 TYPE string,
           text2 TYPE string,
           text3 TYPE string,
           text4 TYPE string,
         END OF ty_popup_inform_request.

  TYPES: BEGIN OF ty_popup_values_request,
           title          TYPE string,
           no_value_check TYPE abap_bool,
           start_column   TYPE i,
           start_row      TYPE i,
         END OF ty_popup_values_request.

  TYPES: BEGIN OF ty_popup_table_request,
           title        TYPE string,
           start_column TYPE i,
           start_row    TYPE i,
           end_column   TYPE i,
           end_row      TYPE i,
         END OF ty_popup_table_request.

  TYPES: BEGIN OF ty_month_request,
           actual_month TYPE string,
           language     TYPE string,
           start_column TYPE i,
           start_row    TYPE i,
         END OF ty_month_request.

  TYPES: BEGIN OF ty_f4_request,
           retfield    TYPE string,
           dynpprog    TYPE string,
           dynpnr      TYPE string,
           dynprofield TYPE string,
           value_org   TYPE string,
         END OF ty_f4_request.

  TYPES: BEGIN OF ty_alv_request,
           callback_program       TYPE string,
           callback_pf_status_set TYPE string,
           callback_user_command  TYPE string,
           callback_top_of_page   TYPE string,
           grid_title             TYPE string,
           tabname_header         TYPE string,
           tabname_item           TYPE string,
           list_type              TYPE i,
           title                  TYPE string,
         END OF ty_alv_request.

  TYPES: BEGIN OF ty_dynamic_selection_request,
           kind         TYPE string,
           selection_id TYPE string,
           title        TYPE string,
           as_window    TYPE abap_bool,
           start_row    TYPE i,
           start_column TYPE i,
           tree_visible TYPE abap_bool,
         END OF ty_dynamic_selection_request.

  TYPES: BEGIN OF ty_variant_request,
           report  TYPE string,
           variant TYPE string,
           title   TYPE string,
         END OF ty_variant_request.

  TYPES: BEGIN OF ty_frontend_url_request,
           type     TYPE string,
           subtype  TYPE string,
           size     TYPE i,
           lifetime TYPE string,
         END OF ty_frontend_url_request.

  METHODS popup_to_confirm
    IMPORTING is_request       TYPE ty_popup_confirm_request
    RETURNING VALUE(rv_answer) TYPE ty_answer.

  METHODS popup_to_inform
    IMPORTING is_request TYPE ty_popup_inform_request.

  METHODS popup_get_values
    IMPORTING is_request           TYPE ty_popup_values_request
    CHANGING  ct_fields            TYPE STANDARD TABLE
    RETURNING VALUE(rv_returncode) TYPE ty_answer.

  METHODS popup_with_table_display
    IMPORTING is_request       TYPE ty_popup_table_request
    CHANGING  ct_values        TYPE STANDARD TABLE
    RETURNING VALUE(rv_choice) TYPE i.

  METHODS popup_to_select_month
    IMPORTING is_request        TYPE ty_month_request
    CHANGING  cv_return_code    TYPE any
              cv_selected_month TYPE any.

  METHODS f4_table_value_request
    IMPORTING is_request    TYPE ty_f4_request
    CHANGING  ct_value_tab  TYPE STANDARD TABLE
              ct_return_tab TYPE STANDARD TABLE.

  METHODS set_selection_list_values
    IMPORTING iv_id     TYPE string
              it_values TYPE vrm_values.

  METHODS alpha_input
    IMPORTING iv_input         TYPE string
    RETURNING VALUE(rv_output) TYPE string.

  METHODS alpha_output
    IMPORTING iv_input         TYPE string
    RETURNING VALUE(rv_output) TYPE string.

  METHODS alv_fieldcatalog_merge
    IMPORTING is_request  TYPE ty_alv_request
    CHANGING  ct_fieldcat TYPE STANDARD TABLE.

  METHODS alv_display
    IMPORTING is_request TYPE ty_alv_request
    CHANGING  ct_outtab  TYPE STANDARD TABLE.

  METHODS alv_display_hierseq
    IMPORTING is_request TYPE ty_alv_request
    CHANGING  ct_header  TYPE STANDARD TABLE
              ct_item    TYPE STANDARD TABLE.

  METHODS alv_block_init
    IMPORTING is_request TYPE ty_alv_request.

  METHODS alv_block_append
    IMPORTING is_request TYPE ty_alv_request
    CHANGING  ct_outtab  TYPE STANDARD TABLE.

  METHODS alv_block_display
    IMPORTING is_request TYPE ty_alv_request.

  METHODS alv_popup_to_select
    IMPORTING is_request  TYPE ty_alv_request
    CHANGING  ct_outtab   TYPE STANDARD TABLE
              cs_selfield TYPE any
              cv_exit     TYPE any.

  METHODS alv_events_get
    IMPORTING is_request TYPE ty_alv_request
    CHANGING  ct_events  TYPE STANDARD TABLE.

  METHODS alv_variant_f4
    IMPORTING is_request TYPE ty_variant_request
    CHANGING  cs_variant TYPE disvariant
              cv_exit    TYPE any.

  METHODS alv_commentary_write
    CHANGING ct_list_commentary TYPE STANDARD TABLE.

  METHODS select_options_restrict
    IMPORTING is_restriction TYPE sscr_restrict.

  METHODS free_selections_init
    IMPORTING is_request      TYPE ty_dynamic_selection_request
    CHANGING  cv_selection_id TYPE any
              ct_field_ranges TYPE any
              ct_tables       TYPE STANDARD TABLE
              ct_fields       TYPE STANDARD TABLE.

  METHODS free_selections_dialog
    IMPORTING is_request       TYPE ty_dynamic_selection_request
    CHANGING  ct_where_clauses TYPE any
              cs_expressions   TYPE any
              ct_field_ranges  TYPE any
              cv_active_fields TYPE any
              ct_fields        TYPE STANDARD TABLE.

  METHODS free_selections_range_to_where
    IMPORTING it_field_ranges  TYPE any
    CHANGING  ct_where_clauses TYPE any.

  METHODS variant_refresh
    IMPORTING is_request   TYPE ty_variant_request
    CHANGING  ct_selection TYPE STANDARD TABLE.

  METHODS variant_catalog
    IMPORTING is_request        TYPE ty_variant_request
    RETURNING VALUE(rv_variant) TYPE string.

  METHODS variant_contents
    IMPORTING is_request  TYPE ty_variant_request
    CHANGING  ct_contents TYPE STANDARD TABLE.

  METHODS variant_create
    IMPORTING is_request  TYPE ty_variant_request
    CHANGING  ct_contents TYPE STANDARD TABLE
              ct_text     TYPE STANDARD TABLE.

  METHODS variant_change
    IMPORTING is_request  TYPE ty_variant_request
    CHANGING  ct_contents TYPE STANDARD TABLE
              ct_text     TYPE STANDARD TABLE.

  METHODS variant_delete
    IMPORTING is_request TYPE ty_variant_request.

  METHODS xstring_to_binary
    IMPORTING iv_buffer        TYPE xstring
    CHANGING  cv_output_length TYPE any
              ct_binary        TYPE STANDARD TABLE.

  METHODS create_url
    IMPORTING is_request TYPE ty_frontend_url_request
    CHANGING  cv_url     TYPE any
              ct_data    TYPE STANDARD TABLE.

  METHODS publish_url
    IMPORTING iv_object     TYPE string
              iv_lifetime   TYPE string
    RETURNING VALUE(rv_url) TYPE string.

  METHODS supports
    IMPORTING iv_family           TYPE string
    RETURNING VALUE(rv_supported) TYPE abap_bool.

ENDINTERFACE.
