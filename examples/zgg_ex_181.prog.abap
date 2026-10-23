REPORT zgg_ex_181.

* Declarations typed LIKE a parameter, which becomes a class attribute of
* another name.

PARAMETERS p_dir(132) LOWER CASE DEFAULT '/tmp'.

DATA: BEGIN OF gt_hist OCCURS 0,
        p_dir LIKE p_dir,
      END OF gt_hist.
DATA gv_dir LIKE p_dir.

START-OF-SELECTION.
  gv_dir = p_dir.
  gt_hist-p_dir = gv_dir.
  APPEND gt_hist.
  WRITE: / gv_dir, lines( gt_hist ).
