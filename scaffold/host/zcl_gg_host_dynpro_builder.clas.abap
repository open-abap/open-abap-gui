CLASS zcl_gg_host_dynpro_builder DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_builder_v1.

    TYPES ty_screens TYPE STANDARD TABLE OF zif_gg_dynpro_types_v1=>ty_screen
      WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_control_record,
             screen         TYPE zif_gg_dynpro_types_v1=>ty_screen_number,
             kind           TYPE string,
             name           TYPE zif_gg_dynpro_types_v1=>ty_name,
             parent         TYPE zif_gg_dynpro_types_v1=>ty_name,
             text           TYPE string,
             ucomm          TYPE zif_gg_dynpro_types_v1=>ty_ucomm,
             position       TYPE zif_gg_dynpro_types_v1=>ty_position,
             data_type      TYPE zif_gg_dynpro_types_v1=>ty_data_type,
             modif_id       TYPE zif_gg_dynpro_types_v1=>ty_modif_id,
             search_help    TYPE zif_gg_dynpro_types_v1=>ty_name,
             value_help     TYPE abap_bool,
             uppercase      TYPE abap_bool,
             fixed_values   TYPE zif_gg_dynpro_types_v1=>ty_fixed_values,
             required       TYPE abap_bool,
             enabled        TYPE abap_bool,
             visible        TYPE abap_bool,
             input          TYPE abap_bool,
             password       TYPE abap_bool,
             group          TYPE zif_gg_dynpro_types_v1=>ty_group,
             subscreen      TYPE zif_gg_dynpro_types_v1=>ty_screen_number,
             table_control  TYPE zif_gg_dynpro_types_v1=>ty_name,
             visible_rows   TYPE i,
             selection_mode TYPE string,
             with_hscroll   TYPE abap_bool,
             with_vscroll   TYPE abap_bool,
             column_title   TYPE string,
             column_width   TYPE i,
           END OF ty_control_record.
    TYPES ty_controls TYPE STANDARD TABLE OF ty_control_record WITH DEFAULT KEY.

    METHODS get_screens
      RETURNING
        VALUE(rt_screens) TYPE ty_screens.

    METHODS get_controls
      RETURNING
        VALUE(rt_controls) TYPE ty_controls.

  PRIVATE SECTION.
    DATA mt_screens TYPE ty_screens.
    DATA mt_controls TYPE ty_controls.
    DATA mv_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.
    DATA mv_table_control TYPE zif_gg_dynpro_types_v1=>ty_name.

ENDCLASS.

