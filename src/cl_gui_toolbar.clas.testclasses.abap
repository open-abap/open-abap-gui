CLASS ltcl_gui_toolbar DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS updates_button_state FOR TESTING.
ENDCLASS.

CLASS ltcl_gui_toolbar IMPLEMENTATION.
  METHOD updates_button_state.
    cl_gui_control=>clear( ).
    DATA(lo_container) = NEW cl_gui_custom_container( container_name = 'TOOLBAR_TEST' ).
    DATA(lo_toolbar) = NEW cl_gui_toolbar( parent = lo_container ).
    lo_toolbar->add_button(
      fcode     = 'TEST'
      icon      = '@'
      butn_type = 0
      text      = 'Test'
      quickinfo = 'Test button' ).
    lo_toolbar->set_button_state(
      fcode   = 'TEST'
      enabled = ' '
      checked = 'X' ).
    lo_toolbar->set_button_info(
      fcode     = 'TEST'
      text      = 'Updated'
      quickinfo = 'Updated button' ).
    DATA(lt_snapshots) = cl_gui_control=>get_snapshots( ).
    READ TABLE lt_snapshots INTO DATA(ls_snapshot)
      WITH KEY control_id = lo_toolbar->control_id.

    cl_abap_unit_assert=>assert_equals(
      act = ls_snapshot-buttons[ 1 ]-text
      exp = 'Updated' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_snapshot-buttons[ 1 ]-disabled
      exp = 'X' ).
    cl_abap_unit_assert=>assert_equals(
      act = ls_snapshot-buttons[ 1 ]-checked
      exp = 'X' ).
    lo_toolbar->set_button_visible(
      fcode   = 'TEST'
      visible = ' ' ).
    lt_snapshots = cl_gui_control=>get_snapshots( ).
    READ TABLE lt_snapshots INTO ls_snapshot
      WITH KEY control_id = lo_toolbar->control_id.
    cl_abap_unit_assert=>assert_initial( act = ls_snapshot-buttons ).
    cl_gui_control=>clear( ).
  ENDMETHOD.
ENDCLASS.
