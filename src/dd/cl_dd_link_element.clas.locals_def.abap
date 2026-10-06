CLASS lcl_link_bridge DEFINITION INHERITING FROM cl_gui_control.
  PUBLIC SECTION.
    METHODS constructor IMPORTING link TYPE REF TO cl_dd_link_element.
    METHODS get_event RETURNING VALUE(result) TYPE string.
  PROTECTED SECTION.
    METHODS dispatch_frontend_event REDEFINITION.
    METHODS is_application_event REDEFINITION.
  PRIVATE SECTION.
    DATA mo_link TYPE REF TO cl_dd_link_element.
ENDCLASS.
