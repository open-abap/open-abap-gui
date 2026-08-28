CLASS cl_gui_chart_engine DEFINITION PUBLIC INHERITING FROM cl_gui_control.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        parent TYPE REF TO cl_gui_container OPTIONAL
        name   TYPE string OPTIONAL
      EXCEPTIONS
        cntl_error
        cntl_system_error
        create_error
        lifetime_error.

    METHODS set_data
      IMPORTING
        data  TYPE string OPTIONAL
        xdata TYPE xstring OPTIONAL
        size  TYPE i OPTIONAL.

    METHODS render
      EXCEPTIONS
        cntl_error.

ENDCLASS.

CLASS cl_gui_chart_engine IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    cl_gui_control=>initialize(
      control = me
      parent = parent
      kind = 'CHART_ENGINE' ).
    IF parent IS BOUND.
      parent->add_child( me ).
    ENDIF.
  ENDMETHOD.

  METHOD set_data.
    IF data IS SUPPLIED.
      cl_gui_control=>set_payload( control = me payload = data ).
    ENDIF.
    IF xdata IS SUPPLIED.
      cl_gui_control=>set_payload( control = me payload = |binary chart data ({ size })| ).
    ENDIF.
  ENDMETHOD.

  METHOD render.
    cl_gui_control=>set_html( control = me html = |<div role="img" aria-label="Chart">Chart data</div>| ).
  ENDMETHOD.

ENDCLASS.
