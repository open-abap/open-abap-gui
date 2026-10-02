REPORT zgg_ex_167.

CONSTANTS: BEGIN OF gc_vrm_id,
             mode TYPE vrm_id VALUE 'P_MODE',
           END OF gc_vrm_id.

DATA gt_values TYPE vrm_values.

PARAMETERS p_mode TYPE c LENGTH 1 AS LISTBOX VISIBLE LENGTH 20 DEFAULT 'D'.

INITIALIZATION.
  gt_values = VALUE #( ( key = 'D' text = 'Display' )
                       ( key = 'C' text = 'Change' ) ).
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = gc_vrm_id-mode
      values = gt_values.

START-OF-SELECTION.
  WRITE: / 'Mode:', p_mode.
