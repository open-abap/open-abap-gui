* Behaviour on a screen needs the host's compatibility layer; those tests are
* in framework/host/zcl_gg_host_compatibility.clas.testclasses.abap.
CLASS ltcl_gui_frontend_services DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS browser_boundary_is_safe FOR TESTING.
    METHODS execute_needs_a_screen FOR TESTING.
ENDCLASS.

CLASS ltcl_gui_frontend_services IMPLEMENTATION.
  METHOD execute_needs_a_screen.
* Outside a screen nothing would reach a browser.
    cl_gui_frontend_services=>execute(
      EXPORTING
        document               = `https://example.com/`
      EXCEPTIONS
        cntl_error             = 1
        error_no_gui           = 2
        bad_parameter          = 3
        file_not_found         = 4
        path_not_found         = 5
        file_extension_unknown = 6
        error_execute_failed   = 7
        synchronous_failed     = 8
        not_supported_by_gui   = 9
        OTHERS                 = 10 ).
    cl_abap_unit_assert=>assert_subrc( exp = 2 ).
  ENDMETHOD.

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

* Outside a screen there is no frontend to transfer a file to, and the data
* stays the program's.
    APPEND `line` TO lt_data.
    cl_gui_frontend_services=>gui_download(
      EXPORTING
        filename             = '/browser-only'
      CHANGING
        data_tab             = lt_data
      EXCEPTIONS
        not_supported_by_gui = 1
        OTHERS               = 2 ).
    cl_abap_unit_assert=>assert_subrc( exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_data )
                                        exp = 1 ).
  ENDMETHOD.
ENDCLASS.
