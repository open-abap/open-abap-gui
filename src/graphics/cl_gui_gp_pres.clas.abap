CLASS cl_gui_gp_pres DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.

    INTERFACES if_graphic_proxy.

    METHODS set_dc_names
      IMPORTING
        objid  TYPE clike OPTIONAL
        grpid  TYPE clike OPTIONAL
        x_val  TYPE clike OPTIONAL
        y_val  TYPE clike OPTIONAL
      EXPORTING
        retval TYPE i.

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
