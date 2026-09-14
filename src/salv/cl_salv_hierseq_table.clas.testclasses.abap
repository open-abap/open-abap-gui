CLASS ltcl_salv_hierseq_support DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS renders_related_levels FOR TESTING
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
  ENDMETHOD.
ENDCLASS.
