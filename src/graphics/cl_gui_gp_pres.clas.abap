CLASS cl_gui_gp_pres DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.

    INTERFACES if_graphic_proxy.

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

  METHOD set_dc_names.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD if_graphic_proxy~init.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD if_graphic_proxy~activate.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD if_graphic_proxy~deactivate.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD if_graphic_proxy~free.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD if_graphic_proxy~add_cu_bundle.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
