CLASS zcl_gg_host_screen DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Selection screen builder that records values, mutable states, and all
* operation-specific layout data needed by the HTML renderer.

  PUBLIC SECTION.
    INTERFACES zif_gg_selection_screen_builder_v1.

    TYPES: BEGIN OF ty_block,
             block TYPE zif_gg_selection_screen_types=>ty_block,
             depth TYPE i,
           END OF ty_block.
    TYPES ty_blocks TYPE STANDARD TABLE OF ty_block WITH DEFAULT KEY.

    TYPES ty_screens TYPE STANDARD TABLE OF zif_gg_selection_screen_types=>ty_screen
      WITH DEFAULT KEY.
    TYPES: BEGIN OF ty_tab,
             block     TYPE zif_gg_selection_screen_types=>ty_name,
             name      TYPE zif_gg_selection_screen_types=>ty_name,
             text      TYPE string,
             subscreen TYPE zif_gg_selection_screen_types=>ty_name,
             ucomm     TYPE zif_gg_selection_screen_types=>ty_ucomm,
             selected  TYPE abap_bool,
           END OF ty_tab.
    TYPES ty_tabs TYPE STANDARD TABLE OF ty_tab WITH DEFAULT KEY.
    TYPES: BEGIN OF ty_element,
             kind           TYPE string,
             name           TYPE zif_gg_selection_screen_types=>ty_name,
             text           TYPE string,
             ucomm          TYPE zif_gg_selection_screen_types=>ty_ucomm,
             number         TYPE i,
             lines          TYPE i,
             subscreen      TYPE zif_gg_selection_screen_types=>ty_name,
             screen         TYPE zif_gg_selection_screen_types=>ty_screen_number,
             as_window      TYPE abap_bool,
             as_subscreen   TYPE abap_bool,
             position       TYPE i,
             length         TYPE i,
             line           TYPE i,
             block_depth    TYPE i,
             visible_length TYPE i,
             for_field      TYPE zif_gg_selection_screen_types=>ty_name,
             modif_id       TYPE zif_gg_selection_screen_types=>ty_modif_id,
             data_type      TYPE zif_gg_selection_screen_types=>ty_data_type,
             fixed_values   TYPE zif_gg_selection_screen_types=>ty_fixed_values,
             no_extension   TYPE abap_bool,
             no_intervals   TYPE abap_bool,
             value_help     TYPE abap_bool,
           END OF ty_element.
    TYPES ty_elements TYPE STANDARD TABLE OF ty_element WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_snapshot,
             screen       TYPE zif_gg_selection_screen_types=>ty_screen_number,
             screens      TYPE ty_screens,
             blocks       TYPE ty_blocks,
             elements     TYPE ty_elements,
             tabs         TYPE ty_tabs,
             values       TYPE zif_gg_selection_screen_types=>ty_values,
             states       TYPE zif_gg_selection_screen_types=>ty_states,
             selected_tab TYPE zif_gg_selection_screen_types=>ty_name,
           END OF ty_snapshot.

    METHODS get_values
      RETURNING
        VALUE(rt_values) TYPE zif_gg_selection_screen_types=>ty_values.

    METHODS get_blocks
      RETURNING
        VALUE(rt_blocks) TYPE ty_blocks.

    METHODS get_screens
      RETURNING
        VALUE(rt_screens) TYPE ty_screens.

    METHODS get_tabs
      RETURNING
        VALUE(rt_tabs) TYPE ty_tabs.

    METHODS get_snapshot
      IMPORTING
        iv_screen          TYPE zif_gg_selection_screen_types=>ty_screen_number OPTIONAL
        it_values          TYPE zif_gg_selection_screen_types=>ty_values OPTIONAL
        it_states          TYPE zif_gg_selection_screen_types=>ty_states OPTIONAL
      RETURNING
        VALUE(rs_snapshot) TYPE ty_snapshot.

    METHODS get_elements
      RETURNING
        VALUE(rt_elements) TYPE ty_elements.

    METHODS get_states
      RETURNING
        VALUE(rt_states) TYPE zif_gg_selection_screen_types=>ty_states.

  PRIVATE SECTION.
    DATA mt_values TYPE zif_gg_selection_screen_types=>ty_values.
    DATA mt_blocks TYPE ty_blocks.
    DATA mt_screens TYPE ty_screens.
    DATA mt_tabs TYPE ty_tabs.
    DATA mt_elements TYPE ty_elements.
    DATA mt_states TYPE zif_gg_selection_screen_types=>ty_states.
    DATA mv_block_depth TYPE i.
    DATA mv_line TYPE i.
    DATA mv_position TYPE i.
    DATA mv_in_line TYPE abap_bool.
    DATA mv_screen TYPE zif_gg_selection_screen_types=>ty_screen_number.
    DATA mv_tabbed_block TYPE zif_gg_selection_screen_types=>ty_name.

    METHODS add_value
      IMPORTING
        iv_name  TYPE zif_gg_selection_screen_types=>ty_name
        iv_value TYPE string OPTIONAL
        is_range TYPE zif_gg_selection_screen_types=>ty_range OPTIONAL.

    METHODS add_element
      IMPORTING
        iv_kind           TYPE string
        iv_name           TYPE zif_gg_selection_screen_types=>ty_name OPTIONAL
        iv_text           TYPE string OPTIONAL
        iv_ucomm          TYPE zif_gg_selection_screen_types=>ty_ucomm OPTIONAL
        iv_number         TYPE i OPTIONAL
        iv_lines          TYPE i OPTIONAL
        iv_subscreen      TYPE zif_gg_selection_screen_types=>ty_name OPTIONAL
        iv_screen         TYPE zif_gg_selection_screen_types=>ty_screen_number OPTIONAL
        iv_as_window      TYPE abap_bool OPTIONAL
        iv_as_subscreen   TYPE abap_bool OPTIONAL
        iv_position       TYPE i OPTIONAL
        iv_length         TYPE i OPTIONAL
        iv_visible_length TYPE i OPTIONAL
        iv_for_field      TYPE zif_gg_selection_screen_types=>ty_name OPTIONAL
        iv_modif_id       TYPE zif_gg_selection_screen_types=>ty_modif_id OPTIONAL
        iv_no_extension   TYPE abap_bool OPTIONAL
        iv_no_intervals   TYPE abap_bool OPTIONAL
        iv_value_help     TYPE abap_bool OPTIONAL
        is_data_type      TYPE zif_gg_selection_screen_types=>ty_data_type OPTIONAL
        it_fixed_values   TYPE zif_gg_selection_screen_types=>ty_fixed_values OPTIONAL.

    METHODS add_state
      IMPORTING
        iv_name        TYPE zif_gg_selection_screen_types=>ty_name
        iv_text        TYPE string OPTIONAL
        iv_modif_id    TYPE zif_gg_selection_screen_types=>ty_modif_id OPTIONAL
        iv_memory_id   TYPE zif_gg_selection_screen_types=>ty_name OPTIONAL
        iv_search_help TYPE zif_gg_selection_screen_types=>ty_name OPTIONAL
        iv_lower_case  TYPE abap_bool OPTIONAL
        iv_no_display  TYPE abap_bool OPTIONAL
        iv_value_help  TYPE abap_bool OPTIONAL
        iv_group1      TYPE zif_gg_selection_screen_types=>ty_group OPTIONAL
        iv_obligatory  TYPE abap_bool OPTIONAL.

