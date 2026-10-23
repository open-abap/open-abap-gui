REPORT zgg_ex_177.

* A local event handler class whose PUBLIC SECTION has a space before the
* period.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION .
    METHODS on_double_click FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column es_row_no.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_double_click.
    MESSAGE |Row { e_row-index } column { e_column-fieldname } { es_row_no-row_id }| TYPE 'S'.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  DATA(go_handler) = NEW lcl_handler( ).
  IF go_handler IS BOUND.
    WRITE / 'Handler created'.
  ENDIF.
