INTERFACE zif_gg_dynpro_builder_v1 PUBLIC.

* Typed command sink for one or more classic dynpros. Controls added between
* begin_screen and end_screen belong to that screen and retain call order.

  METHODS begin_screen
    IMPORTING
      is_screen TYPE zif_gg_dynpro_types_v1=>ty_screen.

  METHODS add_input_field
    IMPORTING
      is_input_field TYPE zif_gg_dynpro_types_v1=>ty_input_field.

  METHODS add_output_field
    IMPORTING
      is_output_field TYPE zif_gg_dynpro_types_v1=>ty_output_field.

  METHODS add_text
    IMPORTING
      is_text TYPE zif_gg_dynpro_types_v1=>ty_text.

  METHODS add_pushbutton
    IMPORTING
      is_pushbutton TYPE zif_gg_dynpro_types_v1=>ty_pushbutton.

  METHODS add_checkbox
    IMPORTING
      is_checkbox TYPE zif_gg_dynpro_types_v1=>ty_checkbox.

  METHODS add_radiobutton
    IMPORTING
      is_radiobutton TYPE zif_gg_dynpro_types_v1=>ty_radiobutton.

  METHODS add_listbox
    IMPORTING
      is_listbox TYPE zif_gg_dynpro_types_v1=>ty_listbox.

  METHODS add_box
    IMPORTING
      is_box TYPE zif_gg_dynpro_types_v1=>ty_box.

  METHODS add_subscreen_area
    IMPORTING
      is_subscreen_area TYPE zif_gg_dynpro_types_v1=>ty_subscreen_area.

  METHODS add_custom_control
    IMPORTING
      is_custom_control TYPE zif_gg_dynpro_types_v1=>ty_custom_control.

  METHODS add_tabstrip
    IMPORTING
      is_tabstrip TYPE zif_gg_dynpro_types_v1=>ty_tabstrip.

  METHODS add_tab
    IMPORTING
      is_tab TYPE zif_gg_dynpro_types_v1=>ty_tab.

  METHODS begin_table_control
    IMPORTING
      is_table_control TYPE zif_gg_dynpro_types_v1=>ty_table_control.

  METHODS add_table_column
    IMPORTING
      is_table_column TYPE zif_gg_dynpro_types_v1=>ty_table_column.

  METHODS end_table_control.

  METHODS end_screen.

ENDINTERFACE.
