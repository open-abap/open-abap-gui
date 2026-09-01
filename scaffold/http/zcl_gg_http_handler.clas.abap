CLASS zcl_gg_http_handler DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_http_extension.

    CLASS-METHODS shutdown.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_payload,
             session_id    TYPE string,
             page_id       TYPE string,
             action        TYPE string,
             gg_action     TYPE string,
             ucomm         TYPE string,
             gg_ucomm      TYPE string,
             target        TYPE string,
             value         TYPE string,
             row           TYPE i,
             pf_key        TYPE i,
             token         TYPE string,
             gg_token      TYPE string,
             cursor_field  TYPE string,
             cursor_value  TYPE string,
             values        TYPE zif_gg_selection_screen_types=>ty_values,
             dynpro_values TYPE zif_gg_dynpro_types_v1=>ty_values,
           END OF ty_payload.

    TYPES: BEGIN OF ty_error_response,
             valid TYPE abap_bool,
             error TYPE string,
           END OF ty_error_response.

    CLASS-DATA mv_database_ready TYPE abap_bool.

    CLASS-METHODS handle_get
      IMPORTING
        server TYPE REF TO if_http_server.

    CLASS-METHODS handle_post
      IMPORTING
        server TYPE REF TO if_http_server.

    CLASS-METHODS handle_delete
      IMPORTING
        server TYPE REF TO if_http_server.

    CLASS-METHODS request_from_http
      IMPORTING
        server            TYPE REF TO if_http_server
      RETURNING
        VALUE(rs_request) TYPE zif_gg_host_html_v1=>ty_request.

    CLASS-METHODS request_from_payload
      IMPORTING
        is_payload        TYPE ty_payload
      RETURNING
        VALUE(rs_request) TYPE zif_gg_host_html_v1=>ty_request.

    CLASS-METHODS request_from_form
      IMPORTING
        server            TYPE REF TO if_http_server
      RETURNING
        VALUE(rs_request) TYPE zif_gg_host_html_v1=>ty_request.

    CLASS-METHODS form_value
      IMPORTING
        it_fields       TYPE tihttpnvp
        iv_name         TYPE string
      RETURNING
        VALUE(rv_value) TYPE string.

    CLASS-METHODS values_from_fields
      IMPORTING
        it_fields        TYPE tihttpnvp
      RETURNING
        VALUE(rt_values) TYPE zif_gg_selection_screen_types=>ty_values.

    CLASS-METHODS dynpro_from_fields
      IMPORTING
        it_fields        TYPE tihttpnvp
      RETURNING
        VALUE(rt_values) TYPE zif_gg_dynpro_types_v1=>ty_values.

    CLASS-METHODS add_dynpro_value
      IMPORTING
        iv_container TYPE string
        iv_name      TYPE string
        iv_row       TYPE i
        iv_value     TYPE string
      CHANGING
        ct_values    TYPE zif_gg_dynpro_types_v1=>ty_values.

    CLASS-METHODS ensure_database.

    CLASS-METHODS start_program
      IMPORTING
        io_report          TYPE REF TO zif_gg_report_v1 OPTIONAL
        io_dynpro          TYPE REF TO zif_gg_dynpro_v1 OPTIONAL
      RETURNING
        VALUE(rs_response) TYPE zif_gg_host_html_v1=>ty_response.

    CLASS-METHODS create_transaction
      IMPORTING
        is_transaction   TYPE zcl_gg_transaction_registry=>ty_transaction
      RETURNING
        VALUE(ro_object) TYPE REF TO object.

    CLASS-METHODS launch_transaction
      IMPORTING
        is_transaction     TYPE zcl_gg_transaction_registry=>ty_transaction
        io_object          TYPE REF TO object OPTIONAL
      RETURNING
        VALUE(rs_response) TYPE zif_gg_host_html_v1=>ty_response.

    CLASS-METHODS helper_html
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS send_runtime_response
      IMPORTING
        server      TYPE REF TO if_http_server
        is_response TYPE zif_gg_host_html_v1=>ty_response.

    CLASS-METHODS send_html
      IMPORTING
        server    TYPE REF TO if_http_server
        iv_html   TYPE string
        iv_status TYPE i DEFAULT 200.

    CLASS-METHODS send_error
      IMPORTING
        server    TYPE REF TO if_http_server
        iv_error  TYPE string
        iv_status TYPE i DEFAULT 400.

    CLASS-METHODS send_workbench_error
      IMPORTING
        server        TYPE REF TO if_http_server
        iv_error      TYPE string
        iv_session_id TYPE string OPTIONAL
        iv_page_id    TYPE string OPTIONAL
        iv_status     TYPE i DEFAULT 200.

    CLASS-METHODS send_empty
      IMPORTING
        server    TYPE REF TO if_http_server
        iv_status TYPE i.

    CLASS-METHODS send_method_not_allowed
      IMPORTING
        server TYPE REF TO if_http_server.

    CLASS-METHODS send_not_found
      IMPORTING
        server TYPE REF TO if_http_server.
