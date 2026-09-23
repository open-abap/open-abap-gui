CLASS zcl_gg_class_discovery DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Finds the global classes implementing an interface, so the framework can
* reach application classes without naming them. XCO is used where it exists,
* then the class library function module, then a scan of the repository
* sources, which is what the open-abap runtime provides.

  PUBLIC SECTION.
    CLASS-METHODS implementations_of
      IMPORTING
        iv_interface    TYPE string
      RETURNING
        VALUE(rt_names) TYPE string_table.

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

ENDCLASS.

CLASS zcl_gg_class_discovery IMPLEMENTATION.

  METHOD implementations_of.
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

    lv_interface = iv_interface.
    TRANSLATE lv_interface TO UPPER CASE.

    TRY.
        CALL METHOD ('XCO_CP_ABAP')=>interface
          EXPORTING
            iv_name      = lv_interface
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
            ls_key-intkey = lv_interface.
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
            SELECT progname, data FROM reposrc
              INTO TABLE @lt_sources
              ORDER BY progname.
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

ENDCLASS.
