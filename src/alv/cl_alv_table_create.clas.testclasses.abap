CLASS ltcl_alv_table_create DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS returns_safe_table_reference FOR TESTING.
ENDCLASS.

CLASS ltcl_alv_table_create IMPLEMENTATION.
  METHOD returns_safe_table_reference.
    DATA lr_table TYPE REF TO data.
    DATA lv_style TYPE lvc_fname.
    cl_alv_table_create=>create_dynamic_table(
      EXPORTING
        i_style_table   = 'X'
        it_fieldcatalog = VALUE lvc_t_fcat( ( fieldname = 'CARRIER' ) )
      IMPORTING
        ep_table        = lr_table
        e_style_fname   = lv_style ).
    cl_abap_unit_assert=>assert_bound( act = lr_table ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_style
      exp = 'STYLE' ).
  ENDMETHOD.
ENDCLASS.