CLASS zcl_gg_host_dynpro_builder IMPLEMENTATION.

  METHOD get_screens.
    rt_screens = mt_screens.
  ENDMETHOD.

  METHOD get_controls.
    rt_controls = mt_controls.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~begin_screen.
    APPEND is_screen TO mt_screens.
    mv_screen = is_screen-number.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_input_field.
    APPEND VALUE #( screen      = mv_screen
                    kind        = 'INPUT'
                    name        = is_input_field-control-name
                    position    = is_input_field-control-position
                    data_type   = is_input_field-data_type
                    modif_id    = is_input_field-control-modif_id
                    search_help = is_input_field-search_help
                    value_help  = is_input_field-value_help
                    uppercase   = is_input_field-uppercase
                    required    = is_input_field-required
                    enabled     = abap_true
                    visible     = abap_true
                    input       = abap_true
                    password    = is_input_field-password ) TO mt_controls.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_output_field.
    APPEND VALUE #( screen    = mv_screen
                    kind      = 'OUTPUT'
                    name      = is_output_field-control-name
                    position  = is_output_field-control-position
                    data_type = is_output_field-data_type
                    modif_id  = is_output_field-control-modif_id
                    enabled   = abap_false
                    visible   = abap_true
                    input     = abap_false ) TO mt_controls.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_text.
    APPEND VALUE #( screen   = mv_screen
                    kind     = 'TEXT'
                    name     = is_text-control-name
                    text     = is_text-text
                    position = is_text-control-position
                    visible  = abap_true
                    input    = abap_false ) TO mt_controls.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_pushbutton.
    APPEND VALUE #( screen   = mv_screen
                    kind     = 'PUSHBUTTON'
                    name     = is_pushbutton-control-name
                    text     = is_pushbutton-text
                    ucomm    = is_pushbutton-ucomm
                    position = is_pushbutton-control-position
                    enabled  = abap_true
                    visible  = abap_true ) TO mt_controls.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_checkbox.
    APPEND VALUE #( screen   = mv_screen
                    kind     = 'CHECKBOX'
                    name     = is_checkbox-control-name
                    text     = is_checkbox-text
                    ucomm    = is_checkbox-ucomm
                    position = is_checkbox-control-position
                    enabled  = abap_true
                    visible  = abap_true ) TO mt_controls.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_radiobutton.
    APPEND VALUE #( screen   = mv_screen
                    kind     = 'RADIOBUTTON'
                    name     = is_radiobutton-control-name
                    text     = is_radiobutton-text
                    ucomm    = is_radiobutton-ucomm
                    position = is_radiobutton-control-position
                    group    = is_radiobutton-group
                    enabled  = abap_true
                    visible  = abap_true ) TO mt_controls.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_listbox.
    APPEND VALUE #( screen       = mv_screen
                    kind         = 'LISTBOX'
                    name         = is_listbox-control-name
                    position     = is_listbox-control-position
                    data_type    = is_listbox-data_type
                    fixed_values = is_listbox-fixed_values
                    ucomm        = is_listbox-ucomm
                    enabled      = abap_true
                    visible      = abap_true ) TO mt_controls.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_box.
    APPEND VALUE #( screen   = mv_screen
                    kind     = 'BOX'
                    name     = is_box-control-name
                    text     = is_box-text
                    position = is_box-control-position
                    visible  = abap_true ) TO mt_controls.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_subscreen_area.
    APPEND VALUE #( screen   = mv_screen
                    kind     = 'SUBSCREEN_AREA'
                    name     = is_subscreen_area-control-name
                    position = is_subscreen_area-control-position
                    visible  = abap_true ) TO mt_controls.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_custom_control.
    APPEND VALUE #( screen   = mv_screen
                    kind     = 'CUSTOM_CONTROL'
                    name     = is_custom_control-control-name
                    position = is_custom_control-control-position
                    visible  = abap_true ) TO mt_controls.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_tabstrip.
    APPEND VALUE #( screen   = mv_screen
                    kind     = 'TABSTRIP'
                    name     = is_tabstrip-control-name
                    position = is_tabstrip-control-position
                    ucomm    = is_tabstrip-ucomm
                    enabled  = abap_true
                    visible  = abap_true ) TO mt_controls.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_tab.
    APPEND VALUE #( screen    = mv_screen
                    kind      = 'TAB'
                    name      = is_tab-control-name
                    parent    = is_tab-tabstrip
                    text      = is_tab-text
                    ucomm     = is_tab-ucomm
                    position  = is_tab-control-position
                    subscreen = is_tab-subscreen
                    enabled   = abap_true
                    visible   = abap_true ) TO mt_controls.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~begin_table_control.
    mv_table_control = is_table_control-control-name.
    APPEND VALUE #( screen         = mv_screen
                    kind           = 'TABLE_CONTROL'
                    name           = is_table_control-control-name
                    position       = is_table_control-control-position
                    visible_rows   = is_table_control-visible_rows
                    selection_mode = is_table_control-selection_mode
                    with_hscroll   = is_table_control-with_hscroll
                    with_vscroll   = is_table_control-with_vscroll
                    enabled        = abap_true
                    visible        = abap_true ) TO mt_controls.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_table_column.
    APPEND VALUE #( screen       = mv_screen
                    kind         = 'TABLE_COLUMN'
                    name         = is_table_column-name
                    parent       = mv_table_control
                    text         = is_table_column-title
                    data_type    = is_table_column-data_type
                    column_title = is_table_column-title
                    column_width = is_table_column-width
                    required     = is_table_column-required
                    input        = is_table_column-input
                    visible      = abap_true ) TO mt_controls.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~end_table_control.
    CLEAR mv_table_control.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~end_screen.
    CLEAR mv_screen.
    CLEAR mv_table_control.
  ENDMETHOD.

ENDCLASS.
