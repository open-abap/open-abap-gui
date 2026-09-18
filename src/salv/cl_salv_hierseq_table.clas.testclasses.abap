CLASS ltcl_salv_hierseq_support DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS renders_related_levels FOR TESTING
      RAISING
        cx_salv_data_error
        cx_salv_not_found.
    METHODS hides_technical_levels FOR TESTING
      RAISING
        cx_salv_data_error
        cx_salv_not_found.
ENDCLASS.

CLASS ltcl_salv_hierseq_support IMPLEMENTATION.
  METHOD renders_related_levels.
    TYPES: BEGIN OF ty_header,
             order_id TYPE i,
             customer TYPE string,
           END OF ty_header.
    TYPES: BEGIN OF ty_item,
             order_id TYPE i,
             flight   TYPE string,
             price    TYPE p LENGTH 8 DECIMALS 2,
           END OF ty_item.
    DATA lt_headers TYPE STANDARD TABLE OF ty_header WITH DEFAULT KEY.
    DATA lt_items TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.
    DATA lt_binding TYPE salv_t_hierseq_binding.
    DATA lo_hierseq TYPE REF TO cl_salv_hierseq_table.

    APPEND VALUE #( order_id = 100 customer = 'Lufthansa' ) TO lt_headers.
    APPEND VALUE #( order_id = 100 flight = 'LH400' price = '120.00' ) TO lt_items.
    lt_binding = VALUE #( ( master = 'ORDER_ID' slave = 'ORDER_ID' ) ).
    cl_gui_control=>clear( ).
    cl_salv_hierseq_table=>factory(
      EXPORTING
        t_binding_level1_level2 = lt_binding
      IMPORTING
        r_hierseq               = lo_hierseq
      CHANGING
        t_table_level1          = lt_headers
        t_table_level2          = lt_items ).
    lo_hierseq->get_level( 1 )->set_items_expanded( abap_true ).
    lo_hierseq->display( ).

    DATA(lv_html) = cl_gui_control=>render_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'SALV hierarchy level 1' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Lufthansa' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'LH400' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '120.00' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'data-total="true" data-fieldname="PRICE">120.00</td>' ) ).
  ENDMETHOD.

  METHOD hides_technical_levels.
    TYPES: BEGIN OF ty_header,
             group_id   TYPE c LENGTH 8,
             group_name TYPE c LENGTH 20,
             owner      TYPE c LENGTH 12,
           END OF ty_header.
    TYPES: BEGIN OF ty_item,
             group_id TYPE c LENGTH 8,
             item_id  TYPE c LENGTH 8,
             name     TYPE string,
             quantity TYPE i,
             price    TYPE p LENGTH 8 DECIMALS 2,
           END OF ty_item.
    DATA lt_headers TYPE STANDARD TABLE OF ty_header WITH DEFAULT KEY.
    DATA lt_items TYPE STANDARD TABLE OF ty_item WITH DEFAULT KEY.
    DATA lo_hierseq TYPE REF TO cl_salv_hierseq_table.

    lt_headers = VALUE #( ( group_id = 'G1' group_name = 'Group' owner = 'Owner' ) ).
    lt_items = VALUE #( ( group_id = 'G1' item_id = 'I1' name = 'Visible item' quantity = 2 price = '12.50' ) ).
    cl_salv_hierseq_table=>factory(
      EXPORTING
        t_binding_level1_level2 = VALUE #( ( master = 'GROUP_ID' slave = 'GROUP_ID' ) )
      IMPORTING
        r_hierseq               = lo_hierseq
      CHANGING
        t_table_level1          = lt_headers
        t_table_level2          = lt_items ).
    lo_hierseq->get_columns( 1 )->get_column( 'GROUP_ID' )->set_technical( abap_true ).
    lo_hierseq->get_columns( 2 )->get_column( 'GROUP_ID' )->set_technical( abap_true ).
    lo_hierseq->display( ).

    DATA(lv_html) = cl_gui_control=>render_html( ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Group' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Owner' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'Visible item' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'price' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS '>2</td>' ) ).
    cl_abap_unit_assert=>assert_false( act = xsdbool( lv_html CS '>G1<' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'group name' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'item id' ) ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_html CS 'quantity' ) ).
  ENDMETHOD.
ENDCLASS.
