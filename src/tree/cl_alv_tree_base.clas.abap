CLASS cl_alv_tree_base DEFINITION PUBLIC.
  PUBLIC SECTION.
    CONSTANTS c_hierarchy_column_name TYPE string VALUE '&Hierarchy'.

    CONSTANTS mc_fc_calculate TYPE ui_func VALUE '&CALC'.
    CONSTANTS mc_fc_current_variant TYPE ui_func VALUE '&COL0'.
    CONSTANTS mc_fc_load_variant TYPE ui_func VALUE '&LOAD'.
    CONSTANTS mc_fc_maintain_variant TYPE ui_func VALUE '&MAINTAIN'.
    CONSTANTS mc_fc_print_back TYPE ui_func VALUE '&PRINT_BACK'.
    CONSTANTS mc_fc_print_back_all TYPE ui_func VALUE '&PRINT_BACK_ALL'.
    CONSTANTS mc_fc_save_variant TYPE ui_func VALUE '&SAVE'.

    METHODS get_frontend_fieldcatalog
      EXPORTING
        VALUE(et_fieldcatalog) TYPE lvc_t_fcat.

ENDCLASS.

CLASS cl_alv_tree_base IMPLEMENTATION.

  METHOD get_frontend_fieldcatalog.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.