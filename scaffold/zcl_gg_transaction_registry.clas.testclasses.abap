CLASS ltcl_gg_transaction_registry DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS contract_is_independent FOR TESTING.
    METHODS inventory_is_complete FOR TESTING.
    METHODS normalizes_and_looks_up FOR TESTING.
    METHODS parses_supported_commands FOR TESTING.
    METHODS replaces_a_host_session FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_transaction_registry IMPLEMENTATION.

  METHOD contract_is_independent.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    DATA lo_report TYPE REF TO zif_gg_report_v1.
    DATA lo_example TYPE REF TO zcl_gg_ex_01.

    lo_example = NEW zcl_gg_ex_01( ).
    lo_metadata ?= lo_example.
    lo_report ?= lo_example.
    DATA(ls_transaction) = lo_metadata->get_transaction( ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-tcode exp = 'ZGG_EX_01' ).
    cl_abap_unit_assert=>assert_bound( act = lo_report ).
  ENDMETHOD.

  METHOD inventory_is_complete.
    DATA lt_expected TYPE zcl_gg_transaction_registry=>ty_transactions.
    DATA lt_catalog TYPE zcl_gg_transaction_registry=>ty_transactions.
    DATA lv_examples TYPE i.

    zcl_gg_transaction_registry=>clear( ).
    lt_catalog = zcl_gg_transaction_registry=>get_all( ).
    lt_expected = VALUE #(
      ( tcode = 'ZGG_EX_01' class_name = 'ZCL_GG_EX_01' description = 'WRITE literal' )
      ( tcode = 'ZGG_EX_02' class_name = 'ZCL_GG_EX_02' description = 'WRITE AT position and NO-GAP' )
      ( tcode = 'ZGG_EX_03' class_name = 'ZCL_GG_EX_03' description = 'SKIP, ULINE, NEW-LINE and SET LEFT COLUMN' )
      ( tcode = 'ZGG_EX_04' class_name = 'ZCL_GG_EX_04' description = 'WRITE numeric and mask additions' )
      ( tcode = 'ZGG_EX_05' class_name = 'ZCL_GG_EX_05' description = 'FORMAT color and attributes' )
      ( tcode = 'ZGG_EX_06' class_name = 'ZCL_GG_EX_06' description = 'WRITE AS CHECKBOX, ICON and SYMBOL' )
      ( tcode = 'ZGG_EX_07' class_name = 'ZCL_GG_EX_07' description = 'REPORT line settings' )
      ( tcode = 'ZGG_EX_08' class_name = 'ZCL_GG_EX_08' description = 'NEW-PAGE, RESERVE and SET BLANK LINES' )
      ( tcode = 'ZGG_EX_09' class_name = 'ZCL_GG_EX_09' description = 'TOP-OF-PAGE' )
      ( tcode = 'ZGG_EX_10' class_name = 'ZCL_GG_EX_10' description = 'END-OF-PAGE' )
      ( tcode = 'ZGG_EX_11' class_name = 'ZCL_GG_EX_11' description = 'LOAD-OF-PROGRAM' )
      ( tcode = 'ZGG_EX_12' class_name = 'ZCL_GG_EX_12' description = 'INITIALIZATION' )
      ( tcode = 'ZGG_EX_13' class_name = 'ZCL_GG_EX_13' description = 'START-OF-SELECTION and END-OF-SELECTION' )
      ( tcode = 'ZGG_EX_14' class_name = 'ZCL_GG_EX_14' description = 'STOP' )
      ( tcode = 'ZGG_EX_15' class_name = 'ZCL_GG_EX_15' description = 'PARAMETERS with DEFAULT' )
      ( tcode = 'ZGG_EX_16' class_name = 'ZCL_GG_EX_16' description = 'PARAMETERS attribute additions' )
      ( tcode = 'ZGG_EX_17' class_name = 'ZCL_GG_EX_17' description = 'PARAMETERS AS CHECKBOX' )
      ( tcode = 'ZGG_EX_18' class_name = 'ZCL_GG_EX_18' description = 'PARAMETERS RADIOBUTTON GROUP' )
      ( tcode = 'ZGG_EX_19' class_name = 'ZCL_GG_EX_19' description = 'PARAMETERS AS LISTBOX' )
      ( tcode = 'ZGG_EX_20' class_name = 'ZCL_GG_EX_20' description = 'SELECT-OPTIONS' )
      ( tcode = 'ZGG_EX_21' class_name = 'ZCL_GG_EX_21' description = 'SELECTION-SCREEN COMMENT, ULINE and SKIP' )
      ( tcode = 'ZGG_EX_22' class_name = 'ZCL_GG_EX_22' description = 'Selection-screen block with frame and title' )
      ( tcode = 'ZGG_EX_23' class_name = 'ZCL_GG_EX_23' description = 'Selection-screen line and position' )
      ( tcode = 'ZGG_EX_24' class_name = 'ZCL_GG_EX_24' description = 'Selection-screen pushbutton and USER-COMMAND' )
      ( tcode = 'ZGG_EX_25' class_name = 'ZCL_GG_EX_25' description = 'SELECTION-SCREEN FUNCTION KEY' )
      ( tcode = 'ZGG_EX_26' class_name = 'ZCL_GG_EX_26' description = 'Selection-screen tabbed block and tabs' )
      ( tcode = 'ZGG_EX_27' class_name = 'ZCL_GG_EX_27' description = 'Selection-screen BEGIN OF SCREEN' )
      ( tcode = 'ZGG_EX_28' class_name = 'ZCL_GG_EX_28' description = 'AT SELECTION-SCREEN OUTPUT with LOOP AT SCREEN' )
      ( tcode = 'ZGG_EX_29' class_name = 'ZCL_GG_EX_29' description = 'AT SELECTION-SCREEN OUTPUT writing a parameter' )
      ( tcode = 'ZGG_EX_30' class_name = 'ZCL_GG_EX_30' description = 'AT SELECTION-SCREEN' )
      ( tcode = 'ZGG_EX_31' class_name = 'ZCL_GG_EX_31' description = 'AT SELECTION-SCREEN ON field' )
      ( tcode = 'ZGG_EX_32' class_name = 'ZCL_GG_EX_32' description = 'AT SELECTION-SCREEN ON END OF select-option' )
      ( tcode = 'ZGG_EX_33' class_name = 'ZCL_GG_EX_33' description = 'AT SELECTION-SCREEN ON BLOCK' )
      ( tcode = 'ZGG_EX_34' class_name = 'ZCL_GG_EX_34' description = 'AT SELECTION-SCREEN ON RADIOBUTTON GROUP' )
      ( tcode = 'ZGG_EX_35' class_name = 'ZCL_GG_EX_35' description = 'AT SELECTION-SCREEN ON VALUE-REQUEST' )
      ( tcode = 'ZGG_EX_36' class_name = 'ZCL_GG_EX_36' description = 'AT SELECTION-SCREEN ON HELP-REQUEST' )
      ( tcode = 'ZGG_EX_37' class_name = 'ZCL_GG_EX_37' description = 'AT SELECTION-SCREEN ON EXIT-COMMAND' )
      ( tcode = 'ZGG_EX_38' class_name = 'ZCL_GG_EX_38' description = 'SSCRFIELDS-UCOMM driven suppression' )
      ( tcode = 'ZGG_EX_39' class_name = 'ZCL_GG_EX_39' description = 'MESSAGE free text TYPE' )
      ( tcode = 'ZGG_EX_40' class_name = 'ZCL_GG_EX_40' description = 'MESSAGE number(id) WITH' )
      ( tcode = 'ZGG_EX_41' class_name = 'ZCL_GG_EX_41' description = 'Terminal MESSAGE type A' )
      ( tcode = 'ZGG_EX_42' class_name = 'ZCL_GG_EX_42' description = 'MESSAGE DISPLAY LIKE' )
      ( tcode = 'ZGG_EX_43' class_name = 'ZCL_GG_EX_43' description = 'HIDE and AT LINE-SELECTION' )
      ( tcode = 'ZGG_EX_44' class_name = 'ZCL_GG_EX_44' description = 'SET PF-STATUS and AT USER-COMMAND' )
      ( tcode = 'ZGG_EX_45' class_name = 'ZCL_GG_EX_45' description = 'SET TITLEBAR' )
      ( tcode = 'ZGG_EX_46' class_name = 'ZCL_GG_EX_46' description = 'READ LINE and MODIFY LINE' )
      ( tcode = 'ZGG_EX_47' class_name = 'ZCL_GG_EX_47' description = 'GET CURSOR' )
      ( tcode = 'ZGG_EX_48' class_name = 'ZCL_GG_EX_48' description = 'TOP-OF-PAGE DURING LINE-SELECTION' )
      ( tcode = 'ZGG_EX_49' class_name = 'ZCL_GG_EX_49' description = 'AT PF5' )
      ( tcode = 'ZGG_EX_50' class_name = 'ZCL_GG_EX_50' description = 'LEAVE TO/LIST-PROCESSING' )
      ( tcode = 'ZGG_EX_51' class_name = 'ZCL_GG_EX_51' description = 'CALL SELECTION-SCREEN' )
      ( tcode = 'ZGG_EX_52' class_name = 'ZCL_GG_EX_52' description = 'CALL SCREEN' )
      ( tcode = 'ZGG_EX_53' class_name = 'ZCL_GG_EX_53' description = 'Terminal SUBMIT' )
      ( tcode = 'ZGG_EX_54' class_name = 'ZCL_GG_EX_54' description = 'SUBMIT AND RETURN with selections and variant' )
      ( tcode = 'ZGG_EX_55' class_name = 'ZCL_GG_EX_55' description = 'SUBMIT EXPORTING LIST TO MEMORY' )
      ( tcode = 'ZGG_EX_56' class_name = 'ZCL_GG_EX_56' description = 'CALL TRANSACTION' )
      ( tcode = 'ZGG_EX_57' class_name = 'ZCL_GG_EX_57' description = 'LEAVE TO TRANSACTION and LEAVE PROGRAM' )
      ( tcode = 'ZGG_EX_58' class_name = 'ZCL_GG_EX_58' description = 'SET SCREEN, LEAVE SCREEN and LEAVE TO SCREEN' ) ).

    LOOP AT lt_catalog INTO DATA(ls_catalog).
      IF ls_catalog-class_name CP 'ZCL_GG_EX_*'.
        lv_examples = lv_examples + 1.
      ENDIF.
    ENDLOOP.
    cl_abap_unit_assert=>assert_equals( act = lv_examples exp = 58 ).
    LOOP AT lt_expected INTO DATA(ls_expected).
      READ TABLE lt_catalog INTO ls_catalog WITH KEY tcode = ls_expected-tcode.
      cl_abap_unit_assert=>assert_equals( act = sy-subrc exp = 0 ).
      cl_abap_unit_assert=>assert_equals( act = ls_catalog-class_name exp = ls_expected-class_name ).
      cl_abap_unit_assert=>assert_equals( act = ls_catalog-description exp = ls_expected-description ).
      cl_abap_unit_assert=>assert_not_initial( act = ls_catalog-kind ).
    ENDLOOP.
  ENDMETHOD.

  METHOD normalizes_and_looks_up.
    DATA ls_transaction TYPE zcl_gg_transaction_registry=>ty_transaction.
    DATA lt_invalid_tcodes TYPE string_table.
    DATA lv_invalid_tcode TYPE string.

    zcl_gg_transaction_registry=>clear( ).
    ls_transaction = zcl_gg_transaction_registry=>lookup( iv_tcode = `  zgg_ex_01  ` ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-tcode exp = 'ZGG_EX_01' ).
    cl_abap_unit_assert=>assert_equals( act = ls_transaction-class_name exp = 'ZCL_GG_EX_01' ).
    cl_abap_unit_assert=>assert_initial(
      act = zcl_gg_transaction_registry=>lookup( iv_tcode = `ZGG_EX_UNKNOWN` )-tcode ).
    cl_abap_unit_assert=>assert_equals(
      act = zcl_gg_transaction_registry=>normalize_tcode( iv_tcode = `/abc/def` )
      exp = `/ABC/DEF` ).
    lt_invalid_tcodes = VALUE #(
      ( `` )
      ( `ZGG EX 01` )
      ( `123456789012345678901` )
      ( `/NZGG_EX_01` )
      ( `/OZGG_EX_01` )
      ( `/ABC/` )
      ( `/ABC//DEF` ) ).
    LOOP AT lt_invalid_tcodes INTO lv_invalid_tcode.
      cl_abap_unit_assert=>assert_initial(
        act = zcl_gg_transaction_registry=>normalize_tcode( iv_tcode = lv_invalid_tcode ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD parses_supported_commands.
    DATA ls_result TYPE zcl_gg_transaction_command=>ty_result.

    zcl_gg_transaction_registry=>clear( ).
    ls_result = zcl_gg_transaction_command=>parse( iv_command = ` /nzgg_ex_58 ` ).
    cl_abap_unit_assert=>assert_true( act = ls_result-valid ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-tcode exp = 'ZGG_EX_58' ).
    ls_result = zcl_gg_transaction_command=>parse( iv_command = `/nzgg_ex01` ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-error
      exp = 'Unknown transaction code: zgg_ex01' ).
    LOOP AT VALUE string_table( ( `ZGG_EX_01` ) ( `/oZGG_EX_01` ) ( `/n` ) ( `/nUNKNOWN` ) ( `/nZGG_EX_01 extra` ) ) INTO DATA(lv_command).
      ls_result = zcl_gg_transaction_command=>parse( iv_command = lv_command ).
      cl_abap_unit_assert=>assert_false( act = ls_result-valid ).
      cl_abap_unit_assert=>assert_not_initial( act = ls_result-error ).
    ENDLOOP.
  ENDMETHOD.

  METHOD replaces_a_host_session.
    DATA ls_old TYPE zif_gg_host_html_v1=>ty_response.
    DATA ls_new TYPE zif_gg_host_html_v1=>ty_response.
    DATA ls_stale TYPE zif_gg_host_html_v1=>ty_response.
    DATA ls_request TYPE zif_gg_host_html_v1=>ty_request.

    zcl_gg_host_runtime=>clear( ).
    ls_old = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_01( ) ).
    cl_abap_unit_assert=>assert_initial(
      act = zcl_gg_host_runtime=>close_current(
        iv_session_id = ls_old-session_id
        iv_page_id    = ls_old-page_id ) ).
    ls_new = zcl_gg_host_runtime=>start( io_report = NEW zcl_gg_ex_02( ) ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_new-session_id ).
    ls_request-session_id = ls_old-session_id.
    ls_request-page_id = ls_old-page_id.
    ls_request-action = zif_gg_host_html_v1=>action_submit.
    ls_stale = zcl_gg_host_runtime=>dispatch( ls_request ).
    cl_abap_unit_assert=>assert_false( act = ls_stale-valid ).
    zcl_gg_host_runtime=>clear( ).
  ENDMETHOD.

ENDCLASS.
