REPORT zgg_ex_214.

* A macro-heavy report: the macros of the main program declare data, bind
* field symbols, call FORMs and change SCREEN, and its includes call them.

INCLUDE zgg_ex_214_top.

DEFINE declare_counter.
  DATA &1 TYPE i.
END-OF-DEFINITION.

DEFINE add_item.
  APPEND VALUE #( name = &1 qty = &2 ) TO gt_items.
END-OF-DEFINITION.

DEFINE point_at.
  READ TABLE gt_items ASSIGNING <gs_item> WITH KEY name = &1.
END-OF-DEFINITION.

DEFINE log.
  PERFORM add_log USING &1.
END-OF-DEFINITION.

DEFINE lock_group.
  IF screen-group1 = &1.
    screen-input = 0.
  ENDIF.
END-OF-DEFINITION.

declare_counter gv_changes.

INCLUDE zgg_ex_214_f01.

PARAMETERS p_name TYPE c LENGTH 10 DEFAULT 'Apple' MODIF ID nam.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    PERFORM protect.
    MODIFY SCREEN.
  ENDLOOP.

START-OF-SELECTION.
  PERFORM fill.
  PERFORM bump USING p_name.
  PERFORM show.
