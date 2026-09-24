REPORT zexample_counter.

DATA go_counter TYPE REF TO zcl_example_counter.
DATA gv_value TYPE i.

START-OF-SELECTION.
  go_counter = NEW #( ).
  go_counter->increment( ).
  go_counter->increment( )->increment( ).
  CALL METHOD go_counter->add EXPORTING iv_amount = 10.
  DATA(lo_second) = NEW zcl_example_counter( ).
  lo_second->add( iv_amount = 5 ).
  gv_value = go_counter->get_value( ) + lo_second->get_value( ).
  WRITE: / 'Total:', gv_value.
