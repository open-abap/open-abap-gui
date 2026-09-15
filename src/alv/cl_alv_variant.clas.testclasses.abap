CLASS ltcl_alv_support DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS keeps_variant_metadata FOR TESTING.
    METHODS records_changed_cells FOR TESTING.
ENDCLASS.

CLASS ltcl_alv_support IMPLEMENTATION.
  METHOD keeps_variant_metadata.
    DATA lt_fieldcatalog TYPE lvc_t_fcat.
    DATA lt_result TYPE lvc_t_fcat.

    APPEND VALUE #( fieldname = 'CARRIER' coltext = 'Carrier' ) TO lt_fieldcatalog.
    DATA(lo_variant) = NEW cl_alv_variant( it_fieldcatalog = lt_fieldcatalog ).
    lo_variant->get_variant_info_from_db(
      EXPORTING
        is_variant = VALUE #( report = 'LOCAL' )
      IMPORTING
        et_fcat    = lt_result ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( lt_result )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = lt_result[ 1 ]-fieldname
      exp = 'CARRIER' ).
  ENDMETHOD.

  METHOD records_changed_cells.
    DATA lv_value TYPE string.
    DATA lo_protocol TYPE REF TO cl_alv_changed_data_protocol.

    lo_protocol = NEW cl_alv_changed_data_protocol( ).
    lo_protocol->modify_cell(
      i_row_id    = 2
      i_fieldname = 'NOTE'
      i_value     = 'changed' ).
    lo_protocol->modify_style(
      i_row_id    = 2
      i_fieldname = 'NOTE'
      i_style     = '0001' ).
    lo_protocol->get_cell_value(
      EXPORTING
        i_row_id    = 2
        i_fieldname = 'NOTE'
      IMPORTING
        e_value     = lv_value ).
    lo_protocol->add_protocol_entry(
      i_msgid     = '00'
      i_msgty     = 'E'
      i_msgno     = '001'
      i_fieldname = 'NOTE'
      i_row_id    = 2 ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_value
      exp = 'changed' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( lo_protocol->mt_mod_cells )
      exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( lo_protocol->mt_protocol )
      exp = 1 ).
  ENDMETHOD.
ENDCLASS.
