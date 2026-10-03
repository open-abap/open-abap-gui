REPORT zgg_ex_082.

TABLES sscrfields.

DATA gt_contents TYPE STANDARD TABLE OF rsparams WITH DEFAULT KEY.
DATA gt_text TYPE STANDARD TABLE OF varit WITH DEFAULT KEY.
DATA gs_variant TYPE varid.

PARAMETERS p_name TYPE c LENGTH 14 OBLIGATORY.
PARAMETERS p_value TYPE c LENGTH 30.
SELECTION-SCREEN PUSHBUTTON /1(12) TEXT-001 USER-COMMAND var_save.
SELECTION-SCREEN PUSHBUTTON 15(12) TEXT-002 USER-COMMAND var_load.
SELECTION-SCREEN PUSHBUTTON 29(12) TEXT-003 USER-COMMAND var_delete.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'VAR_SAVE'.
      CALL FUNCTION 'RS_REFRESH_FROM_SELECTOPTIONS'
        EXPORTING
          curr_report     = sy-repid
        TABLES
          selection_table = gt_contents
        EXCEPTIONS
          OTHERS          = 1.
      gs_variant-report = sy-repid.
      gs_variant-variant = p_name.
      CALL FUNCTION 'RS_CREATE_VARIANT'
        EXPORTING
          curr_report   = sy-repid
          curr_variant  = p_name
          vari_desc     = gs_variant
        TABLES
          vari_contents = gt_contents
          vari_text     = gt_text
        EXCEPTIONS
          OTHERS        = 1.
      IF sy-subrc <> 0.
        CALL FUNCTION 'RS_CHANGE_CREATED_VARIANT'
          EXPORTING
            curr_report   = sy-repid
            curr_variant  = p_name
            vari_desc     = gs_variant
          TABLES
            vari_contents = gt_contents
            vari_text     = gt_text
          EXCEPTIONS
            OTHERS        = 1.
      ENDIF.
      MESSAGE 'Variant saved' TYPE 'S'.
    WHEN 'VAR_LOAD'.
      CALL FUNCTION 'RS_VARIANT_CONTENTS'
        EXPORTING
          report  = sy-repid
          variant = p_name
        TABLES
          valutab = gt_contents
        EXCEPTIONS
          OTHERS  = 1.
      IF sy-subrc <> 0.
        MESSAGE 'Variant not found' TYPE 'W'.
      ELSE.
        LOOP AT gt_contents INTO DATA(ls_content) WHERE selname = 'P_VALUE'.
          p_value = ls_content-low.
        ENDLOOP.
        MESSAGE 'Variant loaded' TYPE 'S'.
      ENDIF.
    WHEN 'VAR_DELETE'.
      CALL FUNCTION 'RS_VARIANT_DELETE'
        EXPORTING
          report  = sy-repid
          variant = p_name
        EXCEPTIONS
          OTHERS  = 1.
      MESSAGE 'Variant deleted' TYPE 'S'.
  ENDCASE.

START-OF-SELECTION.
  WRITE |{ p_name }={ p_value }|.
