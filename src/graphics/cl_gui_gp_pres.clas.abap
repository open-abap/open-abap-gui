CLASS cl_gui_gp_pres DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.

    INTERFACES if_graphic_proxy.

    METHODS constructor.

    CONSTANTS co_prod_chart TYPE char8 VALUE 'CHART'.
    CONSTANTS co_prod_export TYPE char8 VALUE 'EXPORT'.
    CONSTANTS co_prod_sap TYPE char8 VALUE 'SAP'.
    CONSTANTS co_prod_sapocx TYPE char8 VALUE 'SAPOCX'.

    METHODS set_dc_names
      IMPORTING
        dim1      TYPE clike OPTIONAL
        dim2      TYPE clike OPTIONAL
        dim3      TYPE clike OPTIONAL
        filter    TYPE clike OPTIONAL
        grp_id    TYPE clike OPTIONAL
        objref_id TYPE clike OPTIONAL
        obj_id    TYPE clike OPTIONAL
        text      TYPE clike OPTIONAL
        t_dim1    TYPE clike OPTIONAL
        t_grp_id  TYPE clike OPTIONAL
      EXPORTING
        retval    TYPE symsgno.

ENDCLASS.

CLASS cl_gui_gp_pres IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    cl_gui_control=>initialize(
      control = me
      kind    = 'GP_PRES' ).
    cl_gui_control=>set_payload(
      control = me
      payload = 'Native GFW business-graphics proxy unavailable; use the accessible chart/table fallback' ).
  ENDMETHOD.

  METHOD set_dc_names.
    cl_gui_control=>set_payload(
      control = me
      payload = 'Native GFW business-graphics proxy unavailable; use the accessible chart/table fallback' ).
    retval = '004'.
  ENDMETHOD.

  METHOD if_graphic_proxy~init.
    cl_gui_control=>set_payload(
      control = me
      payload = 'Native GFW business-graphics proxy unavailable; audit only' ).
    retval = '004'.
  ENDMETHOD.

  METHOD if_graphic_proxy~activate.
    cl_gui_control=>set_payload(
      control = me
      payload = 'Native GFW business-graphics proxy unavailable; activate was not performed' ).
    retval = '004'.
  ENDMETHOD.

  METHOD if_graphic_proxy~deactivate.
    retval = '004'.
  ENDMETHOD.

  METHOD if_graphic_proxy~free.
    retval = '004'.
  ENDMETHOD.

  METHOD if_graphic_proxy~add_cu_bundle.
    retval = '004'.
  ENDMETHOD.

ENDCLASS.
