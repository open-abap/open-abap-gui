CLASS zcl_gg_system_dictionary DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_dictionary_service_v1.

ENDCLASS.

CLASS zcl_gg_system_dictionary IMPLEMENTATION.

  METHOD zif_gg_dictionary_service_v1~get_capabilities.
    rs_capabilities = VALUE #(
      display_only = abap_true
      can_change   = abap_false
      can_create   = abap_false
      can_save     = abap_false
      can_activate = abap_false
      can_release  = abap_false
      can_export   = abap_false
      can_debug    = abap_false
      explanation  = 'Display-only deployment: Dictionary changes require a repository activation pipeline.' ).
  ENDMETHOD.

  METHOD zif_gg_dictionary_service_v1~get_object.
    DATA lv_object_type TYPE string.
    DATA lv_name TYPE string.

    lv_object_type = iv_object_type.
    lv_name = iv_name.
    SHIFT lv_object_type LEFT DELETING LEADING space.
    SHIFT lv_name LEFT DELETING LEADING space.
    TRANSLATE lv_object_type TO UPPER CASE.
    TRANSLATE lv_name TO UPPER CASE.
    IF lv_object_type <> 'TABLE' AND lv_object_type <> 'VIEW'.
      rs_object-error = 'Dictionary object type is not supported.'.
      RETURN.
    ENDIF.
    IF lv_name <> 'ZSFLIGHT'.
      rs_object-error = 'Dictionary object is unknown or not permitted.'.
      RETURN.
    ENDIF.
    rs_object = VALUE #(
      object_type    = lv_object_type
      name           = 'ZSFLIGHT'
      description    = 'Flight schedule fixture for scaffold examples'
      delivery_class = 'A'
      fields         = VALUE #(
        ( position = 1 name = 'CARRID' key_flag = abap_true data_type = 'CHAR'
          int_type = 'C' length = 3 description = 'Airline carrier ID' )
        ( position = 2 name = 'CONNID' key_flag = abap_true data_type = 'NUMC'
          int_type = 'N' length = 4 description = 'Flight connection number' )
        ( position = 3 name = 'FLDATE' key_flag = abap_true data_type = 'DATS'
          int_type = 'D' length = 8 description = 'Flight date' )
        ( position = 4 name = 'PRICE' key_flag = abap_false data_type = 'DEC'
          int_type = 'P' length = 15 decimals = 2 description = 'Flight price' )
        ( position = 5 name = 'CURRENCY' key_flag = abap_false data_type = 'CUKY'
          int_type = 'C' length = 5 description = 'Currency key' )
        ( position = 6 name = 'PLANETYPE' key_flag = abap_false data_type = 'CHAR'
          int_type = 'C' length = 10 description = 'Aircraft type' )
        ( position = 7 name = 'CITYFROM' key_flag = abap_false data_type = 'CHAR'
          int_type = 'C' length = 20 description = 'Departure city' )
        ( position = 8 name = 'CITYTO' key_flag = abap_false data_type = 'CHAR'
          int_type = 'C' length = 20 description = 'Arrival city' ) ) ).
  ENDMETHOD.

  METHOD zif_gg_dictionary_service_v1~get_names.
    DATA lv_object_type TYPE string.

    lv_object_type = iv_object_type.
    TRANSLATE lv_object_type TO UPPER CASE.
    IF lv_object_type = 'TABLE' OR lv_object_type = 'VIEW'.
      rt_names = VALUE string_table( ( `ZSFLIGHT` ) ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
