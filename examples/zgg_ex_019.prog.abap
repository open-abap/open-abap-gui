REPORT zgg_ex_019.

* The listbox offers the fixed values of the domain ZGG_MODE, the domain of
* the parameter's data element, with their texts.

PARAMETERS p_mode TYPE zgg_mode AS LISTBOX VISIBLE LENGTH 10 DEFAULT 'A'.

START-OF-SELECTION.
  CASE p_mode.
    WHEN 'A'.
      WRITE / 'Mode A: the rows are added'.
    WHEN 'D'.
      WRITE / 'Mode D: the rows are deleted'.
  ENDCASE.
