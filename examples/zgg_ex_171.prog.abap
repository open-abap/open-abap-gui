REPORT zgg_ex_171.

* A log display: the entries in an ALV list and their count as a status
* message, as an application log reports "n entries listed". The message can
* be displayed like another type, be made long, or be left out.

TYPES: BEGIN OF ty_entry,
         msgno TYPE n LENGTH 3,
         text  TYPE c LENGTH 40,
       END OF ty_entry.

PARAMETERS p_count TYPE i DEFAULT 3.
PARAMETERS p_like TYPE c LENGTH 1 DEFAULT 'S'.
PARAMETERS p_long AS CHECKBOX.
PARAMETERS p_quiet AS CHECKBOX.

DATA gt_log TYPE STANDARD TABLE OF ty_entry WITH DEFAULT KEY.
DATA gs_entry TYPE ty_entry.
DATA go_alv TYPE REF TO cl_salv_table.
DATA gx_msg TYPE REF TO cx_salv_msg.
DATA gv_text TYPE string.

START-OF-SELECTION.
  DO p_count TIMES.
    gs_entry-msgno = sy-index.
    gs_entry-text = |Log entry { sy-index }|.
    APPEND gs_entry TO gt_log.
  ENDDO.
  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = go_alv
        CHANGING
          t_table      = gt_log ).
    CATCH cx_salv_msg INTO gx_msg.
      MESSAGE gx_msg TYPE 'E'.
  ENDTRY.

  gv_text = |{ lines( gt_log ) } entries listed|.
  IF p_long = abap_true.
    gv_text = |{ gv_text }; the log holds every message the run wrote, from its start to its end, | &&
              |with the object, the subobject, the external number and the user who started it|.
  ENDIF.
  IF p_quiet = abap_false.
    CASE p_like.
      WHEN 'I'.
        MESSAGE gv_text TYPE 'S' DISPLAY LIKE 'I'.
      WHEN 'W'.
        MESSAGE gv_text TYPE 'S' DISPLAY LIKE 'W'.
      WHEN 'E'.
        MESSAGE gv_text TYPE 'S' DISPLAY LIKE 'E'.
      WHEN OTHERS.
        MESSAGE gv_text TYPE 'S'.
    ENDCASE.
  ENDIF.
  go_alv->display( ).
