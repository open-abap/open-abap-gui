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

    TYPES ty_class_names TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    CLASS-DATA mv_database_ready TYPE abap_bool.
    CLASS-DATA mt_report_classes TYPE ty_class_names.
    CLASS-DATA mt_dynpro_classes TYPE ty_class_names.

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

    CLASS-METHODS report_for_path
      IMPORTING
        iv_path          TYPE string
      RETURNING
        VALUE(ro_report) TYPE REF TO zif_gg_report_v1.

    CLASS-METHODS dynpro_for_path
      IMPORTING
        iv_path          TYPE string
      RETURNING
        VALUE(ro_dynpro) TYPE REF TO zif_gg_dynpro_v1.

    CLASS-METHODS get_list_classes_impl_intf
      IMPORTING
        val           TYPE string
      RETURNING
        VALUE(result) TYPE ty_class_names.

    CLASS-METHODS ensure_database.

    CLASS-METHODS index_html
      RETURNING
        VALUE(rv_html) TYPE string.

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

    CLASS-METHODS send_empty
      IMPORTING
        server    TYPE REF TO if_http_server
        iv_status TYPE i.

    CLASS-METHODS send_method_not_allowed
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
            send_empty( server = server iv_status = 204 ).
          WHEN OTHERS.
            send_method_not_allowed( server ).
        ENDCASE.
      CATCH cx_root INTO DATA(lx_error).
        send_error(
          server   = server
          iv_error = lx_error->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD handle_get.
    DATA lv_path   TYPE string.
    DATA lo_report TYPE REF TO zif_gg_report_v1.
    DATA lo_dynpro TYPE REF TO zif_gg_dynpro_v1.
    DATA ls_response TYPE zif_gg_host_html_v1=>ty_response.

    lv_path = server->request->get_header_field( '~path' ).
    IF lv_path = '/'.
      send_html( server = server iv_html = index_html( ) ).
      RETURN.
    ENDIF.
    IF lv_path = '/ZCL_GG_DB_HELPER'.
      send_html( server = server iv_html = helper_html( ) ).
      RETURN.
    ENDIF.

    lo_dynpro = dynpro_for_path( lv_path ).
    IF lo_dynpro IS BOUND.
      ensure_database( ).
      ls_response = zcl_gg_host_runtime=>start( io_dynpro_program = lo_dynpro ).
      send_runtime_response( server = server is_response = ls_response ).
      RETURN.
    ENDIF.

    lo_report = report_for_path( lv_path ).
    IF lo_report IS BOUND.
      ensure_database( ).
      ls_response = zcl_gg_host_runtime=>start( io_report = lo_report ).
      send_runtime_response( server = server is_response = ls_response ).
      RETURN.
    ENDIF.

    send_method_not_allowed( server ).
  ENDMETHOD.

  METHOD handle_post.
    DATA lv_path TYPE string.
    DATA ls_response TYPE zif_gg_host_html_v1=>ty_response.

    lv_path = server->request->get_header_field( '~path' ).
    IF lv_path <> '/dispatch'.
      send_method_not_allowed( server ).
      RETURN.
    ENDIF.

    ls_response = zcl_gg_host_runtime=>dispatch( is_request = request_from_http( server ) ).
    send_runtime_response( server = server is_response = ls_response ).
  ENDMETHOD.

  METHOD handle_delete.
    DATA lv_path       TYPE string.
    DATA lv_session_id TYPE string.

    lv_path = server->request->get_header_field( '~path' ).
    IF lv_path NP '/session/*'.
      send_method_not_allowed( server ).
      RETURN.
    ENDIF.

    lv_session_id = substring( val = lv_path off = 9 ).
    IF lv_session_id IS INITIAL OR lv_session_id CS '/'.
      send_method_not_allowed( server ).
      RETURN.
    ENDIF.
    lv_session_id = cl_http_utility=>unescape_url( lv_session_id ).
    zcl_gg_host_runtime=>close( lv_session_id ).
    send_empty( server = server iv_status = 204 ).
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
    ls_payload-session_id = form_value( it_fields = lt_fields iv_name = 'session_id' ).
    ls_payload-page_id = form_value( it_fields = lt_fields iv_name = 'page_id' ).
    ls_payload-action = form_value( it_fields = lt_fields iv_name = 'action' ).
    ls_payload-gg_action = form_value( it_fields = lt_fields iv_name = 'gg_action' ).
    ls_payload-ucomm = form_value( it_fields = lt_fields iv_name = 'ucomm' ).
    ls_payload-gg_ucomm = form_value( it_fields = lt_fields iv_name = 'gg_ucomm' ).
    ls_payload-target = form_value( it_fields = lt_fields iv_name = 'target' ).
    ls_payload-value = form_value( it_fields = lt_fields iv_name = 'value' ).
    ls_payload-row = CONV i( form_value( it_fields = lt_fields iv_name = 'row' ) ).
    ls_payload-pf_key = CONV i( form_value( it_fields = lt_fields iv_name = 'pf_key' ) ).
    ls_payload-token = form_value( it_fields = lt_fields iv_name = 'token' ).
    ls_payload-gg_token = form_value( it_fields = lt_fields iv_name = 'gg_token' ).
    ls_payload-cursor_field = form_value( it_fields = lt_fields iv_name = 'cursor_field' ).
    ls_payload-cursor_value = form_value( it_fields = lt_fields iv_name = 'cursor_value' ).
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
      lv_remainder = substring( val = lv_action_value off = 5 ).
      SPLIT lv_remainder AT '|' INTO lv_first lv_second.
      rs_request-row = CONV i( lv_first ).
      IF lv_second IS NOT INITIAL.
        rs_request-target = lv_second.
      ENDIF.
    ELSEIF lv_action_value CP 'VALUE_HELP:*'.
      rs_request-action = zif_gg_host_html_v1=>action_value_help.
      rs_request-target = substring( val = lv_action_value off = 11 ).
    ELSEIF lv_action_value CP 'HELP:*'.
      rs_request-action = zif_gg_host_html_v1=>action_help.
      rs_request-target = substring( val = lv_action_value off = 5 ).
    ELSEIF lv_action_value CP 'TAB:*'.
      rs_request-action = zif_gg_host_html_v1=>action_tab.
      lv_remainder = substring( val = lv_action_value off = 4 ).
      SPLIT lv_remainder AT '|' INTO lv_target lv_second.
      rs_request-target = lv_target.
      IF lv_second IS NOT INITIAL.
        rs_request-ucomm = lv_second.
      ENDIF.
    ELSEIF lv_action_value CP 'SCREEN:*'.
      rs_request-action = zif_gg_host_html_v1=>action_screen.
      lv_remainder = substring( val = lv_action_value off = 7 ).
      SPLIT lv_remainder AT '|' INTO lv_target lv_second.
      rs_request-target = lv_target.
      IF lv_second IS NOT INITIAL.
        rs_request-ucomm = lv_second.
      ENDIF.
    ELSEIF lv_action_value CP 'COMMAND:*'.
      rs_request-action = zif_gg_host_html_v1=>action_command.
      IF is_payload-gg_ucomm IS INITIAL.
        rs_request-ucomm = substring( val = lv_action_value off = 8 ).
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
    DATA lv_typed_name TYPE zif_gg_selection_screen_types=>ty_name.
    FIELD-SYMBOLS <ls_value> TYPE zif_gg_selection_screen_types=>ty_value.
    FIELD-SYMBOLS <ls_range> TYPE zif_gg_selection_screen_types=>ty_range.

    LOOP AT it_fields INTO DATA(ls_field).
      IF ls_field-name CP 'gg-radio-*'.
        lv_name = substring( val = ls_field-name off = 9 ).
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
      CLEAR lv_suffix.
      IF ls_field-name CP '*-LOW'.
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
          name  = lv_typed_name
          value = ``
          ranges = VALUE #( ) ) INTO TABLE rt_values.
        READ TABLE rt_values ASSIGNING <ls_value> WITH KEY name = lv_typed_name.
      ENDIF.
      IF lv_suffix IS INITIAL.
        <ls_value>-value = ls_field-value.
      ELSE.
        IF <ls_value>-ranges IS INITIAL.
          APPEND VALUE #(
            sign   = zif_gg_selection_screen_types=>sign_include
            option = zif_gg_selection_screen_types=>option_eq ) TO <ls_value>-ranges.
        ENDIF.
        READ TABLE <ls_value>-ranges ASSIGNING <ls_range> INDEX 1.
        CASE lv_suffix.
          WHEN 'LOW'.
            <ls_range>-low = ls_field-value.
          WHEN 'HIGH'.
            <ls_range>-high = ls_field-value.
          WHEN 'SIGN'.
            <ls_range>-sign = ls_field-value.
          WHEN 'OPTION'.
            <ls_range>-option = ls_field-value.
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
    DATA lv_row       TYPE i.
    DATA lv_last      TYPE i.
    DATA lt_parts     TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    LOOP AT it_fields INTO DATA(ls_field).
      IF ls_field-name CP 'gg-radio-*'.
        add_dynpro_value(
          EXPORTING
            iv_container = ``
            iv_name      = substring( val = ls_field-name off = 9 )
            iv_row       = 0
            iv_value     = 'X'
          CHANGING
            ct_values = rt_values ).
        CONTINUE.
      ENDIF.
      IF ls_field-name CP 'gg-cell-*'.
        lv_cell = substring( val = ls_field-name off = 8 ).
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
              iv_value     = ls_field-value
            CHANGING
              ct_values = rt_values ).
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
          iv_value     = ls_field-value
        CHANGING
          ct_values = rt_values ).
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

  METHOD report_for_path.
    DATA lv_class_name TYPE string.
    DATA lt_class_names TYPE ty_class_names.

    lv_class_name = substring( val = iv_path off = 1 ).
    IF lv_class_name NP 'ZCL_GG_*'.
      RETURN.
    ENDIF.

    lt_class_names = get_list_classes_impl_intf( 'ZIF_GG_REPORT_V1' ).
    READ TABLE lt_class_names TRANSPORTING NO FIELDS
      WITH KEY table_line = lv_class_name.
    IF sy-subrc = 0.
      CREATE OBJECT ro_report TYPE (lv_class_name).
    ENDIF.
  ENDMETHOD.

  METHOD dynpro_for_path.
    DATA lv_class_name TYPE string.
    DATA lt_class_names TYPE ty_class_names.

    lv_class_name = substring( val = iv_path off = 1 ).
    IF lv_class_name NP 'ZCL_GG_*'.
      RETURN.
    ENDIF.

    lt_class_names = get_list_classes_impl_intf( 'ZIF_GG_DYNPRO_V1' ).
    READ TABLE lt_class_names TRANSPORTING NO FIELDS
      WITH KEY table_line = lv_class_name.
    IF sy-subrc = 0.
      CREATE OBJECT ro_dynpro TYPE (lv_class_name).
    ENDIF.
  ENDMETHOD.

  METHOD get_list_classes_impl_intf.
    TYPES:
      BEGIN OF ty_s_impl,
        clsname    TYPE c LENGTH 30,
        refclsname TYPE c LENGTH 30,
      END OF ty_s_impl,
      BEGIN OF ty_s_key,
        intkey TYPE c LENGTH 30,
      END OF ty_s_key,
      BEGIN OF ty_source,
        progname TYPE c LENGTH 40,
        data     TYPE string,
      END OF ty_source.
    DATA obj TYPE REF TO object.
    DATA lt_implementation_names TYPE string_table.
    DATA lv_fm TYPE string.
    DATA lt_impl TYPE STANDARD TABLE OF ty_s_impl WITH DEFAULT KEY.
    DATA ls_key TYPE ty_s_key.
    DATA lt_sources TYPE STANDARD TABLE OF ty_source WITH DEFAULT KEY.
    DATA lv_interface TYPE string.
    DATA ls_source TYPE ty_source.
    DATA lv_source TYPE string.
    DATA lv_class_name TYPE string.
    DATA lr_impl TYPE REF TO ty_s_impl.
    FIELD-SYMBOLS <any> TYPE any.
    FIELD-SYMBOLS <class_name> TYPE string.

    IF val = 'ZIF_GG_REPORT_V1' AND mt_report_classes IS NOT INITIAL.
      result = mt_report_classes.
      RETURN.
    ELSEIF val = 'ZIF_GG_DYNPRO_V1' AND mt_dynpro_classes IS NOT INITIAL.
      result = mt_dynpro_classes.
      RETURN.
    ENDIF.

    TRY.
        CALL METHOD ('XCO_CP_ABAP')=>interface
          EXPORTING
            iv_name      = val
          RECEIVING
            ro_interface = obj.

        ASSIGN obj->('IF_XCO_AO_INTERFACE~IMPLEMENTATIONS') TO <any>.
        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE cx_sy_dyn_call_illegal_class.
        ENDIF.
        obj = <any>.

        ASSIGN obj->('IF_XCO_INTF_IMPLEMENTATIONS_FC~ALL') TO <any>.
        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE cx_sy_dyn_call_illegal_class.
        ENDIF.
        obj = <any>.

        CALL METHOD obj->('IF_XCO_INTF_IMPLEMENTATIONS~GET').

        CALL METHOD obj->('IF_XCO_INTF_IMPLEMENTATIONS~GET_NAMES')
          RECEIVING
            rt_names = lt_implementation_names.

        result = lt_implementation_names.

      CATCH cx_sy_dyn_call_illegal_class.
        lv_fm = `SEO_INTERFACE_IMPLEM_GET_ALL`.
        TRY.
            ls_key-intkey = val.

            CALL FUNCTION lv_fm
              EXPORTING
                intkey       = ls_key
              IMPORTING
                impkeys      = lt_impl
              EXCEPTIONS
                not_existing = 1
                OTHERS       = 2.

            LOOP AT lt_impl REFERENCE INTO lr_impl.
              INSERT CONV #( lr_impl->clsname ) INTO TABLE result.
            ENDLOOP.
          CATCH cx_root.
            lv_interface = val.
            TRANSLATE lv_interface TO UPPER CASE.
            SELECT progname, data FROM reposrc
              INTO TABLE @lt_sources
              ORDER BY progname.
            LOOP AT lt_sources INTO ls_source.
              lv_source = ls_source-data.
              TRANSLATE lv_source TO UPPER CASE.
              IF lv_source CS |INTERFACES { lv_interface }|.
                lv_class_name = CONV string( ls_source-progname ).
                SHIFT lv_class_name RIGHT DELETING TRAILING space.
                INSERT lv_class_name INTO TABLE result.
              ENDIF.
            ENDLOOP.
        ENDTRY.
    ENDTRY.

    LOOP AT result ASSIGNING <class_name>.
      TRANSLATE <class_name> TO UPPER CASE.
      SHIFT <class_name> RIGHT DELETING TRAILING space.
    ENDLOOP.
    SORT result.
    DELETE ADJACENT DUPLICATES FROM result.
    CASE val.
      WHEN 'ZIF_GG_REPORT_V1'.
        mt_report_classes = result.
      WHEN 'ZIF_GG_DYNPRO_V1'.
        mt_dynpro_classes = result.
    ENDCASE.
  ENDMETHOD.

  METHOD ensure_database.
    IF mv_database_ready = abap_false.
      zcl_gg_db_helper=>create( ).
      zcl_gg_db_helper=>reset( ).
      mv_database_ready = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD shutdown.
    zcl_gg_host_runtime=>clear( ).
    IF mv_database_ready = abap_true.
      zcl_gg_db_helper=>destroy( ).
      mv_database_ready = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD index_html.
    DATA lt_report_classes TYPE ty_class_names.
    DATA lt_dynpro_classes TYPE ty_class_names.
    DATA lv_class_name TYPE string.

    rv_html = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>ABAP examples and integration classes</title></head><body><main><h1>ABAP examples</h1><ul>'.
    lt_report_classes = get_list_classes_impl_intf( 'ZIF_GG_REPORT_V1' ).
    LOOP AT lt_report_classes INTO lv_class_name.
      IF lv_class_name CP 'ZCL_GG_*'.
        rv_html = rv_html && |<li><a href="/{ lv_class_name }">{ lv_class_name }</a></li>|.
      ENDIF.
    ENDLOOP.
    rv_html = rv_html && '</ul><h2>Dynpro classes</h2><ul>'.
    lt_dynpro_classes = get_list_classes_impl_intf( 'ZIF_GG_DYNPRO_V1' ).
    LOOP AT lt_dynpro_classes INTO lv_class_name.
      IF lv_class_name CP 'ZCL_GG_*'.
        rv_html = rv_html && |<li><a href="/{ lv_class_name }">{ lv_class_name }</a></li>|.
      ENDIF.
    ENDLOOP.
    rv_html = rv_html && '</ul><h2>Utilities</h2><ul>'.
    rv_html = rv_html && '<li><a href="/ZCL_GG_DB_HELPER">ZCL_GG_DB_HELPER</a></li>'.
    rv_html = rv_html && '</ul></main></body></html>'.
  ENDMETHOD.

  METHOD helper_html.
    rv_html = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>ZCL_GG_DB_HELPER</title></head><body><main><h1>ZCL_GG_DB_HELPER</h1><p>This is the database fixture support class used by the integration examples.</p><p>It is not an executable report or dynpro program.</p></main></body></html>'.
  ENDMETHOD.

  METHOD send_runtime_response.
    IF is_response-valid = abap_true.
      send_html(
        server = server
        iv_html = is_response-html ).
    ELSEIF is_response-error CS 'Stale'.
      send_error(
        server = server
        iv_error = is_response-error
        iv_status = 409 ).
    ELSE.
      send_error(
        server = server
        iv_error = is_response-error ).
    ENDIF.
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
      data = ls_error
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
      server = server
      iv_error = 'Method not allowed'
      iv_status = 405 ).
  ENDMETHOD.

ENDCLASS.
