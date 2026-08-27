CLASS zcl_gg_host_screen DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Selection screen builder that records just enough to produce the initial
* values, namely the name and the DEFAULT of every value bearing element.
*
* Layout is accepted and dropped. This host does not render a selection screen
* yet, so blocks, lines, comments, tabs and screen boundaries have nowhere to
* go; recording them belongs with the phase 3 work in examples/PLAN.md.

  PUBLIC SECTION.
    INTERFACES zif_gg_selection_screen_builder_v1.

    METHODS get_values
      RETURNING
        VALUE(rt_values) TYPE zif_gg_selection_screen_types=>ty_values.

  PRIVATE SECTION.
    DATA mt_values TYPE zif_gg_selection_screen_types=>ty_values.

    METHODS add_value
      IMPORTING
        iv_name  TYPE zif_gg_selection_screen_types=>ty_name
        iv_value TYPE string OPTIONAL
        is_range TYPE zif_gg_selection_screen_types=>ty_range OPTIONAL.

ENDCLASS.

CLASS zcl_gg_host_screen IMPLEMENTATION.

  METHOD get_values.
    rt_values = mt_values.
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

  METHOD zif_gg_selection_screen_builder_v1~add_parameter.
    add_value(
      iv_name  = is_parameter-name
      iv_value = is_parameter-default ).
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_checkbox.
    add_value(
      iv_name  = is_checkbox-name
      iv_value = CONV string( is_checkbox-default ) ).
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_radiobutton.
    add_value(
      iv_name  = is_radiobutton-name
      iv_value = CONV string( is_radiobutton-default ) ).
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_listbox.
    add_value(
      iv_name  = is_listbox-name
      iv_value = is_listbox-default ).
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_select_option.
    add_value(
      iv_name  = is_select_option-name
      is_range = is_select_option-default ).
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_pushbutton.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_comment.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_uline.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_skip.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~new_line.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~set_position.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_function_key.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~begin_block.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~end_block.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~begin_line.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~end_line.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~begin_tabbed_block.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~add_tab.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~end_tabbed_block.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~begin_screen.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_selection_screen_builder_v1~end_screen.
    RETURN.
  ENDMETHOD.

ENDCLASS.