ENDCLASS.

CLASS zcl_gg_host_screen IMPLEMENTATION.

  METHOD get_values.
    rt_values = mt_values.
  ENDMETHOD.

  METHOD get_blocks.
    rt_blocks = mt_blocks.
  ENDMETHOD.

  METHOD get_screens.
    rt_screens = mt_screens.
  ENDMETHOD.

  METHOD get_tabs.
    rt_tabs = mt_tabs.
  ENDMETHOD.

  METHOD get_snapshot.
    rs_snapshot-screen = iv_screen.
    IF rs_snapshot-screen IS INITIAL.
      rs_snapshot-screen = mv_screen.
    ENDIF.
    rs_snapshot-screens = mt_screens.
    rs_snapshot-blocks = mt_blocks.
    rs_snapshot-elements = mt_elements.
    rs_snapshot-tabs = mt_tabs.
    rs_snapshot-values = mt_values.
    rs_snapshot-states = mt_states.
    IF it_values IS NOT INITIAL.
      rs_snapshot-values = it_values.
    ENDIF.
    IF it_states IS NOT INITIAL.
      rs_snapshot-states = it_states.
    ENDIF.
    READ TABLE mt_tabs INTO DATA(ls_tab) INDEX 1.
    IF sy-subrc = 0.
      rs_snapshot-selected_tab = ls_tab-name.
    ENDIF.
  ENDMETHOD.

  METHOD get_elements.
    rt_elements = mt_elements.
  ENDMETHOD.

  METHOD get_states.
    rt_states = mt_states.
  ENDMETHOD.

  METHOD add_element.
    DATA ls_element TYPE ty_element.

    ls_element-kind = iv_kind.
    ls_element-name = iv_name.
    ls_element-text = iv_text.
    ls_element-ucomm = iv_ucomm.
    ls_element-number = iv_number.
    ls_element-lines = iv_lines.
    ls_element-subscreen = iv_subscreen.
    ls_element-screen = iv_screen.
    ls_element-as_window = iv_as_window.
    ls_element-as_subscreen = iv_as_subscreen.
    ls_element-position = iv_position.
    ls_element-length = iv_length.
    ls_element-line = mv_line.
    ls_element-block_depth = mv_block_depth.
    ls_element-visible_length = iv_visible_length.
    ls_element-for_field = iv_for_field.
    ls_element-modif_id = iv_modif_id.
    ls_element-data_type = is_data_type.
    ls_element-fixed_values = it_fixed_values.
    ls_element-no_extension = iv_no_extension.
    ls_element-no_intervals = iv_no_intervals.
    ls_element-value_help = iv_value_help.
    IF ls_element-screen IS INITIAL.
      ls_element-screen = mv_screen.
      IF ls_element-screen IS INITIAL.
        ls_element-screen = '1000'.
      ENDIF.
    ENDIF.
    APPEND ls_element TO mt_elements.
  ENDMETHOD.

  METHOD add_value.
    DATA ls_value TYPE zif_gg_selection_screen_types=>ty_value.

    ls_value-name  = iv_name.
    ls_value-value = iv_value.
    IF is_range-sign IS NOT INITIAL.
      APPEND is_range TO ls_value-ranges.
    ENDIF.
    INSERT ls_value INTO TABLE mt_values.
  ENDMETHOD.

  METHOD add_state.
    DATA ls_state TYPE zif_gg_selection_screen_types=>ty_state.

    ls_state-name = iv_name.
    ls_state-text = iv_text.
    ls_state-modif_id = iv_modif_id.
    ls_state-memory_id = iv_memory_id.
    ls_state-search_help = iv_search_help.
    ls_state-lower_case = iv_lower_case.
    ls_state-no_display = iv_no_display.
    ls_state-value_help = iv_value_help.
    ls_state-group1 = iv_group1.
    ls_state-visible = abap_true.
    ls_state-enabled = abap_true.
    ls_state-input = abap_true.
    ls_state-output = abap_true.
    ls_state-obligatory = iv_obligatory.
    INSERT ls_state INTO TABLE mt_states.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_parameter.
    add_value(
      iv_name  = is_parameter-name
      iv_value = is_parameter-default ).
    add_state(
      iv_name       = is_parameter-name
      iv_text       = is_parameter-text
      iv_modif_id   = is_parameter-modif_id
      iv_memory_id  = is_parameter-memory_id
      iv_search_help = is_parameter-search_help
      iv_lower_case = is_parameter-lower_case
      iv_no_display = is_parameter-no_display
      iv_value_help = is_parameter-value_help
      iv_obligatory = is_parameter-obligatory ).
    add_element(
      iv_kind     = 'PARAMETER'
      iv_name     = is_parameter-name
      iv_text     = is_parameter-text
      iv_position = mv_position
      iv_length   = is_parameter-data_type-length
      iv_value_help = is_parameter-value_help
      is_data_type = is_parameter-data_type
      iv_modif_id = is_parameter-modif_id ).
    IF mv_in_line = abap_true.
      mv_position = mv_position + is_parameter-data_type-length.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_checkbox.
    add_value(
      iv_name  = is_checkbox-name
      iv_value = CONV string( is_checkbox-default ) ).
    add_state(
      iv_name       = is_checkbox-name
      iv_text       = is_checkbox-text
      iv_modif_id   = is_checkbox-modif_id
      iv_obligatory = is_checkbox-obligatory ).
    add_element(
      iv_kind     = 'CHECKBOX'
      iv_name     = is_checkbox-name
      iv_text     = is_checkbox-text
      iv_ucomm    = is_checkbox-ucomm
      iv_modif_id = is_checkbox-modif_id ).
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_radiobutton.
    add_value(
      iv_name  = is_radiobutton-name
      iv_value = CONV string( is_radiobutton-default ) ).
    add_state(
      iv_name       = is_radiobutton-name
      iv_text       = is_radiobutton-text
      iv_modif_id   = is_radiobutton-modif_id
      iv_group1     = is_radiobutton-radio_group
      iv_obligatory = is_radiobutton-obligatory ).
    add_element(
      iv_kind     = 'RADIOBUTTON'
      iv_name     = is_radiobutton-name
      iv_text     = is_radiobutton-text
      iv_ucomm    = is_radiobutton-ucomm
      iv_modif_id = is_radiobutton-modif_id ).
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_listbox.
    add_value(
      iv_name  = is_listbox-name
      iv_value = is_listbox-default ).
    add_state(
      iv_name       = is_listbox-name
      iv_text       = is_listbox-text
      iv_modif_id   = is_listbox-modif_id
      iv_obligatory = is_listbox-obligatory ).
    add_element(
      iv_kind         = 'LISTBOX'
      iv_name         = is_listbox-name
      iv_text         = is_listbox-text
      iv_ucomm        = is_listbox-ucomm
      iv_length       = is_listbox-data_type-length
      iv_visible_length = is_listbox-data_type-visible_length
      iv_modif_id     = is_listbox-modif_id
      is_data_type    = is_listbox-data_type
      it_fixed_values = is_listbox-fixed_values ).
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_select_option.
    add_value(
      iv_name  = is_select_option-name
      is_range = is_select_option-default ).
    add_state(
      iv_name       = is_select_option-name
      iv_text       = is_select_option-text
      iv_modif_id   = is_select_option-modif_id
      iv_obligatory = is_select_option-obligatory ).
    add_element(
      iv_kind     = 'SELECT_OPTION'
      iv_name     = is_select_option-name
      iv_text     = is_select_option-text
      iv_length   = is_select_option-data_type-length
      iv_value_help = is_select_option-value_help
      iv_no_extension = is_select_option-no_extension
      iv_no_intervals = is_select_option-no_intervals
      is_data_type = is_select_option-data_type
      iv_modif_id = is_select_option-modif_id ).
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_pushbutton.
    add_element(
      iv_kind     = 'PUSHBUTTON'
      iv_name     = is_pushbutton-name
      iv_text     = is_pushbutton-text
      iv_ucomm    = is_pushbutton-ucomm
      iv_position = is_pushbutton-position
      iv_length   = is_pushbutton-length
      iv_modif_id = is_pushbutton-modif_id ).
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_comment.
    add_element(
      iv_kind     = 'COMMENT'
      iv_name     = is_comment-name
      iv_text     = is_comment-text
      iv_position = is_comment-position
      iv_length   = is_comment-visible_length
      iv_visible_length = is_comment-visible_length
      iv_for_field = is_comment-for_field
      iv_modif_id = is_comment-modif_id ).
    IF mv_in_line = abap_true AND is_comment-position > 0.
      mv_position = is_comment-position + is_comment-visible_length.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_uline.
    add_element(
      iv_kind     = 'ULINE'
      iv_position = is_uline-position
      iv_length   = is_uline-length
      iv_modif_id = is_uline-modif_id ).
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_skip.
    add_element( iv_kind = 'SKIP' iv_length = iv_lines ).
    mv_line = mv_line + iv_lines.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~new_line.
    mv_line = mv_line + 1.
    mv_position = 1.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~set_position.
    mv_position = iv_position.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_function_key.
    add_element(
      iv_kind   = 'FUNCTION_KEY'
      iv_text   = is_function_key-text
      iv_ucomm  = is_function_key-ucomm
      iv_number = is_function_key-number ).
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~begin_block.
    mv_block_depth = mv_block_depth + 1.
    APPEND VALUE #( block = is_block
                    depth = mv_block_depth ) TO mt_blocks.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~end_block.
    IF mv_block_depth > 0.
      mv_block_depth = mv_block_depth - 1.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~begin_line.
    mv_in_line = abap_true.
    mv_line = mv_line + 1.
    mv_position = 1.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~end_line.
    mv_in_line = abap_false.
    mv_position = 0.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~begin_tabbed_block.
    mv_tabbed_block = is_tabbed_block-name.
    add_element(
      iv_kind  = 'TABBED_BLOCK'
      iv_name  = is_tabbed_block-name
      iv_lines = is_tabbed_block-lines ).
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_tab.
    add_element(
      iv_kind      = 'TAB'
      iv_name      = is_tab-name
      iv_text      = is_tab-text
      iv_ucomm     = is_tab-ucomm
      iv_subscreen = is_tab-subscreen ).
    APPEND VALUE #( block = mv_tabbed_block
                    name = is_tab-name
                    text = is_tab-text
                    subscreen = is_tab-subscreen
                    ucomm = is_tab-ucomm
                    selected = xsdbool( lines( mt_tabs ) = 0 ) ) TO mt_tabs.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~end_tabbed_block.
    CLEAR mv_tabbed_block.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~begin_screen.
    APPEND is_screen TO mt_screens.
    mv_screen = is_screen-number.
    add_element(
      iv_kind        = 'SCREEN'
      iv_screen      = is_screen-number
      iv_as_window   = is_screen-as_window
      iv_as_subscreen = is_screen-as_subscreen ).
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~end_screen.
    CLEAR mv_screen.
  ENDMETHOD.

ENDCLASS.
