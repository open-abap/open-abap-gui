CLASS zcl_gg_transaction_registry DEFINITION PUBLIC FINAL CREATE PUBLIC.

* The registry is the only production catalog for public transactions. It
* discovers metadata implementations, validates their executable contract,
* normalizes identifiers, and owns the process-local catalog cache.

  PUBLIC SECTION.
    TYPES ty_kind TYPE string.
    CONSTANTS kind_report TYPE ty_kind VALUE 'REPORT'.
    CONSTANTS kind_dynpro TYPE ty_kind VALUE 'DYNPRO'.

    TYPES: BEGIN OF ty_transaction,
             tcode       TYPE zif_gg_transaction_v1=>ty_tcode,
             description TYPE string,
             class_name  TYPE string,
             kind        TYPE ty_kind,
           END OF ty_transaction.
    TYPES ty_transactions TYPE STANDARD TABLE OF ty_transaction WITH DEFAULT KEY.

    CLASS-METHODS get_all
      RETURNING
        VALUE(rt_transactions) TYPE ty_transactions.

    CLASS-METHODS lookup
      IMPORTING
        iv_tcode              TYPE string
      RETURNING
        VALUE(rs_transaction) TYPE ty_transaction.

    CLASS-METHODS normalize_tcode
      IMPORTING
        iv_tcode        TYPE string
      RETURNING
        VALUE(rv_tcode) TYPE zif_gg_transaction_v1=>ty_tcode.

    CLASS-METHODS clear.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_s_impl,
             clsname    TYPE c LENGTH 30,
             refclsname TYPE c LENGTH 30,
           END OF ty_s_impl.
    TYPES: BEGIN OF ty_s_key,
             intkey TYPE c LENGTH 30,
           END OF ty_s_key.
    TYPES: BEGIN OF ty_s_source,
             progname TYPE c LENGTH 40,
             data     TYPE string,
           END OF ty_s_source.

    CLASS-DATA mt_transactions TYPE ty_transactions.
    CLASS-DATA mv_initialized TYPE abap_bool.

    CLASS-METHODS ensure_catalog.

    CLASS-METHODS get_implementations
      RETURNING
        VALUE(rt_names) TYPE string_table.

    CLASS-METHODS validate_tcode
      IMPORTING
        iv_tcode        TYPE string
      RETURNING
        VALUE(rv_error) TYPE string.

    CLASS-METHODS validate_description
      IMPORTING
        iv_description  TYPE string
      RETURNING
        VALUE(rv_error) TYPE string.

ENDCLASS.

