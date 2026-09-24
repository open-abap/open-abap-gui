REPORT zexample_events.

DATA gt_log TYPE STANDARD TABLE OF string WITH EMPTY KEY.
DATA gv_line TYPE string.

CLASS lcl_listener DEFINITION.
  PUBLIC SECTION.
    METHODS on_status_changed FOR EVENT status_changed OF zcl_example_order
      IMPORTING ev_status.
    CLASS-METHODS on_order_created FOR EVENT order_created OF zcl_example_order.
ENDCLASS.

CLASS lcl_listener IMPLEMENTATION.
  METHOD on_status_changed.
    APPEND |Status changed to { ev_status }| TO gt_log.
  ENDMETHOD.

  METHOD on_order_created.
    APPEND `Order created` TO gt_log.
  ENDMETHOD.
ENDCLASS.

DATA go_order TYPE REF TO zcl_example_order.
DATA go_listener TYPE REF TO lcl_listener.

START-OF-SELECTION.
  SET HANDLER lcl_listener=>on_order_created.
  go_order = zcl_example_order=>create( ).
  go_listener = NEW #( ).
  SET HANDLER go_listener->on_status_changed FOR go_order.
  go_order->set_status( `RELEASED` ).
  SET HANDLER go_listener->on_status_changed FOR ALL INSTANCES ACTIVATION abap_false.
  LOOP AT gt_log INTO gv_line.
    WRITE: / gv_line.
  ENDLOOP.
