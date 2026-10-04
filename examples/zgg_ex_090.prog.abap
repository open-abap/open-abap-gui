REPORT zgg_ex_090.

* The source stays 7-bit ASCII; the wide text arrives as UTF-8 bytes.
CONSTANTS gc_wide_utf8 TYPE xstring VALUE 'E888AAE7A9BA20E29C88EFB88F2065CC8120E2809420D985D8B1D8ADD8A8D8A7203C776964653E'.

START-OF-SELECTION.
  WRITE / cl_abap_codepage=>convert_from( gc_wide_utf8 ).
  WRITE AT 28 'logical column'.
