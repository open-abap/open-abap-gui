CLASS cl_gui_custom_container DEFINITION PUBLIC INHERITING FROM cl_gui_container.
  PUBLIC SECTION.
    DATA mv_container_name TYPE string READ-ONLY.
    DATA mv_repid TYPE sy-repid READ-ONLY.
    DATA mv_dynnr TYPE sy-dynnr READ-ONLY.
    DATA mv_lifetime TYPE i READ-ONLY.

    METHODS constructor
      IMPORTING
        container_name          TYPE c
        parent                  TYPE REF TO cl_gui_container OPTIONAL
        repid                   TYPE sy-repid OPTIONAL
        no_autodef_progid_dynnr TYPE abap_bool OPTIONAL
        lifetime                TYPE i OPTIONAL
        dynnr                   TYPE sy-dynnr OPTIONAL.
ENDCLASS.

CLASS cl_gui_custom_container IMPLEMENTATION.

  METHOD constructor.
    mv_container_name = CONV string( container_name ).
    mv_repid = repid.
    mv_dynnr = dynnr.
    mv_lifetime = lifetime.
    cl_gui_control=>initialize(
      control = me
      parent  = parent
      kind    = 'CUSTOM_CONTAINER' ).
    cl_gui_control=>set_payload(
      control = me
      payload = |name={ mv_container_name }; repid={ mv_repid }; dynnr={ mv_dynnr }; lifetime={ mv_lifetime }; parent={ COND string( WHEN parent IS BOUND THEN parent->control_id ELSE `` ) }| ).
    IF parent IS BOUND.
      parent->add_child( me ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
