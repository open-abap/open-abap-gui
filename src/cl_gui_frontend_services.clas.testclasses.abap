CLASS ltcl_gui_frontend_services DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS browser_boundary_is_safe FOR TESTING.
    METHODS clipboard_roundtrip FOR TESTING.
ENDCLASS.

CLASS ltcl_gui_frontend_services IMPLEMENTATION.
  METHOD clipboard_roundtrip.
    DATA(lo_host) = NEW zcl_gg_host_compatibility( ).
    DATA lv_rc TYPE i.
    DATA lt_text TYPE string_table.
    lo_host->zif_gg_compatibility_v1~set_popup_request( iv_action = 'CLIPBOARD:OK'
      it_values                                                   = VALUE #( ( name = 'CONTENT' value = |first\r\nsecond  | ) ) ).
    cl_gui_frontend_services=>clipboard_import( IMPORTING data = lt_text length = DATA(lv_lines) ).
    cl_abap_unit_assert=>assert_equals( act = lv_lines
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_text[ 2 ]
                                        exp = `second  ` ).
    cl_gui_frontend_services=>clipboard_export( IMPORTING data = lt_text CHANGING rc = lv_rc ).
    cl_abap_unit_assert=>assert_equals( act = lv_rc
                                        exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = lines( lt_text )
                                        exp = 2 ).
    DATA(lt_actions) = lo_host->get_downloads( ).
    cl_abap_unit_assert=>assert_true( lt_actions[ 1 ]-clipboard ).
    cl_abap_unit_assert=>assert_equals( act = cl_abap_codepage=>convert_from( lt_actions[ 1 ]-content )
      exp                                   = |first\r\nsecond  | ).
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
