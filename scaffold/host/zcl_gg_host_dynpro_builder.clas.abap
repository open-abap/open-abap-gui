CLASS zcl_gg_host_dynpro_builder DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_builder_v1.

    TYPES ty_screens TYPE STANDARD TABLE OF zif_gg_dynpro_types_v1=>ty_screen
      WITH DEFAULT KEY.

    METHODS get_screens
      RETURNING
        VALUE(rt_screens) TYPE ty_screens.

  PRIVATE SECTION.
    DATA mt_screens TYPE ty_screens.

ENDCLASS.

CLASS zcl_gg_host_dynpro_builder IMPLEMENTATION.

  METHOD get_screens.
    rt_screens = mt_screens.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~begin_screen.
    APPEND is_screen TO mt_screens.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_input_field.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_output_field.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_text.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_pushbutton.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_checkbox.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_radiobutton.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_listbox.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_box.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_subscreen_area.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_custom_control.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_tabstrip.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_tab.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~begin_table_control.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~add_table_column.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~end_table_control.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_dynpro_builder_v1~end_screen.
    RETURN.
  ENDMETHOD.

ENDCLASS.
