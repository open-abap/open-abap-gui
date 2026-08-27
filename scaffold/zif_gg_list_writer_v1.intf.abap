INTERFACE zif_gg_list_writer_v1 PUBLIC.

* Command sink for classic list output. Calls are processed in order, like
* their WRITE, FORMAT and list-layout statement counterparts.

  METHODS write_field
    IMPORTING
      is_field TYPE zif_gg_list_processing_types_v1=>ty_write_field.

  METHODS write_checkbox
    IMPORTING
      is_checkbox TYPE zif_gg_list_processing_types_v1=>ty_write_checkbox.

  METHODS write_icon
    IMPORTING
      is_icon TYPE zif_gg_list_processing_types_v1=>ty_write_icon.

  METHODS write_symbol
    IMPORTING
      is_symbol TYPE zif_gg_list_processing_types_v1=>ty_write_symbol.

  METHODS new_line.

  METHODS skip
    IMPORTING
      iv_lines TYPE i DEFAULT 1.

  METHODS uline
    IMPORTING
      is_uline TYPE zif_gg_list_processing_types_v1=>ty_uline.

  METHODS set_position
    IMPORTING
      iv_position TYPE i.

  METHODS reserve
    IMPORTING
      iv_lines TYPE i.

  METHODS set_blank_lines
    IMPORTING
      iv_enabled TYPE abap_bool.

  METHODS new_page
    IMPORTING
      is_new_page TYPE zif_gg_list_processing_types_v1=>ty_new_page.

  METHODS set_format
    IMPORTING
      is_format TYPE zif_gg_list_processing_types_v1=>ty_format.

  METHODS reset_format.

ENDINTERFACE.
