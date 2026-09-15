CLASS ltcl_gui_object DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS reports_control_lifetime FOR TESTING.
ENDCLASS.

CLASS ltcl_gui_object IMPLEMENTATION.
  METHOD reports_control_lifetime.
    DATA lv_valid TYPE i.

    cl_gui_control=>clear( ).
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'VALIDITY' ).
    lo_container->is_valid( IMPORTING result = lv_valid ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_valid
      exp = 1 ).
    lo_container->free( ).
    lo_container->is_valid( IMPORTING result = lv_valid ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_valid
      exp = 0 ).
  ENDMETHOD.
ENDCLASS.
