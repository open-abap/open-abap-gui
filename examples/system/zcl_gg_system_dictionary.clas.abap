CLASS zcl_gg_system_dictionary DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Read-only Dictionary adapter. Every supported object kind keeps its own
* detail record; an unsupported kind and an unknown name are rejected with
* different messages so a caller never infers existence from a type error.

  PUBLIC SECTION.
    INTERFACES zif_gg_dictionary_service_v1.

  PRIVATE SECTION.
    METHODS flight_fields
      RETURNING
        VALUE(rt_fields) TYPE zif_gg_system_types_v1=>ty_ddic_fields.
    METHODS key_fields
      RETURNING
        VALUE(rt_fields) TYPE zif_gg_system_types_v1=>ty_ddic_fields.
    METHODS view_fields
      RETURNING
        VALUE(rt_fields) TYPE zif_gg_system_types_v1=>ty_ddic_fields.
    METHODS table_object
      RETURNING
        VALUE(rs_object) TYPE zif_gg_system_types_v1=>ty_ddic_object.
    METHODS structure_object
      RETURNING
        VALUE(rs_object) TYPE zif_gg_system_types_v1=>ty_ddic_object.
    METHODS data_element_object
      RETURNING
        VALUE(rs_object) TYPE zif_gg_system_types_v1=>ty_ddic_object.
    METHODS domain_object
      RETURNING
        VALUE(rs_object) TYPE zif_gg_system_types_v1=>ty_ddic_object.
    METHODS view_object
      RETURNING
        VALUE(rs_object) TYPE zif_gg_system_types_v1=>ty_ddic_object.
    METHODS search_help_object
      RETURNING
        VALUE(rs_object) TYPE zif_gg_system_types_v1=>ty_ddic_object.
    METHODS lock_object
      RETURNING
        VALUE(rs_object) TYPE zif_gg_system_types_v1=>ty_ddic_object.
    METHODS table_type_object
      RETURNING
        VALUE(rs_object) TYPE zif_gg_system_types_v1=>ty_ddic_object.
    METHODS type_group_object
      RETURNING
        VALUE(rs_object) TYPE zif_gg_system_types_v1=>ty_ddic_object.

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
    DATA lt_types TYPE string_table.
    DATA lt_names TYPE string_table.

    lv_object_type = iv_object_type.
    lv_name = iv_name.
    SHIFT lv_object_type LEFT DELETING LEADING space.
    SHIFT lv_name LEFT DELETING LEADING space.
    TRANSLATE lv_object_type TO UPPER CASE.
    TRANSLATE lv_name TO UPPER CASE.
    lt_types = zif_gg_dictionary_service_v1~get_object_types( ).
    IF NOT line_exists( lt_types[ table_line = lv_object_type ] ).
      rs_object-error = 'Dictionary object type is not supported.'.
      RETURN.
    ENDIF.
    lt_names = zif_gg_dictionary_service_v1~get_names( lv_object_type ).
    IF NOT line_exists( lt_names[ table_line = lv_name ] ).
      rs_object-error = 'Dictionary object is unknown or not permitted.'.
      RETURN.
    ENDIF.
    CASE lv_object_type.
      WHEN zif_gg_system_types_v1=>ddic_table.
        rs_object = table_object( ).
      WHEN zif_gg_system_types_v1=>ddic_structure.
        rs_object = structure_object( ).
      WHEN zif_gg_system_types_v1=>ddic_data_element.
        rs_object = data_element_object( ).
      WHEN zif_gg_system_types_v1=>ddic_domain.
        rs_object = domain_object( ).
      WHEN zif_gg_system_types_v1=>ddic_view.
        rs_object = view_object( ).
      WHEN zif_gg_system_types_v1=>ddic_search_help.
        rs_object = search_help_object( ).
      WHEN zif_gg_system_types_v1=>ddic_lock_object.
        rs_object = lock_object( ).
      WHEN zif_gg_system_types_v1=>ddic_table_type.
        rs_object = table_type_object( ).
      WHEN OTHERS.
        rs_object = type_group_object( ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_dictionary_service_v1~get_object_types.
    rt_types = VALUE string_table(
      ( zif_gg_system_types_v1=>ddic_table )
      ( zif_gg_system_types_v1=>ddic_structure )
      ( zif_gg_system_types_v1=>ddic_data_element )
      ( zif_gg_system_types_v1=>ddic_domain )
      ( zif_gg_system_types_v1=>ddic_view )
      ( zif_gg_system_types_v1=>ddic_search_help )
      ( zif_gg_system_types_v1=>ddic_lock_object )
      ( zif_gg_system_types_v1=>ddic_table_type )
      ( zif_gg_system_types_v1=>ddic_type_group ) ).
  ENDMETHOD.

  METHOD zif_gg_dictionary_service_v1~get_names.
    DATA lv_object_type TYPE string.

    lv_object_type = iv_object_type.
    SHIFT lv_object_type LEFT DELETING LEADING space.
    TRANSLATE lv_object_type TO UPPER CASE.
    CASE lv_object_type.
      WHEN zif_gg_system_types_v1=>ddic_table.
        rt_names = VALUE string_table( ( `ZSFLIGHT` ) ).
      WHEN zif_gg_system_types_v1=>ddic_structure.
        rt_names = VALUE string_table( ( `ZSFLIGHT_KEY` ) ).
      WHEN zif_gg_system_types_v1=>ddic_data_element.
        rt_names = VALUE string_table( ( `ZGG_CARRID` ) ).
      WHEN zif_gg_system_types_v1=>ddic_domain.
        rt_names = VALUE string_table( ( `ZGG_CARRID` ) ).
      WHEN zif_gg_system_types_v1=>ddic_view.
        rt_names = VALUE string_table( ( `ZSFLIGHT_V` ) ).
      WHEN zif_gg_system_types_v1=>ddic_search_help.
        rt_names = VALUE string_table( ( `ZGG_CARRID_SH` ) ).
      WHEN zif_gg_system_types_v1=>ddic_lock_object.
        rt_names = VALUE string_table( ( `EZGG_SFLIGHT` ) ).
      WHEN zif_gg_system_types_v1=>ddic_table_type.
        rt_names = VALUE string_table( ( `ZGG_SFLIGHT_TT` ) ).
      WHEN zif_gg_system_types_v1=>ddic_type_group.
        rt_names = VALUE string_table( ( `ZGGT` ) ).
      WHEN OTHERS.
        CLEAR rt_names.
    ENDCASE.
  ENDMETHOD.

  METHOD flight_fields.
    rt_fields = VALUE #(
      ( position = 1 name = 'CARRID' key_flag = abap_true data_element = 'ZGG_CARRID'
        data_type = 'CHAR' int_type = 'C' length = 3 search_help = 'ZGG_CARRID_SH'
        description = 'Airline carrier ID' )
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
        int_type = 'C' length = 20 description = 'Arrival city' ) ).
  ENDMETHOD.

  METHOD key_fields.
    LOOP AT flight_fields( ) INTO DATA(ls_field) WHERE key_flag = abap_true.
      APPEND ls_field TO rt_fields.
    ENDLOOP.
  ENDMETHOD.

  METHOD view_fields.
    LOOP AT flight_fields( ) INTO DATA(ls_field) WHERE position <= 4.
      APPEND ls_field TO rt_fields.
    ENDLOOP.
  ENDMETHOD.

  METHOD table_object.
    rs_object = VALUE #(
      object_type    = zif_gg_system_types_v1=>ddic_table
      name           = 'ZSFLIGHT'
      description    = 'Flight schedule fixture for scaffold examples'
      delivery_class = 'A'
      fields         = flight_fields( )
      technical      = VALUE #( data_class    = 'APPL0'
                                size_category = '0'
                                buffering     = 'Buffering not allowed'
                                log_changes   = abap_false ) ).
  ENDMETHOD.

  METHOD structure_object.
    rs_object = VALUE #(
      object_type = zif_gg_system_types_v1=>ddic_structure
      name        = 'ZSFLIGHT_KEY'
      description = 'Flight key structure'
      fields      = key_fields( ) ).
  ENDMETHOD.

  METHOD data_element_object.
    rs_object = VALUE #(
      object_type  = zif_gg_system_types_v1=>ddic_data_element
      name         = 'ZGG_CARRID'
      description  = 'Airline carrier ID'
      data_element = VALUE #( domain       = 'ZGG_CARRID'
                              data_type    = 'CHAR'
                              length       = 3
                              short_label  = 'Carrier'
                              medium_label = 'Airline'
                              long_label   = 'Airline carrier'
                              heading      = 'Carr.' ) ).
  ENDMETHOD.

  METHOD domain_object.
    rs_object = VALUE #(
      object_type = zif_gg_system_types_v1=>ddic_domain
      name        = 'ZGG_CARRID'
      description = 'Airline carrier key'
      domain      = VALUE #( data_type     = 'CHAR'
                             length        = 3
                             output_length = 3
                             value_table   = 'ZSFLIGHT'
                             fixed_values  = VALUE #(
                               ( value = 'AA' description = 'American Airlines' )
                               ( value = 'LH' description = 'Lufthansa' )
                               ( value = 'SQ' description = 'Singapore Airlines' ) ) ) ).
  ENDMETHOD.

  METHOD view_object.
    rs_object = VALUE #(
      object_type    = zif_gg_system_types_v1=>ddic_view
      name           = 'ZSFLIGHT_V'
      description    = 'Flight schedule view'
      delivery_class = 'A'
      fields         = view_fields( )
      view           = VALUE #(
        view_type            = 'Database view'
        base_tables          = VALUE string_table( ( `ZSFLIGHT` ) )
        join_conditions      = VALUE string_table( ( `Single base table; no join condition` ) )
        selection_conditions = VALUE string_table( ( `ZSFLIGHT~CARRID <> ' '` ) ) ) ).
  ENDMETHOD.

  METHOD search_help_object.
    rs_object = VALUE #(
      object_type = zif_gg_system_types_v1=>ddic_search_help
      name        = 'ZGG_CARRID_SH'
      description = 'Airline carrier value help'
      search_help = VALUE #(
        selection_method = 'ZSFLIGHT'
        dialog_type      = 'Display values immediately'
        parameters       = VALUE #(
          ( name = 'CARRID' import = abap_true export = abap_true
            list_position = 1 screen_position = 1 ) ) ) ).
  ENDMETHOD.

  METHOD lock_object.
    rs_object = VALUE #(
      object_type = zif_gg_system_types_v1=>ddic_lock_object
      name        = 'EZGG_SFLIGHT'
      description = 'Flight schedule lock object'
      lock_object = VALUE #(
        primary_table = 'ZSFLIGHT'
        lock_mode     = 'E (write lock)'
        parameters    = VALUE #(
          ( name = 'CARRID' table_name = 'ZSFLIGHT' field_name = 'CARRID' )
          ( name = 'CONNID' table_name = 'ZSFLIGHT' field_name = 'CONNID' )
          ( name = 'FLDATE' table_name = 'ZSFLIGHT' field_name = 'FLDATE' ) ) ) ).
  ENDMETHOD.

  METHOD table_type_object.
    rs_object = VALUE #(
      object_type = zif_gg_system_types_v1=>ddic_table_type
      name        = 'ZGG_SFLIGHT_TT'
      description = 'Flight schedule table type'
      table_type  = VALUE #(
        line_type   = 'ZSFLIGHT'
        access_kind = 'Standard table'
        key_kind    = 'Non-unique key'
        key_fields  = VALUE string_table( ( `CARRID` ) ( `CONNID` ) ( `FLDATE` ) ) ) ).
  ENDMETHOD.

  METHOD type_group_object.
    rs_object = VALUE #(
      object_type = zif_gg_system_types_v1=>ddic_type_group
      name        = 'ZGGT'
      description = 'Flight scaffold type group'
      type_group  = VALUE #(
        source_lines = VALUE string_table(
          ( `TYPE-POOL zggt.` )
          ( `` )
          ( `TYPES: BEGIN OF zggt_carrier,` )
          ( `         carrid TYPE c LENGTH 3,` )
          ( `       END OF zggt_carrier.` ) ) ) ).
  ENDMETHOD.

ENDCLASS.
