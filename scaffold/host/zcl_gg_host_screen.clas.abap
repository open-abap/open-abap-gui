CLASS zcl_gg_host_screen DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Selection screen builder that records the initial values and the block
* definitions needed by the host tests.
*
* The host does not render a selection screen yet, but retains its structural
* elements so layout-oriented examples can inspect the builder result.

  PUBLIC SECTION.
    INTERFACES zif_gg_selection_screen_builder_v1.

    TYPES: BEGIN OF ty_block,
             block TYPE zif_gg_selection_screen_types=>ty_block,
             depth TYPE i,
           END OF ty_block.
    TYPES ty_blocks TYPE STANDARD TABLE OF ty_block WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_element,
             kind         TYPE string,
             name         TYPE zif_gg_selection_screen_types=>ty_name,
             text         TYPE string,
             ucomm        TYPE zif_gg_selection_screen_types=>ty_ucomm,
             number       TYPE i,
             lines        TYPE i,
             subscreen    TYPE zif_gg_selection_screen_types=>ty_name,
             screen       TYPE zif_gg_selection_screen_types=>ty_screen_number,
             as_window    TYPE abap_bool,
             as_subscreen TYPE abap_bool,
             position     TYPE i,
             length       TYPE i,
             line         TYPE i,
           END OF ty_element.
    TYPES ty_elements TYPE STANDARD TABLE OF ty_element WITH DEFAULT KEY.

    METHODS get_values
      RETURNING
        VALUE(rt_values) TYPE zif_gg_selection_screen_types=>ty_values.

    METHODS get_blocks
      RETURNING
        VALUE(rt_blocks) TYPE ty_blocks.

    METHODS get_elements
      RETURNING
        VALUE(rt_elements) TYPE ty_elements.

    METHODS get_states
      RETURNING
        VALUE(rt_states) TYPE zif_gg_selection_screen_types=>ty_states.

  PRIVATE SECTION.
    DATA mt_values TYPE zif_gg_selection_screen_types=>ty_values.
    DATA mt_blocks TYPE ty_blocks.
    DATA mt_elements TYPE ty_elements.
    DATA mt_states TYPE zif_gg_selection_screen_types=>ty_states.
    DATA mv_block_depth TYPE i.
    DATA mv_line TYPE i.
    DATA mv_position TYPE i.
    DATA mv_in_line TYPE abap_bool.

    METHODS add_value
      IMPORTING
        iv_name  TYPE zif_gg_selection_screen_types=>ty_name
        iv_value TYPE string OPTIONAL
        is_range TYPE zif_gg_selection_screen_types=>ty_range OPTIONAL.

    METHODS add_element
      IMPORTING
        iv_kind         TYPE string
        iv_name         TYPE zif_gg_selection_screen_types=>ty_name OPTIONAL
        iv_text         TYPE string OPTIONAL
        iv_ucomm        TYPE zif_gg_selection_screen_types=>ty_ucomm OPTIONAL
        iv_number       TYPE i OPTIONAL
        iv_lines        TYPE i OPTIONAL
        iv_subscreen    TYPE zif_gg_selection_screen_types=>ty_name OPTIONAL
        iv_screen       TYPE zif_gg_selection_screen_types=>ty_screen_number OPTIONAL
        iv_as_window    TYPE abap_bool OPTIONAL
        iv_as_subscreen TYPE abap_bool OPTIONAL
        iv_position     TYPE i OPTIONAL
        iv_length       TYPE i OPTIONAL.

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
      iv_length   = is_parameter-data_type-length ).
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
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_pushbutton.
    add_element(
      iv_kind     = 'PUSHBUTTON'
      iv_name     = is_pushbutton-name
      iv_text     = is_pushbutton-text
      iv_ucomm    = is_pushbutton-ucomm
      iv_position = is_pushbutton-position
      iv_length   = is_pushbutton-length ).
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_comment.
    add_element(
      iv_kind     = 'COMMENT'
      iv_name     = is_comment-name
      iv_text     = is_comment-text
      iv_position = is_comment-position
      iv_length   = is_comment-visible_length ).
    IF mv_in_line = abap_true AND is_comment-position > 0.
      mv_position = is_comment-position + is_comment-visible_length.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_uline.
    add_element(
      iv_kind     = 'ULINE'
      iv_position = is_uline-position
      iv_length   = is_uline-length ).
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_skip.
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
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~end_tabbed_block.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~begin_screen.
    add_element(
      iv_kind        = 'SCREEN'
      iv_screen      = is_screen-number
      iv_as_window   = is_screen-as_window
      iv_as_subscreen = is_screen-as_subscreen ).
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~end_screen.
    RETURN.
  ENDMETHOD.

ENDCLASS.
