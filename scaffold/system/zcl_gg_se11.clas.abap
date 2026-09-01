CLASS zcl_gg_se11 DEFINITION PUBLIC FINAL CREATE PUBLIC.

* ABAP Dictionary display. Every supported object kind owns one detail screen
* built from that kind's metadata; unlike kinds are never flattened into one
* generic property dump. Change and Create stay unavailable until a real
* repository write, check and activation pipeline exists.

  PUBLIC SECTION.
    INTERFACES zif_gg_dynpro_v1.
    INTERFACES zif_gg_transaction_v1.

  PRIVATE SECTION.
    CONSTANTS screen_chooser TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0100'.
    CONSTANTS screen_table TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0200'.
    CONSTANTS screen_structure TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0210'.
    CONSTANTS screen_data_element TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0220'.
    CONSTANTS screen_domain TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0230'.
    CONSTANTS screen_view TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0240'.
    CONSTANTS screen_search_help TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0250'.
    CONSTANTS screen_lock_object TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0260'.
    CONSTANTS screen_table_type TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0270'.
    CONSTANTS screen_type_group TYPE zif_gg_dynpro_types_v1=>ty_screen_number VALUE '0280'.

    METHODS put_value
      IMPORTING
        iv_name   TYPE zif_gg_dynpro_types_v1=>ty_name
        iv_value  TYPE string
      CHANGING
        ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    METHODS value_of
      IMPORTING
        it_values       TYPE zif_gg_dynpro_types_v1=>ty_values
        iv_name         TYPE zif_gg_dynpro_types_v1=>ty_name
      RETURNING
        VALUE(rv_value) TYPE string.
    METHODS put_cell
      IMPORTING
        iv_container TYPE zif_gg_dynpro_types_v1=>ty_name
        iv_name      TYPE zif_gg_dynpro_types_v1=>ty_name
        iv_row       TYPE i
        iv_value     TYPE string
      CHANGING
        ct_values    TYPE zif_gg_dynpro_types_v1=>ty_values.
    METHODS add_flow
      IMPORTING
        io_builder TYPE REF TO zif_gg_dynpro_flow_builder_v1
        iv_screen  TYPE zif_gg_dynpro_types_v1=>ty_screen_number
        iv_field   TYPE zif_gg_dynpro_types_v1=>ty_name OPTIONAL.
    METHODS detail_screens
      RETURNING
        VALUE(rt_screens) TYPE zcl_gg_host_dynpro_builder=>ty_screens.
    METHODS screen_for_type
      IMPORTING
        iv_object_type   TYPE string
      RETURNING
        VALUE(rv_screen) TYPE zif_gg_dynpro_types_v1=>ty_screen_number.
    METHODS add_header
      IMPORTING
        io_builder TYPE REF TO zif_gg_dynpro_builder_v1
        iv_prefix  TYPE string.
    METHODS put_header
      IMPORTING
        iv_prefix TYPE string
        is_object TYPE zif_gg_system_types_v1=>ty_ddic_object
      CHANGING
        ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    METHODS add_field_table
      IMPORTING
        io_builder TYPE REF TO zif_gg_dynpro_builder_v1
        iv_name    TYPE zif_gg_dynpro_types_v1=>ty_name
        iv_row     TYPE i
        iv_rows    TYPE i.
    METHODS put_field_table
      IMPORTING
        iv_name   TYPE zif_gg_dynpro_types_v1=>ty_name
        it_fields TYPE zif_gg_system_types_v1=>ty_ddic_fields
      CHANGING
        ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    METHODS put_table_detail
      IMPORTING
        is_object TYPE zif_gg_system_types_v1=>ty_ddic_object
      CHANGING
        ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    METHODS put_view_detail
      IMPORTING
        is_object TYPE zif_gg_system_types_v1=>ty_ddic_object
      CHANGING
        ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    METHODS put_data_element_detail
      IMPORTING
        is_object TYPE zif_gg_system_types_v1=>ty_ddic_object
      CHANGING
        ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    METHODS put_domain_detail
      IMPORTING
        is_object TYPE zif_gg_system_types_v1=>ty_ddic_object
      CHANGING
        ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    METHODS put_search_help_detail
      IMPORTING
        is_object TYPE zif_gg_system_types_v1=>ty_ddic_object
      CHANGING
        ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    METHODS put_lock_object_detail
      IMPORTING
        is_object TYPE zif_gg_system_types_v1=>ty_ddic_object
      CHANGING
        ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    METHODS put_table_type_detail
      IMPORTING
        is_object TYPE zif_gg_system_types_v1=>ty_ddic_object
      CHANGING
        ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    METHODS put_type_group_detail
      IMPORTING
        is_object TYPE zif_gg_system_types_v1=>ty_ddic_object
      CHANGING
        ct_values TYPE zif_gg_dynpro_types_v1=>ty_values.
    METHODS joined
      IMPORTING
        it_lines       TYPE string_table
      RETURNING
        VALUE(rv_text) TYPE string.

ENDCLASS.

