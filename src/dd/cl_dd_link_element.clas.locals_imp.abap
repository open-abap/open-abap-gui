CLASS lcl_link_bridge IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    mo_link = link.
    zcl_gg_gui_runtime=>initialize( control = me
                                kind    = 'EVENT_BRIDGE' ).
  ENDMETHOD.

  METHOD is_application_event.
    result = xsdbool( event = 'CLICKED' ).
  ENDMETHOD.

  METHOD get_event.
    result = frontend_event_value( event = 'CLICKED' ).
  ENDMETHOD.

  METHOD dispatch_frontend_event.
    IF event = 'CLICKED'.
      mo_link->raise_clicked( ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
