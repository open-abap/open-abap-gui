* A request and its response, as the ICF layer hands them to the handler:
* header fields, form fields and a body.
CLASS ltcl_entity DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES if_http_request PARTIALLY IMPLEMENTED.
    INTERFACES if_http_response PARTIALLY IMPLEMENTED.

    DATA mt_headers TYPE tihttpnvp.
    DATA mt_fields TYPE tihttpnvp.
    DATA mv_method TYPE string.
    DATA mv_cdata TYPE string.
    DATA mv_status TYPE i.

ENDCLASS.

CLASS ltcl_entity IMPLEMENTATION.

  METHOD if_http_entity~get_header_field.
    READ TABLE mt_headers INTO DATA(ls_header) WITH KEY name = to_lower( name ).
    IF sy-subrc = 0.
      value = ls_header-value.
    ENDIF.
  ENDMETHOD.

  METHOD if_http_entity~set_header_field.
    DELETE mt_headers WHERE name = to_lower( name ).
    INSERT VALUE #( name  = to_lower( name )
                    value = value ) INTO TABLE mt_headers.
  ENDMETHOD.

  METHOD if_http_entity~get_form_fields_cs.
    fields = mt_fields.
  ENDMETHOD.

  METHOD if_http_entity~get_cdata.
    data = mv_cdata.
  ENDMETHOD.

  METHOD if_http_entity~set_cdata.
    mv_cdata = data.
  ENDMETHOD.

  METHOD if_http_entity~set_content_type.
    if_http_entity~set_header_field( name  = 'content-type'
                                     value = content_type ).
  ENDMETHOD.

  METHOD if_http_request~get_method.
    meth = mv_method.
  ENDMETHOD.

  METHOD if_http_response~set_status.
    mv_status = code.
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_server DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES if_http_server PARTIALLY IMPLEMENTED.

ENDCLASS.

CLASS ltcl_server IMPLEMENTATION.
ENDCLASS.

CLASS ltcl_mount DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS c_base TYPE string VALUE '/mount/gui'.

    DATA mo_request TYPE REF TO ltcl_entity.
    DATA mo_response TYPE REF TO ltcl_entity.

    CLASS-METHODS class_teardown.
    METHODS teardown.
    METHODS run
      IMPORTING
        iv_method      TYPE string DEFAULT 'GET'
        iv_path        TYPE string
        iv_info        TYPE string OPTIONAL
        iv_query       TYPE string OPTIONAL
        iv_window      TYPE string OPTIONAL
        it_fields      TYPE tihttpnvp OPTIONAL
      RETURNING
        VALUE(rv_html) TYPE string.

    METHODS shell_at_the_root FOR TESTING.
    METHODS shell_without_path_info FOR TESTING.
    METHODS shell_below_a_mount FOR TESTING.
    METHODS workbench_below_a_mount FOR TESTING.
    METHODS transaction_below_a_mount FOR TESTING.
    METHODS unsafe_mount_is_not_echoed FOR TESTING.
    METHODS mount_of_another_host FOR TESTING.

ENDCLASS.

CLASS ltcl_mount IMPLEMENTATION.

  METHOD class_teardown.
    zcl_gg_http_handler=>shutdown( ).
  ENDMETHOD.

  METHOD teardown.
    zcl_gg_host_windows=>clear( ).
    zcl_gg_host_runtime=>restore_gui_state( ).
  ENDMETHOD.

* One request through the handler: ~path is the whole path, ~path_info the
* part below the service's node, as the ICF layer sets them.
  METHOD run.
    mo_request = NEW #( ).
    mo_response = NEW #( ).
    mo_request->mv_method = iv_method.
    mo_request->mt_fields = it_fields.
    mo_request->if_http_entity~set_header_field( name  = '~path'
                                                 value = iv_path ).
    IF iv_info IS SUPPLIED.
      mo_request->if_http_entity~set_header_field( name  = '~path_info'
                                                   value = iv_info ).
    ENDIF.
    mo_request->if_http_entity~set_header_field(
      name  = '~request_uri'
      value = iv_path && COND string( WHEN iv_query IS NOT INITIAL THEN |?{ iv_query }| ) ).
    IF iv_window IS NOT INITIAL.
      mo_request->if_http_entity~set_header_field( name  = 'x-gg-window'
                                                   value = iv_window ).
    ENDIF.

    DATA(lo_server) = NEW ltcl_server( ).
    lo_server->if_http_server~request = mo_request.
    lo_server->if_http_server~response = mo_response.
    NEW zcl_gg_http_handler( )->if_http_extension~handle_request( lo_server ).
    rv_html = mo_response->mv_cdata.
  ENDMETHOD.

* At the root of the server the shell asks for the routes as it always has.
  METHOD shell_at_the_root.
    DATA(lv_html) = run( iv_path = '/'
                         iv_info = '/' ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<div id="gg-frames"></div>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'var BASE = "";' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS c_base ) ).
  ENDMETHOD.

* A host that sets no ~path_info routes on ~path, as before.
  METHOD shell_without_path_info.
    DATA(lv_html) = run( iv_path = '/' ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<div id="gg-frames"></div>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'var BASE = "";' ) ).
  ENDMETHOD.

* Below a node the handler routes on ~path_info, and the shell's own requests
* go to the node, read from the request.
  METHOD shell_below_a_mount.
    DATA(lv_html) = run( iv_path = |{ c_base }/|
                         iv_info = '/' ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<div id="gg-frames"></div>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS |var BASE = "{ c_base }";| ) ).
  ENDMETHOD.

  METHOD workbench_below_a_mount.
    DATA(lv_html) = run( iv_path   = |{ c_base }/|
                         iv_info   = '/'
                         iv_window = zcl_gg_host_windows=>c_new_window ).

    cl_abap_unit_assert=>assert_equals( act = mo_response->mv_status
                                        exp = 200 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS |href="{ c_base }/transaction?tcode=| ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS |action="{ c_base }/transaction"| ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'href="/transaction' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'action="/transaction"' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'action="/dispatch"' ) ).
  ENDMETHOD.

* A transaction started below the node posts its screen back below the node.
  METHOD transaction_below_a_mount.
    DATA(lv_html) = run( iv_path   = |{ c_base }/transaction|
                         iv_info   = '/transaction'
                         iv_query  = 'tcode=ZGG_EX_001'
                         iv_window = zcl_gg_host_windows=>c_new_window
                         it_fields = VALUE #( ( name = 'tcode' value = 'ZGG_EX_001' ) ) ).

    cl_abap_unit_assert=>assert_equals( act = mo_response->mv_status
                                        exp = 200 ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS |action="{ c_base }/dispatch"| ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'action="/dispatch"' ) ).
  ENDMETHOD.

* A mount that is not a plain URL path is not written into a page or a script.
  METHOD unsafe_mount_is_not_echoed.
    DATA(lv_html) = run( iv_path = '/x"y/'
                         iv_info = '/' ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<div id="gg-frames"></div>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'var BASE = "";' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS 'x"y' ) ).
  ENDMETHOD.

* A mount that starts with // would make every link a URL of another host.
  METHOD mount_of_another_host.
    DATA(lv_html) = run( iv_path = '//mount/gui/'
                         iv_info = '/' ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '<div id="gg-frames"></div>' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'var BASE = "";' ) ).
  ENDMETHOD.

ENDCLASS.
