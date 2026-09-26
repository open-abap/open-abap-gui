CLASS lcl_counter DEFINITION.
  PUBLIC SECTION.
    METHODS count.
ENDCLASS.

CLASS lcl_counter IMPLEMENTATION.
  METHOD count.
    gv_count = p_factor.
    LOOP AT s_date INTO DATA(ls_date).
      gv_count = gv_count + 1.
    ENDLOOP.
    IF s_date-low IS INITIAL.
      gv_count = gv_count * 2.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
