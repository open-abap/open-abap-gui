REPORT zexample_formparm.

DATA gt_log TYPE STANDARD TABLE OF string WITH EMPTY KEY.
DATA gv_line TYPE string.

CLASS lcl_receiver DEFINITION.
  PUBLIC SECTION.
    METHODS on_status_changed FOR EVENT status_changed OF zcl_example_document
      IMPORTING ev_status.
ENDCLASS.

CLASS lcl_receiver IMPLEMENTATION.
  METHOD on_status_changed.
    APPEND |Status changed to { ev_status }| TO gt_log.
  ENDMETHOD.
ENDCLASS.

DATA go_document TYPE REF TO zcl_example_document.
DATA go_receiver TYPE REF TO lcl_receiver.

START-OF-SELECTION.
  go_document = NEW #( ).
  PERFORM register_events USING go_receiver go_document.
  go_document->set_status( `RELEASED` ).
  LOOP AT gt_log INTO gv_line.
    WRITE: / gv_line.
  ENDLOOP.

* The FORM parameter is typed with the local class, which the converter
* hoists into a helper class, so the generated method parameter must be
* typed with the helper class too.
FORM register_events USING po_receiver TYPE REF TO lcl_receiver
                           po_document TYPE REF TO zcl_example_document.
  CREATE OBJECT po_receiver.
  SET HANDLER po_receiver->on_status_changed FOR po_document.
ENDFORM.
