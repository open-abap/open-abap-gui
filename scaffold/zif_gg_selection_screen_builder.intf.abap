INTERFACE zif_gg_selection_screen_builder PUBLIC.

* Command sink used to describe a selection screen. Separate methods make
* invalid combinations of kind-specific additions unrepresentable.

  METHODS add_parameter
    IMPORTING
      is_parameter TYPE zif_gg_selection_screen_types=>ty_parameter.

  METHODS add_checkbox
    IMPORTING
      is_checkbox TYPE zif_gg_selection_screen_types=>ty_checkbox.

  METHODS add_radiobutton
    IMPORTING
      is_radiobutton TYPE zif_gg_selection_screen_types=>ty_radiobutton.

  METHODS add_listbox
    IMPORTING
      is_listbox TYPE zif_gg_selection_screen_types=>ty_listbox.

  METHODS add_select_option
    IMPORTING
      is_select_option TYPE zif_gg_selection_screen_types=>ty_select_option.

  METHODS add_pushbutton
    IMPORTING
      is_pushbutton TYPE zif_gg_selection_screen_types=>ty_pushbutton.

  METHODS add_comment
    IMPORTING
      is_comment TYPE zif_gg_selection_screen_types=>ty_comment.

  METHODS add_uline
    IMPORTING
      is_uline TYPE zif_gg_selection_screen_types=>ty_uline.

  METHODS add_skip
    IMPORTING
      iv_lines TYPE i DEFAULT 1.

  METHODS new_line.

  METHODS set_position
    IMPORTING
      iv_position TYPE i.

  METHODS add_function_key
    IMPORTING
      is_function_key TYPE zif_gg_selection_screen_types=>ty_function_key.

  METHODS begin_block
    IMPORTING
      is_block TYPE zif_gg_selection_screen_types=>ty_block.

  METHODS end_block.

  METHODS begin_line.

  METHODS end_line.

  METHODS begin_tabbed_block
    IMPORTING
      is_tabbed_block TYPE zif_gg_selection_screen_types=>ty_tabbed_block.

  METHODS add_tab
    IMPORTING
      is_tab TYPE zif_gg_selection_screen_types=>ty_tab.

  METHODS end_tabbed_block.

  METHODS begin_screen
    IMPORTING
      is_screen TYPE zif_gg_selection_screen_types=>ty_screen.

  METHODS end_screen.

ENDINTERFACE.