ENDCLASS.

CLASS zcl_gg_http_handler IMPLEMENTATION.

  METHOD if_http_extension~handle_request.
    DATA lv_method TYPE string.

    TRY.
        lv_method = server->request->get_method( ).
        TRANSLATE lv_method TO UPPER CASE.
        CASE lv_method.
          WHEN 'GET'.
            handle_get( server ).
          WHEN 'POST'.
            handle_post( server ).
          WHEN 'DELETE'.
            handle_delete( server ).
          WHEN 'OPTIONS'.
            server->response->set_header_field(
              name  = 'allow'
              value = 'GET, POST, DELETE, OPTIONS' ).
            send_empty( server    = server
                        iv_status = 204 ).
          WHEN OTHERS.
            send_method_not_allowed( server ).
        ENDCASE.
      CATCH zcx_gg_transaction_error INTO DATA(lx_transaction_error).
        send_workbench_error(
          server    = server
          iv_error  = lx_transaction_error->mv_message
          iv_status = 500 ).
      CATCH cx_root INTO DATA(lx_error).
        send_error(
          server   = server
          iv_error = lx_error->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD handle_get.
    DATA lv_path   TYPE string.
    DATA lv_tcode  TYPE string.
    DATA lt_fields TYPE tihttpnvp.
    DATA lt_transactions TYPE zcl_gg_transaction_registry=>ty_transactions.
    DATA ls_response TYPE zif_gg_host_html_v1=>ty_response.
    DATA lo_workbench TYPE REF TO zif_gg_raw_html_v1.
    DATA lv_class_name TYPE string.
    DATA ls_transaction TYPE zcl_gg_transaction_registry=>ty_transaction.

    lv_path = server->request->get_header_field( '~path' ).
    IF lv_path = '/'.
      lo_workbench = NEW zcl_gg_workbench( ).
      send_html( server  = server
                 iv_html = lo_workbench->get_html( ) ).
      RETURN.
    ENDIF.
    IF lv_path = '/transaction'.
      server->request->get_form_fields_cs( CHANGING fields = lt_fields ).
      lv_tcode = form_value( it_fields = lt_fields
                             iv_name   = 'tcode' ).
      ls_transaction = zcl_gg_transaction_registry=>lookup( iv_tcode = lv_tcode ).
      IF ls_transaction-tcode IS INITIAL.
        send_workbench_error(
          server   = server
          iv_error = |Unknown transaction code: { lv_tcode }| ).
        RETURN.
      ENDIF.
      TRY.
          ls_response = launch_transaction( is_transaction = ls_transaction ).
        CATCH zcx_gg_transaction_error INTO DATA(lx_launch_error).
          send_workbench_error(
            server    = server
            iv_error  = lx_launch_error->mv_message
            iv_status = 500 ).
          RETURN.
      ENDTRY.
      IF ls_response-valid = abap_false.
        send_workbench_error(
          server    = server
          iv_error  = ls_response-error
          iv_status = 500 ).
        RETURN.
      ENDIF.
      send_runtime_response( server      = server
                             is_response = ls_response ).
      RETURN.
    ENDIF.
    IF lv_path = '/ZCL_GG_DB_HELPER'.
      send_html( server  = server
                 iv_html = helper_html( ) ).
      RETURN.
    ENDIF.

    lv_class_name = substring( val = lv_path
                               off = 1 ).
    TRANSLATE lv_class_name TO UPPER CASE.
    CASE lv_class_name.
      WHEN 'ZCL_GG_INTEGRATION_HTML_REPORT'.
        ls_response = start_program( io_report = NEW zcl_gg_integration_html_report( ) ).
      WHEN 'ZCL_GG_INTEGRATION_DYNPRO'.
        ls_response = start_program( io_dynpro = NEW zcl_gg_integration_dynpro( ) ).
      WHEN OTHERS.
        lt_transactions = zcl_gg_transaction_registry=>get_all( ).
        READ TABLE lt_transactions INTO ls_transaction
          WITH KEY class_name = lv_class_name.
        IF sy-subrc <> 0.
          send_not_found( server ).
          RETURN.
        ENDIF.
        ls_response = launch_transaction( is_transaction = ls_transaction ).
    ENDCASE.
    send_runtime_response( server      = server
                           is_response = ls_response ).
  ENDMETHOD.

  METHOD handle_post.
    DATA lv_path TYPE string.
    DATA lv_content_type TYPE string.
    DATA lv_cdata TYPE string.
    DATA lv_command TYPE string.
    DATA lv_session_id TYPE string.
    DATA lv_page_id TYPE string.
    DATA lv_close_error TYPE string.
    DATA lt_fields TYPE tihttpnvp.
    DATA lt_body_fields TYPE tihttpnvp.
    DATA ls_command TYPE zcl_gg_transaction_command=>ty_result.
    DATA ls_transaction TYPE zcl_gg_transaction_registry=>ty_transaction.
    DATA lo_transaction TYPE REF TO object.
    DATA ls_response TYPE zif_gg_host_html_v1=>ty_response.

    lv_path = server->request->get_header_field( '~path' ).
    IF lv_path = '/transaction'.
      lv_content_type = server->request->get_header_field( 'content-type' ).
      IF lv_content_type IS NOT INITIAL AND lv_content_type NP 'application/x-www-form-urlencoded*'.
        send_workbench_error(
          server    = server
          iv_error  = 'The transaction command requires form content.'
          iv_status = 415 ).
        RETURN.
      ENDIF.
      server->request->get_form_fields_cs( CHANGING fields = lt_fields ).
      IF lv_content_type CS 'application/x-www-form-urlencoded'.
        lv_cdata = server->request->get_cdata( ).
        lt_body_fields = cl_http_utility=>string_to_fields( lv_cdata ).
        APPEND LINES OF lt_body_fields TO lt_fields.
      ENDIF.
      lv_command = form_value( it_fields = lt_fields
                               iv_name   = 'command' ).
      lv_session_id = form_value( it_fields = lt_fields
                                  iv_name   = 'session_id' ).
      lv_page_id = form_value( it_fields = lt_fields
                               iv_name   = 'page_id' ).
      ls_command = zcl_gg_transaction_command=>parse( iv_command = lv_command ).
      IF ls_command-valid = abap_false.
        send_workbench_error(
          server        = server
          iv_session_id = lv_session_id
          iv_page_id    = lv_page_id
          iv_error      = ls_command-error ).
        RETURN.
      ENDIF.
      ls_transaction = zcl_gg_transaction_registry=>lookup( iv_tcode = CONV string( ls_command-tcode ) ).
      IF ls_transaction-tcode IS INITIAL.
        send_workbench_error(
          server        = server
          iv_session_id = lv_session_id
          iv_page_id    = lv_page_id
          iv_error      = |Unknown transaction code: { ls_command-tcode }| ).
        RETURN.
      ENDIF.
      TRY.
          lo_transaction = create_transaction( is_transaction = ls_transaction ).
        CATCH zcx_gg_transaction_error INTO DATA(lx_target_error).
          send_workbench_error(
            server        = server
            iv_session_id = lv_session_id
            iv_page_id    = lv_page_id
            iv_error      = lx_target_error->mv_message
            iv_status     = 500 ).
          RETURN.
      ENDTRY.
      IF lv_session_id IS INITIAL AND lv_page_id IS INITIAL.
        CLEAR lv_close_error.
      ELSEIF lv_session_id IS INITIAL OR lv_page_id IS INITIAL.
        lv_close_error = 'Both the current host session and page are required.'.
      ELSE.
        lv_close_error = zcl_gg_host_runtime=>close_current(
          iv_session_id = lv_session_id
          iv_page_id    = lv_page_id ).
      ENDIF.
      IF lv_close_error IS NOT INITIAL.
        send_workbench_error(
          server        = server
          iv_session_id = lv_session_id
          iv_page_id    = lv_page_id
          iv_error      = lv_close_error
          iv_status     = 409 ).
        RETURN.
      ENDIF.
      TRY.
          ls_response = launch_transaction(
            is_transaction = ls_transaction
            io_object      = lo_transaction ).
        CATCH zcx_gg_transaction_error INTO DATA(lx_launch_error).
          send_workbench_error(
            server        = server
            iv_session_id = lv_session_id
            iv_page_id    = lv_page_id
            iv_error      = lx_launch_error->mv_message
            iv_status     = 500 ).
          RETURN.
      ENDTRY.
      IF ls_response-valid = abap_false.
        send_workbench_error(
          server        = server
          iv_session_id = lv_session_id
          iv_page_id    = lv_page_id
          iv_error      = ls_response-error
          iv_status     = 500 ).
        RETURN.
      ENDIF.
      send_runtime_response( server      = server
                             is_response = ls_response ).
      RETURN.
    ENDIF.
    IF lv_path <> '/dispatch'.
      send_method_not_allowed( server ).
      RETURN.
    ENDIF.

    ls_response = zcl_gg_host_runtime=>dispatch( is_request = request_from_http( server ) ).
    send_runtime_response( server      = server
                           is_response = ls_response ).
  ENDMETHOD.

  METHOD handle_delete.
    DATA lv_path       TYPE string.
    DATA lv_session_id TYPE string.

    lv_path = server->request->get_header_field( '~path' ).
    IF lv_path NP '/session/*'.
      send_method_not_allowed( server ).
      RETURN.
    ENDIF.

    lv_session_id = substring( val = lv_path
                               off = 9 ).
    IF lv_session_id IS INITIAL OR lv_session_id CS '/'.
      send_method_not_allowed( server ).
      RETURN.
    ENDIF.
    lv_session_id = cl_http_utility=>unescape_url( lv_session_id ).
    zcl_gg_host_runtime=>close( lv_session_id ).
    send_empty( server    = server
                iv_status = 204 ).
  ENDMETHOD.

  METHOD request_from_http.
    DATA lv_content_type TYPE string.
    DATA lv_cdata        TYPE string.
    DATA ls_payload      TYPE ty_payload.

    lv_content_type = server->request->get_header_field( 'content-type' ).
    IF lv_content_type CS 'application/json'.
      lv_cdata = server->request->get_cdata( ).
      /ui2/cl_json=>deserialize(
        EXPORTING
          json = lv_cdata
        CHANGING
          data = ls_payload ).
      rs_request = request_from_payload( ls_payload ).
    ELSE.
      rs_request = request_from_form( server ).
    ENDIF.
  ENDMETHOD.

  METHOD request_from_form.
    DATA lv_content_type TYPE string.
    DATA lv_cdata        TYPE string.
    DATA lt_fields       TYPE tihttpnvp.
    DATA lt_body_fields  TYPE tihttpnvp.
    DATA ls_payload      TYPE ty_payload.

    server->request->get_form_fields_cs( CHANGING fields = lt_fields ).
    lv_content_type = server->request->get_header_field( 'content-type' ).
    IF lv_content_type CS 'application/x-www-form-urlencoded'.
      lv_cdata = server->request->get_cdata( ).
      lt_body_fields = cl_http_utility=>string_to_fields( lv_cdata ).
      APPEND LINES OF lt_body_fields TO lt_fields.
    ENDIF.
    ls_payload-session_id = form_value( it_fields = lt_fields
                                        iv_name   = 'session_id' ).
    ls_payload-page_id = form_value( it_fields = lt_fields
                                     iv_name   = 'page_id' ).
    ls_payload-action = form_value( it_fields = lt_fields
                                    iv_name   = 'action' ).
    ls_payload-gg_action = form_value( it_fields = lt_fields
                                       iv_name   = 'gg_action' ).
    ls_payload-ucomm = form_value( it_fields = lt_fields
                                   iv_name   = 'ucomm' ).
    ls_payload-gg_ucomm = form_value( it_fields = lt_fields
                                      iv_name   = 'gg_ucomm' ).
    ls_payload-target = form_value( it_fields = lt_fields
                                    iv_name   = 'target' ).
    ls_payload-value = form_value( it_fields = lt_fields
                                   iv_name   = 'value' ).
    ls_payload-row = CONV i( form_value( it_fields = lt_fields
                                         iv_name   = 'row' ) ).
    ls_payload-pf_key = CONV i( form_value( it_fields = lt_fields
                                            iv_name   = 'pf_key' ) ).
    ls_payload-token = form_value( it_fields = lt_fields
                                   iv_name   = 'token' ).
    ls_payload-gg_token = form_value( it_fields = lt_fields
                                      iv_name   = 'gg_token' ).
    ls_payload-cursor_field = form_value( it_fields = lt_fields
                                          iv_name   = 'cursor_field' ).
    ls_payload-cursor_value = form_value( it_fields = lt_fields
                                          iv_name   = 'cursor_value' ).
    ls_payload-values = values_from_fields( lt_fields ).
    ls_payload-dynpro_values = dynpro_from_fields( lt_fields ).
    rs_request = request_from_payload( ls_payload ).
  ENDMETHOD.

  METHOD request_from_payload.
    DATA lv_action_value TYPE string.
    DATA lv_remainder    TYPE string.
    DATA lv_first        TYPE string.
    DATA lv_second       TYPE string.
    DATA lv_target       TYPE string.

    rs_request-session_id = is_payload-session_id.
    rs_request-page_id = is_payload-page_id.
    rs_request-action = is_payload-action.
    rs_request-ucomm = is_payload-ucomm.
    rs_request-target = is_payload-target.
    rs_request-value = is_payload-value.
    rs_request-row = is_payload-row.
    rs_request-pf_key = is_payload-pf_key.
    rs_request-token = is_payload-token.
    rs_request-cursor_field = is_payload-cursor_field.
    rs_request-cursor_value = is_payload-cursor_value.
    rs_request-values = is_payload-values.
    rs_request-dynpro_values = is_payload-dynpro_values.

    IF is_payload-gg_ucomm IS NOT INITIAL.
      rs_request-ucomm = is_payload-gg_ucomm.
    ENDIF.
    lv_action_value = is_payload-action.
    IF is_payload-gg_action IS NOT INITIAL.
      lv_action_value = is_payload-gg_action.
    ENDIF.

    IF lv_action_value CP 'LINE:*'.
      rs_request-action = zif_gg_host_html_v1=>action_line.
      lv_remainder = substring( val = lv_action_value
                                off = 5 ).
      SPLIT lv_remainder AT '|' INTO lv_first lv_second.
      rs_request-row = CONV i( lv_first ).
      IF lv_second IS NOT INITIAL.
        rs_request-target = lv_second.
      ENDIF.
    ELSEIF lv_action_value CP 'VALUE_HELP:*'.
      rs_request-action = zif_gg_host_html_v1=>action_value_help.
      rs_request-target = substring( val = lv_action_value
                                     off = 11 ).
    ELSEIF lv_action_value CP 'HELP:*'.
      rs_request-action = zif_gg_host_html_v1=>action_help.
      rs_request-target = substring( val = lv_action_value
                                     off = 5 ).
    ELSEIF lv_action_value CP 'TAB:*'.
      rs_request-action = zif_gg_host_html_v1=>action_tab.
      lv_remainder = substring( val = lv_action_value
                                off = 4 ).
      SPLIT lv_remainder AT '|' INTO lv_target lv_second.
      rs_request-target = lv_target.
      IF lv_second IS NOT INITIAL.
        rs_request-ucomm = lv_second.
      ENDIF.
    ELSEIF lv_action_value CP 'SCREEN:*'.
      rs_request-action = zif_gg_host_html_v1=>action_screen.
      lv_remainder = substring( val = lv_action_value
                                off = 7 ).
      SPLIT lv_remainder AT '|' INTO lv_target lv_second.
      rs_request-target = lv_target.
      IF lv_second IS NOT INITIAL.
        rs_request-ucomm = lv_second.
      ENDIF.
    ELSEIF lv_action_value CP 'COMMAND:*'.
      rs_request-action = zif_gg_host_html_v1=>action_command.
      IF is_payload-gg_ucomm IS INITIAL.
        rs_request-ucomm = substring( val = lv_action_value
                                      off = 8 ).
      ENDIF.
    ELSEIF lv_action_value IS NOT INITIAL AND rs_request-action IS INITIAL.
      rs_request-action = lv_action_value.
    ENDIF.

    IF is_payload-gg_token IS NOT INITIAL.
      rs_request-token = is_payload-gg_token.
    ENDIF.
    IF rs_request-token IS INITIAL AND rs_request-action = zif_gg_host_html_v1=>action_line.
      rs_request-token = rs_request-target.
    ENDIF.

    IF rs_request-dynpro_values IS INITIAL AND rs_request-values IS NOT INITIAL.
      LOOP AT rs_request-values INTO DATA(ls_value).
        INSERT VALUE #(
          container = ``
          name      = CONV zif_gg_dynpro_types_v1=>ty_name( ls_value-name )
          row       = 0
          value     = ls_value-value ) INTO TABLE rs_request-dynpro_values.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD form_value.
    LOOP AT it_fields INTO DATA(ls_field) WHERE name = iv_name.
      rv_value = ls_field-value.
    ENDLOOP.
  ENDMETHOD.

  METHOD values_from_fields.
    DATA lv_name       TYPE string.
    DATA lv_suffix     TYPE string.
    DATA lv_value      TYPE string.
    DATA lv_range_index TYPE i.
    DATA lv_typed_name TYPE zif_gg_selection_screen_types=>ty_name.
    DATA lt_name_parts TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
    FIELD-SYMBOLS <ls_value> TYPE zif_gg_selection_screen_types=>ty_value.
    FIELD-SYMBOLS <ls_range> TYPE zif_gg_selection_screen_types=>ty_range.

    LOOP AT it_fields INTO DATA(ls_field).
      lv_value = ls_field-value.
      REPLACE ALL OCCURRENCES OF '+' IN lv_value WITH ` `.
      IF ls_field-name CP 'gg-radio-*'.
        lv_name = ls_field-value.
        INSERT VALUE #(
          name   = CONV zif_gg_selection_screen_types=>ty_name( lv_name )
          value  = 'X'
          ranges = VALUE #( ) ) INTO TABLE rt_values.
        CONTINUE.
      ENDIF.
      IF ls_field-name CP 'gg-cell-*'.
        CONTINUE.
      ENDIF.
      IF ls_field-name = 'session_id'
          OR ls_field-name = 'page_id'
          OR ls_field-name = 'action'
          OR ls_field-name = 'gg_action'
          OR ls_field-name = 'ucomm'
          OR ls_field-name = 'gg_ucomm'
          OR ls_field-name = 'target'
          OR ls_field-name = 'value'
          OR ls_field-name = 'row'
          OR ls_field-name = 'pf_key'
          OR ls_field-name = 'token'
          OR ls_field-name = 'gg_token'
          OR ls_field-name = 'cursor_field'
          OR ls_field-name = 'cursor_value'
          OR ls_field-name CP 'gg_*'.
        CONTINUE.
      ENDIF.

      lv_name = ls_field-name.
      CLEAR: lv_suffix, lv_range_index, lt_name_parts.
      SPLIT ls_field-name AT '-' INTO TABLE lt_name_parts.
      IF lines( lt_name_parts ) = 3
          AND lt_name_parts[ 2 ] CO '0123456789'.
        lv_name = lt_name_parts[ 1 ].
        lv_range_index = CONV i( lt_name_parts[ 2 ] ).
        lv_suffix = lt_name_parts[ 3 ].
      ELSEIF ls_field-name CP '*-LOW'.
        REPLACE FIRST OCCURRENCE OF '-LOW' IN lv_name WITH ''.
        lv_suffix = 'LOW'.
      ELSEIF ls_field-name CP '*-HIGH'.
        REPLACE FIRST OCCURRENCE OF '-HIGH' IN lv_name WITH ''.
        lv_suffix = 'HIGH'.
      ELSEIF ls_field-name CP '*-SIGN'.
        REPLACE FIRST OCCURRENCE OF '-SIGN' IN lv_name WITH ''.
        lv_suffix = 'SIGN'.
      ELSEIF ls_field-name CP '*-OPTION'.
        REPLACE FIRST OCCURRENCE OF '-OPTION' IN lv_name WITH ''.
        lv_suffix = 'OPTION'.
      ENDIF.

      lv_typed_name = CONV zif_gg_selection_screen_types=>ty_name( lv_name ).
      READ TABLE rt_values ASSIGNING <ls_value> WITH KEY name = lv_typed_name.
      IF sy-subrc <> 0.
        INSERT VALUE #(
          name   = lv_typed_name
          value  = ``
          ranges = VALUE #( ) ) INTO TABLE rt_values.
        READ TABLE rt_values ASSIGNING <ls_value> WITH KEY name = lv_typed_name.
      ENDIF.
      IF lv_suffix IS INITIAL.
        <ls_value>-value = lv_value.
      ELSE.
        IF lv_range_index = 0.
          lv_range_index = 1.
        ENDIF.
        WHILE lines( <ls_value>-ranges ) < lv_range_index.
          APPEND VALUE #(
            sign   = zif_gg_selection_screen_types=>sign_include
            option = zif_gg_selection_screen_types=>option_eq ) TO <ls_value>-ranges.
        ENDWHILE.
        READ TABLE <ls_value>-ranges ASSIGNING <ls_range> INDEX lv_range_index.
        CASE lv_suffix.
          WHEN 'LOW'.
            <ls_range>-low = lv_value.
          WHEN 'HIGH'.
            <ls_range>-high = lv_value.
          WHEN 'SIGN'.
            <ls_range>-sign = lv_value.
          WHEN 'OPTION'.
            <ls_range>-option = lv_value.
        ENDCASE.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD dynpro_from_fields.
    DATA lv_cell      TYPE string.
    DATA lv_part      TYPE string.
    DATA lv_container TYPE string.
    DATA lv_name      TYPE string.
    DATA lv_row_text  TYPE string.
    DATA lv_value     TYPE string.
    DATA lv_row       TYPE i.
    DATA lv_last      TYPE i.
    DATA lt_parts     TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    LOOP AT it_fields INTO DATA(ls_field).
      lv_value = ls_field-value.
      REPLACE ALL OCCURRENCES OF '+' IN lv_value WITH ` `.
      IF ls_field-name CP 'gg-radio-*'.
