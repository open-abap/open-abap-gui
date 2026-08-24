INTERFACE if_graphic_proxy PUBLIC.

  CONSTANTS co_port_diagram TYPE i VALUE 1.
  CONSTANTS co_port_chart TYPE i VALUE 2.
  CONSTANTS co_port_chart1 TYPE i VALUE 3.
  CONSTANTS co_port_chart_x_prim_axis TYPE i VALUE 5.
  CONSTANTS co_port_chart_y_prim_axis TYPE i VALUE 11.
  CONSTANTS co_port_chart_z_prim_axis TYPE i VALUE 17.

  EVENTS graphic_closed
    EXPORTING
      VALUE(event) TYPE any.

  METHODS init
    IMPORTING
      dc           TYPE REF TO object OPTIONAL
      filter_list  TYPE any OPTIONAL
      prod_id      TYPE char8 OPTIONAL
      prod_prio    TYPE numc3 OPTIONAL
      force_prod   TYPE abap_bool OPTIONAL
      parent       TYPE REF TO cl_gui_container OPTIONAL
      width        TYPE i OPTIONAL
      height       TYPE i OPTIONAL
      top          TYPE i OPTIONAL
      left         TYPE i OPTIONAL
      evtcode_list TYPE cntl_simple_events OPTIONAL
    EXPORTING
      retval       TYPE symsgno.

  METHODS activate
    EXPORTING
      retval TYPE symsgno.

  METHODS deactivate
    EXPORTING
      retval TYPE symsgno.

  METHODS free
    EXPORTING
      retval TYPE symsgno.

  METHODS add_cu_bundle
    IMPORTING
      port       TYPE i
      key        TYPE clike OPTIONAL
      bundle     TYPE REF TO object OPTIONAL
      cuobj_list TYPE any OPTIONAL
    EXPORTING
      retval     TYPE symsgno.

ENDINTERFACE.
