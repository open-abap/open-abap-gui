CLASS ltcl_dragdrop DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS stores_flavors_and_handle FOR TESTING.
    METHODS aborts_drag_drop_object FOR TESTING.
ENDCLASS.

CLASS ltcl_dragdrop IMPLEMENTATION.
  METHOD stores_flavors_and_handle.
    DATA lv_source TYPE abap_bool.
    DATA lv_target TYPE abap_bool.
    DATA lv_effect TYPE i.
    DATA lv_effect_in_ctrl TYPE i.
    DATA lv_handle TYPE i.

    DATA(lo_dragdrop) = NEW cl_dragdrop( ).
    lo_dragdrop->add(
      flavor         = 'TEXT'
      dragsrc        = abap_true
      droptarget     = abap_true
      effect         = cl_dragdrop=>move
      effect_in_ctrl = cl_dragdrop=>copy ).
    lo_dragdrop->get(
      EXPORTING
        flavor         = 'TEXT'
      IMPORTING
        isdragsrc      = lv_source
        isdroptarget   = lv_target
        effect         = lv_effect
        effect_in_ctrl = lv_effect_in_ctrl ).
    lo_dragdrop->get_handle( IMPORTING handle = lv_handle ).

    cl_abap_unit_assert=>assert_true( act = lv_source ).
    cl_abap_unit_assert=>assert_true( act = lv_target ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_effect
      exp = cl_dragdrop=>move ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_effect_in_ctrl
      exp = cl_dragdrop=>copy ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_handle > 0 ) ).
  ENDMETHOD.

  METHOD aborts_drag_drop_object.
    DATA(lo_object) = NEW cl_dragdropobject( ).
    lo_object->effect = cl_dragdrop=>move.
    lo_object->abort( ).

    cl_abap_unit_assert=>assert_equals(
      act = lo_object->state
      exp = -1 ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_object->effect
      exp = 0 ).
  ENDMETHOD.
ENDCLASS.