*       A radio group posts the selected control name as its value; the field
*       name only carries the group. Selecting the group would name no control.
        add_dynpro_value(
          EXPORTING
            iv_container = ``
            iv_name      = lv_value
            iv_row       = 0
            iv_value     = 'X'
          CHANGING
            ct_values    = rt_values ).
        CONTINUE.
      ENDIF.
      IF ls_field-name CP 'gg-cell-*'.
        lv_cell = substring( val = ls_field-name
                             off = 8 ).
        CLEAR lt_parts.
        SPLIT lv_cell AT '-' INTO TABLE lt_parts.
        lv_last = lines( lt_parts ).
        IF lv_last >= 2.
          READ TABLE lt_parts INDEX lv_last INTO lv_row_text.
          READ TABLE lt_parts INDEX lv_last - 1 INTO lv_name.
          lv_row = CONV i( lv_row_text ).
          CLEAR lv_container.
          LOOP AT lt_parts INTO lv_part.
            IF sy-tabix = lv_last OR sy-tabix = lv_last - 1.
              CONTINUE.
            ENDIF.
            IF lv_container IS INITIAL.
              lv_container = lv_part.
            ELSE.
              lv_container = lv_container && '-' && lv_part.
            ENDIF.
          ENDLOOP.
          add_dynpro_value(
            EXPORTING
              iv_container = lv_container
              iv_name      = lv_name
              iv_row       = lv_row
              iv_value     = lv_value
            CHANGING
              ct_values    = rt_values ).
        ENDIF.
        CONTINUE.
      ENDIF.
      IF ls_field-name = 'session_id'
          OR ls_field-name = 'page_id'
          OR ls_field-name = 'action'
          OR ls_field-name = 'gg_action'
          OR ls_field-name = 'ucomm'
          OR ls_field-name = 'gg_ucomm'
          OR ls_field-name = 'target'
          OR ls_field-name = 'value'
          OR ls_field-name = 'row'
          OR ls_field-name = 'pf_key'
          OR ls_field-name = 'token'
          OR ls_field-name = 'gg_token'
          OR ls_field-name = 'cursor_field'
          OR ls_field-name = 'cursor_value'
          OR ls_field-name CP 'gg_*'.
        CONTINUE.
      ENDIF.
      add_dynpro_value(
        EXPORTING
          iv_container = ``
          iv_name      = ls_field-name
          iv_row       = 0
          iv_value     = lv_value
        CHANGING
          ct_values    = rt_values ).
    ENDLOOP.
  ENDMETHOD.

  METHOD add_dynpro_value.
    DATA lv_container TYPE zif_gg_dynpro_types_v1=>ty_name.
    DATA lv_name      TYPE zif_gg_dynpro_types_v1=>ty_name.
    FIELD-SYMBOLS <ls_value> TYPE zif_gg_dynpro_types_v1=>ty_value.

    lv_container = CONV #( iv_container ).
    lv_name = CONV #( iv_name ).
    READ TABLE ct_values ASSIGNING <ls_value>
      WITH KEY container = lv_container name = lv_name row = iv_row.
    IF sy-subrc <> 0.
      INSERT VALUE #(
        container = lv_container
        name      = lv_name
        row       = iv_row
        value     = iv_value ) INTO TABLE ct_values.
    ELSE.
      <ls_value>-value = iv_value.
    ENDIF.
  ENDMETHOD.

  METHOD ensure_database.
    IF mv_database_ready = abap_false.
      zcl_gg_db_helper=>create( ).
      zcl_gg_db_helper=>reset( ).
      mv_database_ready = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD start_program.
    ensure_database( ).
    IF io_dynpro IS BOUND.
      rs_response = zcl_gg_host_runtime=>start( io_dynpro_program = io_dynpro ).
    ELSEIF io_report IS BOUND.
      rs_response = zcl_gg_host_runtime=>start( io_report = io_report ).
    ELSE.
      rs_response-valid = abap_false.
      rs_response-error = 'A report or dynpro program is required'.
    ENDIF.
  ENDMETHOD.

  METHOD create_transaction.
    DATA lo_report TYPE REF TO zif_gg_report_v1.
    DATA lo_dynpro TYPE REF TO zif_gg_dynpro_v1.

    TRY.
        CREATE OBJECT ro_object TYPE (is_transaction-class_name).
      CATCH cx_root INTO DATA(lx_create_error).
        RAISE EXCEPTION NEW zcx_gg_transaction_error(
          iv_message = |Unable to start transaction { is_transaction-tcode } ({ is_transaction-class_name }): { lx_create_error->get_text( ) }| ).
    ENDTRY.

    CASE is_transaction-kind.
      WHEN zcl_gg_transaction_registry=>kind_report.
        TRY.
            lo_report ?= ro_object.
          CATCH cx_root.
            RAISE EXCEPTION NEW zcx_gg_transaction_error(
              iv_message = |Transaction { is_transaction-tcode } is not a report implementation| ).
        ENDTRY.
      WHEN zcl_gg_transaction_registry=>kind_dynpro.
        TRY.
            lo_dynpro ?= ro_object.
          CATCH cx_root.
            RAISE EXCEPTION NEW zcx_gg_transaction_error(
              iv_message = |Transaction { is_transaction-tcode } is not a dynpro implementation| ).
        ENDTRY.
      WHEN OTHERS.
        RAISE EXCEPTION NEW zcx_gg_transaction_error(
          iv_message = |Transaction { is_transaction-tcode } has an unsupported executable kind| ).
    ENDCASE.
  ENDMETHOD.

  METHOD launch_transaction.
    DATA lo_object TYPE REF TO object.
    DATA lo_report TYPE REF TO zif_gg_report_v1.
    DATA lo_dynpro TYPE REF TO zif_gg_dynpro_v1.

    IF io_object IS BOUND.
      lo_object = io_object.
    ELSE.
      lo_object = create_transaction( is_transaction = is_transaction ).
    ENDIF.

    CASE is_transaction-kind.
      WHEN zcl_gg_transaction_registry=>kind_report.
        TRY.
            lo_report ?= lo_object.
          CATCH cx_root.
            RAISE EXCEPTION NEW zcx_gg_transaction_error(
              iv_message = |Transaction { is_transaction-tcode } is not a report implementation| ).
        ENDTRY.
        rs_response = start_program( io_report = lo_report ).
      WHEN zcl_gg_transaction_registry=>kind_dynpro.
        TRY.
            lo_dynpro ?= lo_object.
          CATCH cx_root.
            RAISE EXCEPTION NEW zcx_gg_transaction_error(
              iv_message = |Transaction { is_transaction-tcode } is not a dynpro implementation| ).
        ENDTRY.
        rs_response = start_program( io_dynpro = lo_dynpro ).
      WHEN OTHERS.
        RAISE EXCEPTION NEW zcx_gg_transaction_error(
          iv_message = |Transaction { is_transaction-tcode } has an unsupported executable kind| ).
    ENDCASE.
  ENDMETHOD.

  METHOD shutdown.
    zcl_gg_host_runtime=>clear( ).
    IF mv_database_ready = abap_true.
      zcl_gg_db_helper=>destroy( ).
      mv_database_ready = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD helper_html.
    rv_html = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>ZCL_GG_DB_HELPER</title><style>' &&
      zcl_gg_workbench_utility=>render_styles( ) &&
      '</style></head><body><div class="wb-shell">' &&
      zcl_gg_host_icons=>sprite( ) &&
      zcl_gg_workbench_utility=>render_top(
        iv_runtime = abap_true
        iv_title   = `ZCL_GG_DB_HELPER` ) &&
      '<div class="wb-runtime-content"><main><h1>ZCL_GG_DB_HELPER</h1><p>This is the database fixture support class used by the integration examples.</p><p>It is not an executable report or dynpro program.</p></main></div>' &&
      zcl_gg_workbench_utility=>render_bottom( ).
  ENDMETHOD.

  METHOD send_runtime_response.
    IF is_response-valid = abap_true.
      send_html(
        server  = server
        iv_html = is_response-html ).
    ELSEIF is_response-error CS 'Stale'.
      send_error(
        server    = server
        iv_error  = is_response-error
        iv_status = 409 ).
    ELSE.
      send_error(
        server   = server
        iv_error = is_response-error ).
    ENDIF.
  ENDMETHOD.

  METHOD send_workbench_error.
    send_html(
      server    = server
      iv_html   = zcl_gg_workbench=>render_error(
                    iv_error      = iv_error
                    iv_session_id = iv_session_id
                    iv_page_id    = iv_page_id )
      iv_status = iv_status ).
  ENDMETHOD.

  METHOD send_html.
    server->response->set_header_field(
      name  = 'cache-control'
      value = 'no-store' ).
    server->response->set_content_type( 'text/html; charset=utf-8' ).
    server->response->set_cdata( iv_html ).
    server->response->set_status(
      code   = iv_status
      reason = COND string( WHEN iv_status = 200 THEN 'OK' ELSE 'Error' ) ).
  ENDMETHOD.

  METHOD send_error.
    DATA ls_error TYPE ty_error_response.
    DATA lv_json  TYPE string.

    ls_error-valid = abap_false.
    ls_error-error = iv_error.
    lv_json = /ui2/cl_json=>serialize(
      data        = ls_error
      pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
    server->response->set_header_field(
      name  = 'cache-control'
      value = 'no-store' ).
    server->response->set_content_type( 'application/json; charset=utf-8' ).
    server->response->set_cdata( lv_json ).
    server->response->set_status(
      code   = iv_status
      reason = 'Error' ).
  ENDMETHOD.

  METHOD send_empty.
    server->response->set_header_field(
      name  = 'cache-control'
      value = 'no-store' ).
    server->response->set_status(
      code   = iv_status
      reason = COND string( WHEN iv_status = 204 THEN 'No Content' ELSE 'Error' ) ).
  ENDMETHOD.

  METHOD send_method_not_allowed.
    server->response->set_header_field(
      name  = 'allow'
      value = 'GET, POST, DELETE, OPTIONS' ).
    send_error(
      server    = server
      iv_error  = 'Method not allowed'
      iv_status = 405 ).
  ENDMETHOD.

  METHOD send_not_found.
    send_error(
      server    = server
      iv_error  = 'Not found'
      iv_status = 404 ).
  ENDMETHOD.

ENDCLASS.
