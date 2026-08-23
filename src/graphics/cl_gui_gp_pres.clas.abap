CLASS cl_gui_gp_pres DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.

    INTERFACES if_graphic_proxy.

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

  METHOD if_graphic_proxy~activate.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD if_graphic_proxy~deactivate.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
