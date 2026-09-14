CLASS ltcl_gg_gp_pres DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS reports_native_boundary FOR TESTING.
ENDCLASS.

CLASS ltcl_gg_gp_pres IMPLEMENTATION.

  METHOD reports_native_boundary.
    DATA lo_proxy TYPE REF TO cl_gui_gp_pres.
    DATA lv_retval TYPE symsgno.
    DATA lv_html TYPE string.
    cl_gui_control=>clear( ).
    lo_proxy = NEW cl_gui_gp_pres( ).
    lo_proxy->if_graphic_proxy~activate( IMPORTING retval = lv_retval ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_retval
      exp = '004' ).
    lv_html = cl_gui_control=>render_html( iv_document = abap_false ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'GP_PRES' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'activate was not performed' ) ).
    cl_gui_control=>clear( ).
  ENDMETHOD.

ENDCLASS.
