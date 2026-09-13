INTERFACE zif_gg_context_menu_v1 PUBLIC.

* Optional adapter for classic ON CTMENU forms. The host asks for the menu
* after PBO so dynamic disabled/hidden entries reflect current program state.
  METHODS get_context_menu
    IMPORTING
      iv_field       TYPE zif_gg_dynpro_types_v1=>ty_name
      io_session     TYPE REF TO zif_gg_session_v1
    RETURNING
      VALUE(ro_menu) TYPE REF TO cl_ctmenu.

ENDINTERFACE.
