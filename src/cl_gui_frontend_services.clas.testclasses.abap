CLASS ltcl_gui_frontend_services DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS browser_boundary_is_safe FOR TESTING.
ENDCLASS.

CLASS ltcl_gui_frontend_services IMPLEMENTATION.
  METHOD browser_boundary_is_safe.
    DATA lv_separator TYPE string.
    DATA lv_platform TYPE i.
    DATA lv_directory TYPE string.
    DATA lv_file TYPE string.
    DATA lt_data TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    cl_gui_frontend_services=>get_file_separator( CHANGING file_separator = lv_separator ).
    lv_platform = cl_gui_frontend_services=>get_platform( ).
    cl_abap_unit_assert=>assert_equals( act = lv_separator
                                        exp = '/' ).
    cl_abap_unit_assert=>assert_equals( act = lv_platform
                                        exp = 0 ).
    cl_abap_unit_assert=>assert_false( act = cl_gui_frontend_services=>directory_exist( lv_directory ) ).
    cl_abap_unit_assert=>assert_false( act = cl_gui_frontend_services=>file_exist( lv_file ) ).

    cl_gui_frontend_services=>gui_download(
      EXPORTING
        filename = '/browser-only'
      CHANGING
        data_tab = lt_data ).
    cl_abap_unit_assert=>assert_initial( act = lt_data ).
  ENDMETHOD.
ENDCLASS.