CLASS zcl_gg_transaction_registry IMPLEMENTATION.

  METHOD get_all.
    ensure_catalog( ).
    rt_transactions = mt_transactions.
  ENDMETHOD.

  METHOD lookup.
    DATA lv_tcode TYPE zif_gg_transaction_v1=>ty_tcode.

    ensure_catalog( ).
    lv_tcode = normalize_tcode( iv_tcode = iv_tcode ).
    IF lv_tcode IS INITIAL.
      RETURN.
    ENDIF.
    READ TABLE mt_transactions INTO rs_transaction WITH KEY tcode = lv_tcode.
  ENDMETHOD.

  METHOD normalize_tcode.
    DATA lv_tcode TYPE string.
    DATA lv_error TYPE string.
    DATA lv_length TYPE i.
    DATA lv_char TYPE c LENGTH 1.
    DATA lv_offset TYPE i.

    lv_tcode = iv_tcode.
    SHIFT lv_tcode LEFT DELETING LEADING space.
    lv_length = strlen( lv_tcode ).
    WHILE lv_length > 0.
      lv_offset = lv_length - 1.
      lv_char = lv_tcode+lv_offset(1).
      IF lv_char <> ' '.
        EXIT.
      ENDIF.
      lv_length = lv_length - 1.
    ENDWHILE.
    IF lv_length < strlen( lv_tcode ).
      lv_tcode = substring( val = lv_tcode
                            off = 0
                            len = lv_length ).
    ENDIF.
    TRANSLATE lv_tcode TO UPPER CASE.
    lv_error = validate_tcode( iv_tcode = lv_tcode ).
    IF lv_error IS INITIAL.
      rv_tcode = CONV #( lv_tcode ).
    ENDIF.
  ENDMETHOD.

  METHOD clear.
    CLEAR mt_transactions.
    CLEAR mv_initialized.
  ENDMETHOD.

  METHOD ensure_catalog.
    DATA lt_names TYPE string_table.
    DATA lo_object TYPE REF TO object.
    DATA lo_metadata TYPE REF TO zif_gg_transaction_v1.
    DATA lo_report TYPE REF TO zif_gg_report_v1.
    DATA lo_dynpro TYPE REF TO zif_gg_dynpro_v1.
    DATA ls_metadata TYPE zif_gg_transaction_v1=>ty_transaction.
    DATA ls_transaction TYPE ty_transaction.
    DATA lv_class_name TYPE string.
    DATA lv_tcode TYPE string.
    DATA lv_description TYPE string.
    DATA lv_description_length TYPE i.
    DATA lv_description_offset TYPE i.
    DATA lv_error TYPE string.
    DATA lv_report TYPE abap_bool.
    DATA lv_dynpro TYPE abap_bool.

    IF mv_initialized = abap_true.
      RETURN.
    ENDIF.
    CLEAR mt_transactions.
    lt_names = get_implementations( ).
    SORT lt_names.

    LOOP AT lt_names INTO lv_class_name.
      TRY.
          CREATE OBJECT lo_object TYPE (lv_class_name).
          lo_metadata ?= lo_object.
        CATCH cx_root INTO DATA(lx_metadata).
          RAISE EXCEPTION NEW zcx_gg_transaction_error(
            iv_message = |Transaction class { lv_class_name } cannot provide metadata: { lx_metadata->get_text( ) }| ).
      ENDTRY.

      CLEAR: lo_report, lo_dynpro, lv_report, lv_dynpro.
      TRY.
          lo_report ?= lo_object.
          lv_report = abap_true.
        CATCH cx_root.
          CLEAR lo_report.
      ENDTRY.
      TRY.
          lo_dynpro ?= lo_object.
          lv_dynpro = abap_true.
        CATCH cx_root.
          CLEAR lo_dynpro.
      ENDTRY.
      IF lv_report = abap_true AND lv_dynpro = abap_true.
        RAISE EXCEPTION NEW zcx_gg_transaction_error(
          iv_message = |Transaction class { lv_class_name } implements both ZIF_GG_REPORT_V1 and ZIF_GG_DYNPRO_V1| ).
      ELSEIF lv_report = abap_false AND lv_dynpro = abap_false.
        RAISE EXCEPTION NEW zcx_gg_transaction_error(
          iv_message = |Transaction class { lv_class_name } implements neither ZIF_GG_REPORT_V1 nor ZIF_GG_DYNPRO_V1| ).
      ENDIF.

      ls_metadata = lo_metadata->get_transaction( ).
      lv_tcode = ls_metadata-tcode.
      SHIFT lv_tcode LEFT DELETING LEADING space.
      DATA(lv_tcode_length) = strlen( lv_tcode ).
      WHILE lv_tcode_length > 0.
        DATA(lv_tcode_offset) = lv_tcode_length - 1.
        IF lv_tcode+lv_tcode_offset(1) <> ' '.
          EXIT.
        ENDIF.
        lv_tcode_length = lv_tcode_length - 1.
      ENDWHILE.
      IF lv_tcode_length < strlen( lv_tcode ).
        lv_tcode = substring( val = lv_tcode
                              off = 0
                              len = lv_tcode_length ).
      ENDIF.
      TRANSLATE lv_tcode TO UPPER CASE.
      lv_error = validate_tcode( iv_tcode = lv_tcode ).
      IF lv_error IS NOT INITIAL.
        RAISE EXCEPTION NEW zcx_gg_transaction_error(
          iv_message = |Invalid transaction metadata in { lv_class_name }: { lv_error }| ).
      ENDIF.

      lv_description = ls_metadata-description.
      SHIFT lv_description LEFT DELETING LEADING space.
      lv_description_length = strlen( lv_description ).
      WHILE lv_description_length > 0.
        lv_description_offset = lv_description_length - 1.
        IF lv_description+lv_description_offset(1) <> ' '.
          EXIT.
        ENDIF.
        lv_description_length = lv_description_length - 1.
      ENDWHILE.
      IF lv_description_length < strlen( lv_description ).
        lv_description = substring( val = lv_description
                                    off = 0
                                    len = lv_description_length ).
      ENDIF.
      lv_error = validate_description( iv_description = lv_description ).
      IF lv_error IS NOT INITIAL.
        RAISE EXCEPTION NEW zcx_gg_transaction_error(
          iv_message = |Invalid transaction metadata in { lv_class_name }: { lv_error }| ).
      ENDIF.

      CLEAR ls_transaction.
      ls_transaction-tcode = CONV #( lv_tcode ).
      ls_transaction-description = lv_description.
      ls_transaction-class_name = lv_class_name.
      ls_transaction-kind = COND #( WHEN lv_report = abap_true THEN kind_report ELSE kind_dynpro ).
      APPEND ls_transaction TO mt_transactions.
    ENDLOOP.

    SORT mt_transactions BY tcode class_name.
    LOOP AT mt_transactions INTO DATA(ls_current).
      IF sy-tabix > 1.
        READ TABLE mt_transactions INTO DATA(ls_previous) INDEX sy-tabix - 1.
        IF ls_current-tcode = ls_previous-tcode.
          RAISE EXCEPTION NEW zcx_gg_transaction_error(
            iv_message = |Duplicate transaction code { ls_current-tcode } in { ls_previous-class_name } and { ls_current-class_name }| ).
        ENDIF.
      ENDIF.
    ENDLOOP.
    mv_initialized = abap_true.
  ENDMETHOD.

  METHOD get_implementations.
    DATA obj TYPE REF TO object.
    DATA lt_implementation_names TYPE string_table.
    DATA lv_fm TYPE string.
    DATA lt_impl TYPE STANDARD TABLE OF ty_s_impl WITH DEFAULT KEY.
    DATA ls_key TYPE ty_s_key.
    DATA lt_sources TYPE STANDARD TABLE OF ty_s_source WITH DEFAULT KEY.
    DATA lv_interface TYPE string.
    DATA ls_source TYPE ty_s_source.
    DATA lv_source TYPE string.
    DATA lv_class_name TYPE string.
    DATA lr_impl TYPE REF TO ty_s_impl.
    FIELD-SYMBOLS <any> TYPE any.
    FIELD-SYMBOLS <class_name> TYPE string.

    TRY.
        CALL METHOD ('XCO_CP_ABAP')=>interface
          EXPORTING
            iv_name      = 'ZIF_GG_TRANSACTION_V1'
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
        rt_names = lt_implementation_names.
      CATCH cx_sy_dyn_call_illegal_class.
        lv_fm = `SEO_INTERFACE_IMPLEM_GET_ALL`.
        TRY.
            ls_key-intkey = 'ZIF_GG_TRANSACTION_V1'.
            CALL FUNCTION lv_fm
              EXPORTING
                intkey       = ls_key
              IMPORTING
                impkeys      = lt_impl
              EXCEPTIONS
                not_existing = 1
                OTHERS       = 2.
            LOOP AT lt_impl REFERENCE INTO lr_impl.
              INSERT CONV #( lr_impl->clsname ) INTO TABLE rt_names.
            ENDLOOP.
          CATCH cx_root.
            lv_interface = 'ZIF_GG_TRANSACTION_V1'.
            SELECT progname, data FROM reposrc
              INTO TABLE @lt_sources
              ORDER BY progname.
            TRANSLATE lv_interface TO UPPER CASE.
            LOOP AT lt_sources INTO ls_source.
              lv_source = ls_source-data.
              TRANSLATE lv_source TO UPPER CASE.
              IF lv_source CS |INTERFACES { lv_interface }|.
                lv_class_name = CONV string( ls_source-progname ).
                SHIFT lv_class_name RIGHT DELETING TRAILING space.
                INSERT lv_class_name INTO TABLE rt_names.
              ENDIF.
            ENDLOOP.
        ENDTRY.
    ENDTRY.

    LOOP AT rt_names ASSIGNING <class_name>.
      TRANSLATE <class_name> TO UPPER CASE.
      SHIFT <class_name> RIGHT DELETING TRAILING space.
    ENDLOOP.
    SORT rt_names.
    DELETE ADJACENT DUPLICATES FROM rt_names.
  ENDMETHOD.

  METHOD validate_tcode.
    DATA lv_tcode TYPE string.
    DATA lv_length TYPE i.
    DATA lv_char TYPE c LENGTH 1.
    DATA lv_previous TYPE c LENGTH 1.
    DATA lv_slashes TYPE i.

    lv_tcode = iv_tcode.
    IF lv_tcode IS INITIAL.
      rv_error = 'transaction code is initial'.
      RETURN.
    ENDIF.
    lv_length = strlen( lv_tcode ).
    IF lv_length > 20.
      rv_error = 'transaction code is longer than 20 characters'.
      RETURN.
    ENDIF.
    DO lv_length TIMES.
      DATA(lv_offset) = sy-index - 1.
      lv_char = lv_tcode+lv_offset(1).
      IF ( lv_char < 'A' OR lv_char > 'Z' )
          AND ( lv_char < '0' OR lv_char > '9' )
          AND lv_char <> '_'
          AND lv_char <> '/'.
        rv_error = 'transaction code contains an invalid character'.
        RETURN.
      ENDIF.
      IF lv_char = '/'.
        lv_slashes = lv_slashes + 1.
        IF lv_offset = lv_length - 1 OR lv_previous = '/'.
          rv_error = 'namespace separators must be between name segments'.
          RETURN.
        ENDIF.
      ENDIF.
      lv_previous = lv_char.
    ENDDO.
    IF ( lv_tcode CP '/N*' OR lv_tcode CP '/O*' ) AND lv_slashes < 2.
      rv_error = 'transaction code must not contain a command prefix'.
      RETURN.
    ENDIF.
    IF lv_tcode+0(1) = '/' AND lv_slashes < 2.
      rv_error = 'namespace separators must be between name segments'.
    ENDIF.
  ENDMETHOD.

  METHOD validate_description.
    IF iv_description IS INITIAL.
      rv_error = 'description is initial'.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