CLASS zcl_gg_se11 IMPLEMENTATION.

  METHOD zif_gg_transaction_v1~get_transaction.
    rs_transaction = VALUE #( tcode = 'SE11' description = 'ABAP Dictionary' ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~get_initial_screen.
    rv_screen = screen_chooser.
  ENDMETHOD.

  METHOD detail_screens.
    rt_screens = VALUE #(
      ( number = screen_table title = 'Dictionary: Display Table' height = 470 )
      ( number = screen_structure title = 'Dictionary: Display Structure' height = 360 )
      ( number = screen_data_element title = 'Dictionary: Display Data Element' height = 330 )
      ( number = screen_domain title = 'Dictionary: Display Domain' height = 380 )
      ( number = screen_view title = 'Dictionary: Display View' height = 430 )
      ( number = screen_search_help title = 'Dictionary: Display Search Help' height = 370 )
      ( number = screen_lock_object title = 'Dictionary: Display Lock Object' height = 370 )
      ( number = screen_table_type title = 'Dictionary: Display Table Type' height = 330 )
      ( number = screen_type_group title = 'Dictionary: Display Type Group' height = 330 ) ).
  ENDMETHOD.

  METHOD screen_for_type.
    CASE iv_object_type.
      WHEN zif_gg_system_types_v1=>ddic_table.
        rv_screen = screen_table.
      WHEN zif_gg_system_types_v1=>ddic_structure.
        rv_screen = screen_structure.
      WHEN zif_gg_system_types_v1=>ddic_data_element.
        rv_screen = screen_data_element.
      WHEN zif_gg_system_types_v1=>ddic_domain.
        rv_screen = screen_domain.
      WHEN zif_gg_system_types_v1=>ddic_view.
        rv_screen = screen_view.
      WHEN zif_gg_system_types_v1=>ddic_search_help.
        rv_screen = screen_search_help.
      WHEN zif_gg_system_types_v1=>ddic_lock_object.
        rv_screen = screen_lock_object.
      WHEN zif_gg_system_types_v1=>ddic_table_type.
        rv_screen = screen_table_type.
      WHEN zif_gg_system_types_v1=>ddic_type_group.
        rv_screen = screen_type_group.
      WHEN OTHERS.
        CLEAR rv_screen.
    ENDCASE.
  ENDMETHOD.

  METHOD add_header.
    io_builder->add_text( VALUE #( control = VALUE #( name = CONV #( |T_{ iv_prefix }_TYPE| ) position = VALUE #( row = 16 column = 18 width = 120 ) ) text = 'Object type' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = CONV #( |O_{ iv_prefix }_TYPE| ) position = VALUE #( row = 12 column = 150 width = 180 ) ) data_type = VALUE #( typ = 'C' length = 20 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = CONV #( |T_{ iv_prefix }_NAME| ) position = VALUE #( row = 50 column = 18 width = 120 ) ) text = 'Name' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = CONV #( |O_{ iv_prefix }_NAME| ) position = VALUE #( row = 46 column = 150 width = 220 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = CONV #( |T_{ iv_prefix }_DESC| ) position = VALUE #( row = 84 column = 18 width = 120 ) ) text = 'Short description' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = CONV #( |O_{ iv_prefix }_DESC| ) position = VALUE #( row = 80 column = 150 width = 380 ) ) data_type = VALUE #( typ = 'C' length = 80 ) ) ).
  ENDMETHOD.

  METHOD put_header.
    put_value( EXPORTING iv_name = CONV #( |O_{ iv_prefix }_TYPE| )
                         iv_value = is_object-object_type CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = CONV #( |O_{ iv_prefix }_NAME| )
                         iv_value = is_object-name CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = CONV #( |O_{ iv_prefix }_DESC| )
                         iv_value = is_object-description CHANGING ct_values = ct_values ).
  ENDMETHOD.

  METHOD add_field_table.
    io_builder->begin_table_control( VALUE #( control = VALUE #( name = iv_name position = VALUE #( row = iv_row column = 18 width = 700 height = iv_rows * 30 + 30 ) ) visible_rows = iv_rows selection_mode = 'NONE' with_hscroll = abap_true with_vscroll = abap_false ) ).
    io_builder->add_table_column( VALUE #( table_control = iv_name name = 'FIELD_POSITION' title = 'Pos.' data_type = VALUE #( typ = 'N' length = 4 ) width = 55 ) ).
    io_builder->add_table_column( VALUE #( table_control = iv_name name = 'FIELD_NAME' title = 'Field' data_type = VALUE #( typ = 'C' length = 30 ) width = 120 ) ).
    io_builder->add_table_column( VALUE #( table_control = iv_name name = 'FIELD_KEY' title = 'Key' data_type = VALUE #( typ = 'C' length = 3 ) width = 50 ) ).
    io_builder->add_table_column( VALUE #( table_control = iv_name name = 'FIELD_ELEMENT' title = 'Data element' data_type = VALUE #( typ = 'C' length = 30 ) width = 120 ) ).
    io_builder->add_table_column( VALUE #( table_control = iv_name name = 'FIELD_TYPE' title = 'Data type' data_type = VALUE #( typ = 'C' length = 10 ) width = 90 ) ).
    io_builder->add_table_column( VALUE #( table_control = iv_name name = 'FIELD_LENGTH' title = 'Length' data_type = VALUE #( typ = 'N' length = 8 ) width = 70 ) ).
    io_builder->add_table_column( VALUE #( table_control = iv_name name = 'FIELD_DECIMALS' title = 'Decimals' data_type = VALUE #( typ = 'N' length = 8 ) width = 80 ) ).
    io_builder->add_table_column( VALUE #( table_control = iv_name name = 'FIELD_TEXT' title = 'Description' data_type = VALUE #( typ = 'C' length = 60 ) width = 180 ) ).
    io_builder->end_table_control( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_screens.
    DATA(lo_service) = NEW zcl_gg_system_dictionary( ).
    DATA lt_fixed_values TYPE zif_gg_dynpro_types_v1=>ty_fixed_values.
    DATA lv_column TYPE i.

    LOOP AT lo_service->zif_gg_dictionary_service_v1~get_object_types( ) INTO DATA(lv_object_type).
      APPEND VALUE #( key  = lv_object_type
                      text = lv_object_type ) TO lt_fixed_values.
    ENDLOOP.

    io_builder->begin_screen( VALUE #( number = screen_chooser title = 'ABAP Dictionary' height = 330 ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_OBJECT_TYPE' position = VALUE #( row = 18 column = 18 width = 140 ) ) text = 'Object type' ) ).
    io_builder->add_listbox( VALUE #( control = VALUE #( name = 'P_OBJECT_TYPE' position = VALUE #( row = 12 column = 170 width = 220 ) ) data_type = VALUE #( typ = 'C' length = 20 ) fixed_values = lt_fixed_values ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_OBJECT_NAME' position = VALUE #( row = 60 column = 18 width = 140 ) ) text = 'Object name' ) ).
    io_builder->add_input_field( VALUE #( control = VALUE #( name = 'P_OBJECT_NAME' position = VALUE #( row = 54 column = 170 width = 220 ) ) data_type = VALUE #( typ = 'C' length = 30 ) value_help = abap_true required = abap_true uppercase = abap_true ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_CHOOSER_INFO' position = VALUE #( row = 102 column = 18 width = 540 ) ) text = 'Display reads server-owned Dictionary metadata. Change and Create are unavailable.' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'P_CAPABILITY' position = VALUE #( row = 142 column = 18 width = 540 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_DISPLAY' position = VALUE #( row = 198 column = 18 width = 96 ) ) text = 'Display' ucomm = 'DISPLAY' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CHANGE' position = VALUE #( row = 198 column = 124 width = 96 ) ) text = 'Change' ucomm = 'CHANGE' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CREATE' position = VALUE #( row = 198 column = 230 width = 96 ) ) text = 'Create' ucomm = 'CREATE' ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_table title = 'Dictionary: Display Table' height = 470 ) ).
    add_header( io_builder = io_builder
                iv_prefix  = 'TAB' ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TAB_DELIVERY' position = VALUE #( row = 118 column = 18 width = 120 ) ) text = 'Delivery class' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_TAB_DELIVERY' position = VALUE #( row = 114 column = 150 width = 120 ) ) data_type = VALUE #( typ = 'C' length = 4 ) ) ).
    io_builder->add_tabstrip( VALUE #( control = VALUE #( name = 'TAB_DICTIONARY' position = VALUE #( row = 150 column = 18 width = 700 height = 32 ) ) ) ).
    io_builder->add_tab( VALUE #( control = VALUE #( name = 'TAB_ATTRIBUTES' position = VALUE #( row = 150 column = 18 width = 110 ) ) tabstrip = 'TAB_DICTIONARY' text = 'Attributes' subscreen = screen_table ucomm = 'ATTRIBUTES' ) ).
    io_builder->add_tab( VALUE #( control = VALUE #( name = 'TAB_FIELDS' position = VALUE #( row = 150 column = 138 width = 90 ) ) tabstrip = 'TAB_DICTIONARY' text = 'Fields' subscreen = screen_table ucomm = 'FIELDS' ) ).
    io_builder->add_tab( VALUE #( control = VALUE #( name = 'TAB_KEYS' position = VALUE #( row = 150 column = 240 width = 80 ) ) tabstrip = 'TAB_DICTIONARY' text = 'Keys' subscreen = screen_table ucomm = 'KEYS' ) ).
    io_builder->add_tab( VALUE #( control = VALUE #( name = 'TAB_CHECKS' position = VALUE #( row = 150 column = 330 width = 90 ) ) tabstrip = 'TAB_DICTIONARY' text = 'Checks' subscreen = screen_table ucomm = 'CHECKS' ) ).
    io_builder->add_tab( VALUE #( control = VALUE #( name = 'TAB_TECHNICAL' position = VALUE #( row = 150 column = 430 width = 110 ) ) tabstrip = 'TAB_DICTIONARY' text = 'Technical settings' subscreen = screen_table ucomm = 'TECHNICAL' ) ).
    add_field_table( io_builder = io_builder
                     iv_name    = 'TC_FIELDS'
                     iv_row     = 194
                     iv_rows    = 8 ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TAB_CHECKS' position = VALUE #( row = 476 column = 18 width = 200 ) ) text = 'Checks and entry help' ) ).
    io_builder->begin_table_control( VALUE #( control = VALUE #( name = 'TC_CHECKS' position = VALUE #( row = 506 column = 18 width = 560 height = 130 ) ) visible_rows = 3 selection_mode = 'NONE' with_hscroll = abap_true with_vscroll = abap_false ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_CHECKS' name = 'CHECK_FIELD' title = 'Field' data_type = VALUE #( typ = 'C' length = 30 ) width = 150 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_CHECKS' name = 'CHECK_TABLE' title = 'Check table' data_type = VALUE #( typ = 'C' length = 30 ) width = 150 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_CHECKS' name = 'CHECK_HELP' title = 'Search help' data_type = VALUE #( typ = 'C' length = 30 ) width = 180 ) ).
    io_builder->end_table_control( ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TAB_TECHNICAL' position = VALUE #( row = 654 column = 18 width = 200 ) ) text = 'Technical settings' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_TAB_TECHNICAL' position = VALUE #( row = 684 column = 18 width = 560 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CONTENTS' position = VALUE #( row = 726 column = 18 width = 120 ) ) text = 'Table Contents' ucomm = 'CONTENTS' ) ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_CHANGE_DETAILS' position = VALUE #( row = 726 column = 150 width = 96 ) ) text = 'Change' ucomm = 'CHANGE' ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_structure title = 'Dictionary: Display Structure' height = 360 ) ).
    add_header( io_builder = io_builder
                iv_prefix  = 'STR' ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_STR_INFO' position = VALUE #( row = 118 column = 18 width = 560 ) ) text = 'A structure has components but no delivery class, contents or technical settings.' ) ).
    add_field_table( io_builder = io_builder
                     iv_name    = 'TC_STR_FIELDS'
                     iv_row     = 154
                     iv_rows    = 3 ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_data_element title = 'Dictionary: Display Data Element' height = 330 ) ).
    add_header( io_builder = io_builder
                iv_prefix  = 'DTE' ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_DTE_DOMAIN' position = VALUE #( row = 122 column = 18 width = 150 ) ) text = 'Domain' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_DTE_DOMAIN' position = VALUE #( row = 118 column = 190 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_DTE_TYPE' position = VALUE #( row = 156 column = 18 width = 150 ) ) text = 'Data type' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_DTE_TYPE' position = VALUE #( row = 152 column = 190 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_DTE_SHORT' position = VALUE #( row = 190 column = 18 width = 150 ) ) text = 'Short label' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_DTE_SHORT' position = VALUE #( row = 186 column = 190 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_DTE_MEDIUM' position = VALUE #( row = 224 column = 18 width = 150 ) ) text = 'Medium label' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_DTE_MEDIUM' position = VALUE #( row = 220 column = 190 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_DTE_LONG' position = VALUE #( row = 258 column = 18 width = 150 ) ) text = 'Long label' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_DTE_LONG' position = VALUE #( row = 254 column = 190 width = 240 ) ) data_type = VALUE #( typ = 'C' length = 40 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_DTE_HEADING' position = VALUE #( row = 292 column = 18 width = 150 ) ) text = 'Column heading' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_DTE_HEADING' position = VALUE #( row = 288 column = 190 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_domain title = 'Dictionary: Display Domain' height = 380 ) ).
    add_header( io_builder = io_builder
                iv_prefix  = 'DOM' ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_DOM_TYPE' position = VALUE #( row = 122 column = 18 width = 150 ) ) text = 'Data type' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_DOM_TYPE' position = VALUE #( row = 118 column = 190 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_DOM_OUTPUT' position = VALUE #( row = 156 column = 18 width = 150 ) ) text = 'Output length' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_DOM_OUTPUT' position = VALUE #( row = 152 column = 190 width = 120 ) ) data_type = VALUE #( typ = 'N' length = 6 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_DOM_VALUE_TABLE' position = VALUE #( row = 190 column = 18 width = 150 ) ) text = 'Value table' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_DOM_VALUE_TABLE' position = VALUE #( row = 186 column = 190 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_DOM_FIXED' position = VALUE #( row = 224 column = 18 width = 200 ) ) text = 'Fixed values' ) ).
    io_builder->begin_table_control( VALUE #( control = VALUE #( name = 'TC_DOM_FIXED' position = VALUE #( row = 254 column = 18 width = 480 height = 130 ) ) visible_rows = 3 selection_mode = 'NONE' with_hscroll = abap_false with_vscroll = abap_false ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_DOM_FIXED' name = 'FIXED_VALUE' title = 'Fixed value' data_type = VALUE #( typ = 'C' length = 30 ) width = 150 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_DOM_FIXED' name = 'FIXED_TEXT' title = 'Short description' data_type = VALUE #( typ = 'C' length = 60 ) width = 300 ) ).
    io_builder->end_table_control( ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_view title = 'Dictionary: Display View' height = 430 ) ).
    add_header( io_builder = io_builder
                iv_prefix  = 'VIE' ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_VIE_TYPE' position = VALUE #( row = 122 column = 18 width = 150 ) ) text = 'View type' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_VIE_TYPE' position = VALUE #( row = 118 column = 190 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_VIE_TABLES' position = VALUE #( row = 156 column = 18 width = 150 ) ) text = 'Base tables' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_VIE_TABLES' position = VALUE #( row = 152 column = 190 width = 340 ) ) data_type = VALUE #( typ = 'C' length = 60 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_VIE_JOIN' position = VALUE #( row = 190 column = 18 width = 150 ) ) text = 'Join conditions' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_VIE_JOIN' position = VALUE #( row = 186 column = 190 width = 400 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_VIE_SELECTION' position = VALUE #( row = 224 column = 18 width = 150 ) ) text = 'Selection conditions' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_VIE_SELECTION' position = VALUE #( row = 220 column = 190 width = 400 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
    add_field_table( io_builder = io_builder
                     iv_name    = 'TC_VIE_FIELDS'
                     iv_row     = 258
                     iv_rows    = 4 ).
    io_builder->add_pushbutton( VALUE #( control = VALUE #( name = 'PB_VIE_CONTENTS' position = VALUE #( row = 424 column = 18 width = 120 ) ) text = 'Table Contents' ucomm = 'CONTENTS' ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_search_help title = 'Dictionary: Display Search Help' height = 370 ) ).
    add_header( io_builder = io_builder
                iv_prefix  = 'SHL' ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_SHL_METHOD' position = VALUE #( row = 122 column = 18 width = 170 ) ) text = 'Selection method' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_SHL_METHOD' position = VALUE #( row = 118 column = 210 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_SHL_DIALOG' position = VALUE #( row = 156 column = 18 width = 170 ) ) text = 'Dialog type' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_SHL_DIALOG' position = VALUE #( row = 152 column = 210 width = 260 ) ) data_type = VALUE #( typ = 'C' length = 40 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_SHL_PARAMS' position = VALUE #( row = 190 column = 18 width = 200 ) ) text = 'Search help parameters' ) ).
    io_builder->begin_table_control( VALUE #( control = VALUE #( name = 'TC_SHL_PARAMS' position = VALUE #( row = 220 column = 18 width = 600 height = 100 ) ) visible_rows = 2 selection_mode = 'NONE' with_hscroll = abap_true with_vscroll = abap_false ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_SHL_PARAMS' name = 'PARAM_NAME' title = 'Parameter' data_type = VALUE #( typ = 'C' length = 30 ) width = 150 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_SHL_PARAMS' name = 'PARAM_IMPORT' title = 'IMP' data_type = VALUE #( typ = 'C' length = 3 ) width = 70 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_SHL_PARAMS' name = 'PARAM_EXPORT' title = 'EXP' data_type = VALUE #( typ = 'C' length = 3 ) width = 70 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_SHL_PARAMS' name = 'PARAM_LPOS' title = 'LPos' data_type = VALUE #( typ = 'N' length = 4 ) width = 70 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_SHL_PARAMS' name = 'PARAM_SPOS' title = 'SPos' data_type = VALUE #( typ = 'N' length = 4 ) width = 70 ) ).
    io_builder->end_table_control( ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_lock_object title = 'Dictionary: Display Lock Object' height = 370 ) ).
    add_header( io_builder = io_builder
                iv_prefix  = 'ENQ' ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_ENQ_TABLE' position = VALUE #( row = 122 column = 18 width = 170 ) ) text = 'Primary table' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_ENQ_TABLE' position = VALUE #( row = 118 column = 210 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_ENQ_MODE' position = VALUE #( row = 156 column = 18 width = 170 ) ) text = 'Lock mode' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_ENQ_MODE' position = VALUE #( row = 152 column = 210 width = 240 ) ) data_type = VALUE #( typ = 'C' length = 40 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_ENQ_PARAMS' position = VALUE #( row = 190 column = 18 width = 200 ) ) text = 'Lock parameters' ) ).
    io_builder->begin_table_control( VALUE #( control = VALUE #( name = 'TC_ENQ_PARAMS' position = VALUE #( row = 220 column = 18 width = 540 height = 130 ) ) visible_rows = 3 selection_mode = 'NONE' with_hscroll = abap_true with_vscroll = abap_false ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_ENQ_PARAMS' name = 'LOCK_PARAM' title = 'Parameter' data_type = VALUE #( typ = 'C' length = 30 ) width = 150 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_ENQ_PARAMS' name = 'LOCK_TABLE' title = 'Table' data_type = VALUE #( typ = 'C' length = 30 ) width = 150 ) ).
    io_builder->add_table_column( VALUE #( table_control = 'TC_ENQ_PARAMS' name = 'LOCK_FIELD' title = 'Field' data_type = VALUE #( typ = 'C' length = 30 ) width = 150 ) ).
    io_builder->end_table_control( ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_table_type title = 'Dictionary: Display Table Type' height = 330 ) ).
    add_header( io_builder = io_builder
                iv_prefix  = 'TTY' ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TTY_LINE' position = VALUE #( row = 122 column = 18 width = 170 ) ) text = 'Line type' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_TTY_LINE' position = VALUE #( row = 118 column = 210 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TTY_ACCESS' position = VALUE #( row = 156 column = 18 width = 170 ) ) text = 'Access' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_TTY_ACCESS' position = VALUE #( row = 152 column = 210 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TTY_KEY' position = VALUE #( row = 190 column = 18 width = 170 ) ) text = 'Key category' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_TTY_KEY' position = VALUE #( row = 186 column = 210 width = 200 ) ) data_type = VALUE #( typ = 'C' length = 30 ) ) ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TTY_KEY_FIELDS' position = VALUE #( row = 224 column = 18 width = 170 ) ) text = 'Key fields' ) ).
    io_builder->add_output_field( VALUE #( control = VALUE #( name = 'O_TTY_KEY_FIELDS' position = VALUE #( row = 220 column = 210 width = 340 ) ) data_type = VALUE #( typ = 'C' length = 60 ) ) ).
    io_builder->end_screen( ).

    io_builder->begin_screen( VALUE #( number = screen_type_group title = 'Dictionary: Display Type Group' height = 330 ) ).
    add_header( io_builder = io_builder
                iv_prefix  = 'TYP' ).
    io_builder->add_text( VALUE #( control = VALUE #( name = 'T_TYP_SOURCE' position = VALUE #( row = 122 column = 18 width = 300 ) ) text = 'Type group source' ) ).
    lv_column = 1.
    WHILE lv_column <= 5.
      io_builder->add_output_field( VALUE #( control = VALUE #( name = CONV #( |O_TYP_LINE_{ lv_column }| ) position = VALUE #( row = 122 + lv_column * 32 column = 18 width = 560 ) ) data_type = VALUE #( typ = 'C' length = 120 ) ) ).
      lv_column = lv_column + 1.
    ENDWHILE.
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD add_flow.
    io_builder->begin_screen( iv_screen ).
    io_builder->begin_pbo( ).
    io_builder->add_module( VALUE #( name = |PBO_{ iv_screen }| ) ).
    io_builder->end_processing( ).
    io_builder->begin_pai( ).
    io_builder->add_module( VALUE #( name = |PAI_{ iv_screen }| on_input = abap_true ) ).
    io_builder->end_processing( ).
    IF iv_field IS NOT INITIAL.
      io_builder->begin_value_request( iv_field ).
      io_builder->add_module( VALUE #( name = |POV_{ iv_screen }| ) ).
      io_builder->end_processing( ).
      io_builder->begin_help_request( iv_field ).
      io_builder->add_module( VALUE #( name = |POH_{ iv_screen }| ) ).
      io_builder->end_processing( ).
    ENDIF.
    io_builder->end_screen( ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~build_flow_logic.
    add_flow( io_builder = io_builder
              iv_screen  = screen_chooser
              iv_field   = 'P_OBJECT_NAME' ).
    LOOP AT detail_screens( ) INTO DATA(ls_screen).
      add_flow( io_builder = io_builder
                iv_screen  = ls_screen-number ).
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~initialization.
    put_value( EXPORTING iv_name = 'P_OBJECT_TYPE'
                         iv_value = zif_gg_system_types_v1=>ddic_table CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'P_CAPABILITY'
                         iv_value = 'Display-only deployment: Dictionary changes require a repository activation pipeline.' CHANGING ct_values = ct_values ).
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_output_module.
    DATA(lo_service) = NEW zcl_gg_system_dictionary( ).
    DATA(ls_capabilities) = lo_service->zif_gg_dictionary_service_v1~get_capabilities( ).

    io_session->get_dialog( )->set_status( VALUE #(
      status       = 'SE11'
      active_ucomm = VALUE #( ( 'DISPLAY' ) ( 'CHANGE' ) ( 'CREATE' ) ( 'CONTENTS' ) ) ) ).
    put_value( EXPORTING iv_name = 'P_CAPABILITY'
                         iv_value = ls_capabilities-explanation CHANGING ct_values = ct_values ).
    ct_states[ name = 'PB_CHANGE' ]-enabled = abap_false.
    ct_states[ name = 'PB_CHANGE_DETAILS' ]-enabled = abap_false.
    ct_states[ name = 'PB_CREATE' ]-enabled = abap_false.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_input_module.
    DATA(lo_service) = NEW zcl_gg_system_dictionary( ).
    DATA lv_type TYPE string.
    DATA lv_name TYPE string.
    DATA lv_screen TYPE zif_gg_dynpro_types_v1=>ty_screen_number.
    DATA ls_object TYPE zif_gg_system_types_v1=>ty_ddic_object.

    IF is_context-ucomm = 'BACK'.
      IF is_context-screen = screen_chooser.
        io_session->get_navigation( )->leave_program( ).
      ELSE.
        io_session->get_dialog( )->set_next_screen( screen_chooser ).
        io_session->get_dialog( )->leave_screen( ).
      ENDIF.
      RETURN.
    ENDIF.
    IF is_context-ucomm = 'CHANGE' OR is_context-ucomm = 'CREATE'.
      io_session->message( VALUE #(
        type = zif_gg_session_types_v1=>message_type_error
        text = 'This display-only deployment does not provide Dictionary changes or creation.' ) ).
      RETURN.
    ENDIF.
    IF is_context-ucomm = 'CONTENTS'.
      IF is_context-screen <> screen_table AND is_context-screen <> screen_view.
        io_session->message( VALUE #(
          type = zif_gg_session_types_v1=>message_type_error
          text = 'Table contents are only available for tables and views.' ) ).
        RETURN.
      ENDIF.
      io_session->get_navigation( )->leave_to_transaction( VALUE #( tcode = 'SE16' ) ).
      RETURN.
    ENDIF.
    IF is_context-screen = screen_table
        AND ( is_context-ucomm = 'ATTRIBUTES' OR is_context-ucomm = 'FIELDS'
          OR is_context-ucomm = 'KEYS' OR is_context-ucomm = 'CHECKS'
          OR is_context-ucomm = 'TECHNICAL' ).
      RETURN.
    ENDIF.
    IF is_context-screen = screen_chooser AND is_context-ucomm = 'DISPLAY'.
      lv_type = value_of( it_values = ct_values
                          iv_name   = 'P_OBJECT_TYPE' ).
      lv_name = value_of( it_values = ct_values
                          iv_name   = 'P_OBJECT_NAME' ).
      ls_object = lo_service->zif_gg_dictionary_service_v1~get_object(
        iv_object_type = lv_type
        iv_name        = lv_name ).
      IF ls_object-error IS NOT INITIAL.
        io_session->message( VALUE #(
          type  = zif_gg_session_types_v1=>message_type_error
          text  = ls_object-error
          field = 'P_OBJECT_NAME' ) ).
        RETURN.
      ENDIF.
      lv_screen = screen_for_type( ls_object-object_type ).
      IF lv_screen IS INITIAL.
        io_session->message( VALUE #(
          type  = zif_gg_session_types_v1=>message_type_error
          text  = 'Dictionary object type has no display screen in this deployment.'
          field = 'P_OBJECT_TYPE' ) ).
        RETURN.
      ENDIF.
      CASE ls_object-object_type.
        WHEN zif_gg_system_types_v1=>ddic_table.
          put_table_detail( EXPORTING is_object = ls_object
                            CHANGING ct_values  = ct_values ).
        WHEN zif_gg_system_types_v1=>ddic_structure.
          put_header( EXPORTING iv_prefix = 'STR'
                                is_object = ls_object
                      CHANGING ct_values  = ct_values ).
          put_field_table( EXPORTING iv_name   = 'TC_STR_FIELDS'
                                     it_fields = ls_object-fields
                           CHANGING ct_values  = ct_values ).
        WHEN zif_gg_system_types_v1=>ddic_data_element.
          put_data_element_detail( EXPORTING is_object = ls_object
                                   CHANGING ct_values  = ct_values ).
        WHEN zif_gg_system_types_v1=>ddic_domain.
          put_domain_detail( EXPORTING is_object = ls_object
                             CHANGING ct_values  = ct_values ).
        WHEN zif_gg_system_types_v1=>ddic_view.
          put_view_detail( EXPORTING is_object = ls_object
                           CHANGING ct_values  = ct_values ).
        WHEN zif_gg_system_types_v1=>ddic_search_help.
          put_search_help_detail( EXPORTING is_object = ls_object
                                  CHANGING ct_values  = ct_values ).
        WHEN zif_gg_system_types_v1=>ddic_lock_object.
          put_lock_object_detail( EXPORTING is_object = ls_object
                                  CHANGING ct_values  = ct_values ).
        WHEN zif_gg_system_types_v1=>ddic_table_type.
          put_table_type_detail( EXPORTING is_object = ls_object
                                 CHANGING ct_values  = ct_values ).
        WHEN OTHERS.
          put_type_group_detail( EXPORTING is_object = ls_object
                                 CHANGING ct_values  = ct_values ).
      ENDCASE.
      io_session->get_dialog( )->set_next_screen( lv_screen ).
      io_session->get_dialog( )->leave_screen( ).
    ENDIF.
  ENDMETHOD.

  METHOD put_table_detail.
    DATA lv_row TYPE i.

    put_header( EXPORTING iv_prefix = 'TAB'
                          is_object = is_object
                CHANGING ct_values  = ct_values ).
    put_value( EXPORTING iv_name = 'O_TAB_DELIVERY'
                         iv_value = is_object-delivery_class CHANGING ct_values = ct_values ).
    put_field_table( EXPORTING iv_name   = 'TC_FIELDS'
                               it_fields = is_object-fields
                     CHANGING ct_values  = ct_values ).
    LOOP AT is_object-fields INTO DATA(ls_field)
        WHERE check_table IS NOT INITIAL OR search_help IS NOT INITIAL.
      lv_row = lv_row + 1.
      put_cell( EXPORTING iv_container = 'TC_CHECKS'
                          iv_name = 'CHECK_FIELD'
                          iv_row = lv_row
                          iv_value = ls_field-name CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = 'TC_CHECKS'
                          iv_name = 'CHECK_TABLE'
                          iv_row = lv_row
                          iv_value = ls_field-check_table CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = 'TC_CHECKS'
                          iv_name = 'CHECK_HELP'
                          iv_row = lv_row
                          iv_value = ls_field-search_help CHANGING ct_values = ct_values ).
    ENDLOOP.
    put_value( EXPORTING iv_name = 'O_TAB_TECHNICAL'
                         iv_value = |Data class { is_object-technical-data_class }, size category { is_object-technical-size_category }, { is_object-technical-buffering }, log changes { COND string( WHEN is_object-technical-log_changes = abap_true THEN 'on' ELSE 'off' ) }| CHANGING ct_values = ct_values ).
  ENDMETHOD.

  METHOD put_view_detail.
    put_header( EXPORTING iv_prefix = 'VIE'
                          is_object = is_object
                CHANGING ct_values  = ct_values ).
    put_value( EXPORTING iv_name = 'O_VIE_TYPE'
                         iv_value = is_object-view-view_type CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_VIE_TABLES'
                         iv_value = joined( is_object-view-base_tables ) CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_VIE_JOIN'
                         iv_value = joined( is_object-view-join_conditions ) CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_VIE_SELECTION'
                         iv_value = joined( is_object-view-selection_conditions ) CHANGING ct_values = ct_values ).
    put_field_table( EXPORTING iv_name   = 'TC_VIE_FIELDS'
                               it_fields = is_object-fields
                     CHANGING ct_values  = ct_values ).
  ENDMETHOD.

  METHOD put_data_element_detail.
    put_header( EXPORTING iv_prefix = 'DTE'
                          is_object = is_object
                CHANGING ct_values  = ct_values ).
    put_value( EXPORTING iv_name = 'O_DTE_DOMAIN'
                         iv_value = is_object-data_element-domain CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_DTE_TYPE'
                         iv_value = |{ is_object-data_element-data_type } { is_object-data_element-length }| CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_DTE_SHORT'
                         iv_value = is_object-data_element-short_label CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_DTE_MEDIUM'
                         iv_value = is_object-data_element-medium_label CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_DTE_LONG'
                         iv_value = is_object-data_element-long_label CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_DTE_HEADING'
                         iv_value = is_object-data_element-heading CHANGING ct_values = ct_values ).
  ENDMETHOD.

  METHOD put_domain_detail.
    DATA lv_row TYPE i.

    put_header( EXPORTING iv_prefix = 'DOM'
                          is_object = is_object
                CHANGING ct_values  = ct_values ).
    put_value( EXPORTING iv_name = 'O_DOM_TYPE'
                         iv_value = |{ is_object-domain-data_type } { is_object-domain-length }| CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_DOM_OUTPUT'
                         iv_value = |{ is_object-domain-output_length }| CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_DOM_VALUE_TABLE'
                         iv_value = is_object-domain-value_table CHANGING ct_values = ct_values ).
    LOOP AT is_object-domain-fixed_values INTO DATA(ls_fixed).
      lv_row = sy-tabix.
      put_cell( EXPORTING iv_container = 'TC_DOM_FIXED'
                          iv_name = 'FIXED_VALUE'
                          iv_row = lv_row
                          iv_value = ls_fixed-value CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = 'TC_DOM_FIXED'
                          iv_name = 'FIXED_TEXT'
                          iv_row = lv_row
                          iv_value = ls_fixed-description CHANGING ct_values = ct_values ).
    ENDLOOP.
  ENDMETHOD.

  METHOD put_search_help_detail.
    DATA lv_row TYPE i.

    put_header( EXPORTING iv_prefix = 'SHL'
                          is_object = is_object
                CHANGING ct_values  = ct_values ).
    put_value( EXPORTING iv_name = 'O_SHL_METHOD'
                         iv_value = is_object-search_help-selection_method CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_SHL_DIALOG'
                         iv_value = is_object-search_help-dialog_type CHANGING ct_values = ct_values ).
    LOOP AT is_object-search_help-parameters INTO DATA(ls_param).
      lv_row = sy-tabix.
      put_cell( EXPORTING iv_container = 'TC_SHL_PARAMS'
                          iv_name = 'PARAM_NAME'
                          iv_row = lv_row
                          iv_value = ls_param-name CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = 'TC_SHL_PARAMS'
                          iv_name = 'PARAM_IMPORT'
                          iv_row = lv_row
                          iv_value = COND string( WHEN ls_param-import = abap_true THEN 'X' ELSE `` ) CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = 'TC_SHL_PARAMS'
                          iv_name = 'PARAM_EXPORT'
                          iv_row = lv_row
                          iv_value = COND string( WHEN ls_param-export = abap_true THEN 'X' ELSE `` ) CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = 'TC_SHL_PARAMS'
                          iv_name = 'PARAM_LPOS'
                          iv_row = lv_row
                          iv_value = |{ ls_param-list_position }| CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = 'TC_SHL_PARAMS'
                          iv_name = 'PARAM_SPOS'
                          iv_row = lv_row
                          iv_value = |{ ls_param-screen_position }| CHANGING ct_values = ct_values ).
    ENDLOOP.
  ENDMETHOD.

  METHOD put_lock_object_detail.
    DATA lv_row TYPE i.

    put_header( EXPORTING iv_prefix = 'ENQ'
                          is_object = is_object
                CHANGING ct_values  = ct_values ).
    put_value( EXPORTING iv_name = 'O_ENQ_TABLE'
                         iv_value = is_object-lock_object-primary_table CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_ENQ_MODE'
                         iv_value = is_object-lock_object-lock_mode CHANGING ct_values = ct_values ).
    LOOP AT is_object-lock_object-parameters INTO DATA(ls_param).
      lv_row = sy-tabix.
      put_cell( EXPORTING iv_container = 'TC_ENQ_PARAMS'
                          iv_name = 'LOCK_PARAM'
                          iv_row = lv_row
                          iv_value = ls_param-name CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = 'TC_ENQ_PARAMS'
                          iv_name = 'LOCK_TABLE'
                          iv_row = lv_row
                          iv_value = ls_param-table_name CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = 'TC_ENQ_PARAMS'
                          iv_name = 'LOCK_FIELD'
                          iv_row = lv_row
                          iv_value = ls_param-field_name CHANGING ct_values = ct_values ).
    ENDLOOP.
  ENDMETHOD.

  METHOD put_table_type_detail.
    put_header( EXPORTING iv_prefix = 'TTY'
                          is_object = is_object
                CHANGING ct_values  = ct_values ).
    put_value( EXPORTING iv_name = 'O_TTY_LINE'
                         iv_value = is_object-table_type-line_type CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_TTY_ACCESS'
                         iv_value = is_object-table_type-access_kind CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_TTY_KEY'
                         iv_value = is_object-table_type-key_kind CHANGING ct_values = ct_values ).
    put_value( EXPORTING iv_name = 'O_TTY_KEY_FIELDS'
                         iv_value = joined( is_object-table_type-key_fields ) CHANGING ct_values = ct_values ).
  ENDMETHOD.

  METHOD put_type_group_detail.
    put_header( EXPORTING iv_prefix = 'TYP'
                          is_object = is_object
                CHANGING ct_values  = ct_values ).
    LOOP AT is_object-type_group-source_lines INTO DATA(lv_line).
      IF sy-tabix > 5.
        EXIT.
      ENDIF.
      put_value( EXPORTING iv_name = CONV #( |O_TYP_LINE_{ sy-tabix }| )
                           iv_value = |{ sy-tabix WIDTH = 3 ALIGN = RIGHT PAD = '0' } { lv_line }| CHANGING ct_values = ct_values ).
    ENDLOOP.
  ENDMETHOD.

  METHOD put_field_table.
    LOOP AT it_fields INTO DATA(ls_field).
      DATA(lv_row) = sy-tabix.
      put_cell( EXPORTING iv_container = iv_name
                          iv_name = 'FIELD_POSITION'
                          iv_row = lv_row
                          iv_value = |{ ls_field-position }| CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = iv_name
                          iv_name = 'FIELD_NAME'
                          iv_row = lv_row
                          iv_value = ls_field-name CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = iv_name
                          iv_name = 'FIELD_KEY'
                          iv_row = lv_row
                          iv_value = COND string( WHEN ls_field-key_flag = abap_true THEN 'X' ELSE `` ) CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = iv_name
                          iv_name = 'FIELD_ELEMENT'
                          iv_row = lv_row
                          iv_value = ls_field-data_element CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = iv_name
                          iv_name = 'FIELD_TYPE'
                          iv_row = lv_row
                          iv_value = ls_field-data_type CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = iv_name
                          iv_name = 'FIELD_LENGTH'
                          iv_row = lv_row
                          iv_value = |{ ls_field-length }| CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = iv_name
                          iv_name = 'FIELD_DECIMALS'
                          iv_row = lv_row
                          iv_value = |{ ls_field-decimals }| CHANGING ct_values = ct_values ).
      put_cell( EXPORTING iv_container = iv_name
                          iv_name = 'FIELD_TEXT'
                          iv_row = lv_row
                          iv_value = ls_field-description CHANGING ct_values = ct_values ).
    ENDLOOP.
  ENDMETHOD.

  METHOD joined.
    LOOP AT it_lines INTO DATA(lv_line).
      IF rv_text IS INITIAL.
        rv_text = lv_line.
      ELSE.
        rv_text = |{ rv_text }; { lv_line }|.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_value_request.
    DATA(lo_service) = NEW zcl_gg_system_dictionary( ).
    DATA lv_type TYPE string.

    READ TABLE it_values INTO DATA(ls_type) WITH KEY container = `` name = 'P_OBJECT_TYPE' row = 0.
    IF sy-subrc = 0.
      lv_type = ls_type-value.
    ENDIF.
    IF is_context-field = 'P_OBJECT_NAME'.
      LOOP AT lo_service->zif_gg_dictionary_service_v1~get_names( lv_type ) INTO DATA(lv_name).
        APPEND VALUE #( name = 'P_OBJECT_NAME' value = lv_name ) TO rt_values.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_dynpro_v1~process_on_help_request.
    CASE is_context-field.
      WHEN 'P_OBJECT_NAME'.
        rv_text = 'Use F4 to select a permitted object of the chosen kind.'
          && ` The value help only lists names the server allows for that kind.`.
      WHEN 'P_OBJECT_TYPE'.
        rv_text = 'Object kinds remain distinct; each kind opens its own display screen.'
          && ` Unsupported kinds are rejected without metadata leakage.`.
    ENDCASE.
  ENDMETHOD.

  METHOD put_value.
    FIELD-SYMBOLS <ls_value> TYPE zif_gg_dynpro_types_v1=>ty_value.
    READ TABLE ct_values ASSIGNING <ls_value> WITH KEY container = `` name = iv_name row = 0.
    IF sy-subrc <> 0.
      INSERT VALUE #( name = iv_name value = iv_value ) INTO TABLE ct_values.
    ELSE.
      <ls_value>-value = iv_value.
    ENDIF.
  ENDMETHOD.

  METHOD value_of.
    READ TABLE it_values INTO DATA(ls_value) WITH KEY container = `` name = iv_name row = 0.
    IF sy-subrc = 0.
      rv_value = ls_value-value.
    ENDIF.
  ENDMETHOD.

  METHOD put_cell.
    FIELD-SYMBOLS <ls_value> TYPE zif_gg_dynpro_types_v1=>ty_value.
    READ TABLE ct_values ASSIGNING <ls_value> WITH KEY container = iv_container name = iv_name row = iv_row.
    IF sy-subrc <> 0.
      INSERT VALUE #( container = iv_container name = iv_name row = iv_row value = iv_value ) INTO TABLE ct_values.
    ELSE.
      <ls_value>-value = iv_value.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
