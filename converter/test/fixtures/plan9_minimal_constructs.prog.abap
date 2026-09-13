REPORT zplan9_minimal_constructs.

TYPES: BEGIN OF ty_row,
         id TYPE i,
       END OF ty_row.
DATA gv_value TYPE i.
DATA gs_row TYPE ty_row.
DATA gt_rows TYPE STANDARD TABLE OF ty_row WITH DEFAULT KEY.
DATA gt_any TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA gv_any TYPE string.
DATA gv_int TYPE i.
DATA gv_xstr TYPE xstring.
CONSTANTS gc_value TYPE i VALUE 1.
STATICS gv_static TYPE i.
RANGES r_value FOR gv_value.
FIELD-SYMBOLS <lv_value> TYPE i.

SELECTION-SCREEN COMMENT /1(20) TEXT-001.
PARAMETERS p_value TYPE i.

FORM prepare.
  ASSIGN gv_value TO <lv_value>.
  <lv_value> = gc_value.
ENDFORM.

START-OF-SELECTION.
  PERFORM prepare.
  CALL FUNCTION 'POPUP_TO_CONFIRM' IMPORTING answer = gv_any.
  CALL FUNCTION 'POPUP_TO_INFORM'.
  CALL FUNCTION 'POPUP_GET_VALUES' EXPORTING fields = gt_any returncode = gv_any.
  CALL FUNCTION 'POPUP_WITH_TABLE_DISPLAY' EXPORTING valuetab = gt_any choise = gv_int.
  CALL FUNCTION 'POPUP_TO_SELECT_MONTH' EXPORTING return_code = gv_any selected_month = gv_any.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST' EXPORTING value_tab = gt_any return_tab = gt_any.
  CALL FUNCTION 'VRM_SET_VALUES'.
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT' EXPORTING input = gv_any IMPORTING output = gv_any.
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT' EXPORTING input = gv_any IMPORTING output = gv_any.
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE' TABLES ct_fieldcat = gt_any.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE' TABLES ct_fieldcat = gt_any.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY' TABLES t_outtab = gt_any.
  CALL FUNCTION 'REUSE_ALV_LIST_DISPLAY' TABLES t_outtab = gt_any.
  CALL FUNCTION 'REUSE_ALV_HIERSEQ_LIST_DISPLAY' TABLES t_outtab_header = gt_any t_outtab_item = gt_any.
  CALL FUNCTION 'REUSE_ALV_BLOCK_LIST_INIT'.
  CALL FUNCTION 'REUSE_ALV_BLOCK_LIST_APPEND' TABLES t_outtab = gt_any.
  CALL FUNCTION 'REUSE_ALV_BLOCK_LIST_DISPLAY'.
  CALL FUNCTION 'REUSE_ALV_POPUP_TO_SELECT' TABLES t_outtab = gt_any.
  CALL FUNCTION 'REUSE_ALV_EVENTS_GET' TABLES et_events = gt_any.
  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'.
  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE' TABLES it_list_commentary = gt_any.
  CALL FUNCTION 'SELECT_OPTIONS_RESTRICT'.
  CALL FUNCTION 'FREE_SELECTIONS_INIT' EXPORTING selection_id = gv_any TABLES field_ranges_int = gt_any tables_tab = gt_any fields_tab = gt_any.
  CALL FUNCTION 'FREE_SELECTIONS_DIALOG' EXPORTING number_of_active_fields = gv_int TABLES where_clauses = gt_any expressions = gt_any field_ranges = gt_any fields_tab = gt_any.
  CALL FUNCTION 'FREE_SELECTIONS_RANGE_2_WHERE' TABLES field_ranges = gt_any where_clauses = gt_any.
  CALL FUNCTION 'RS_REFRESH_FROM_SELECTOPTIONS' TABLES selection_table = gt_any.
  CALL FUNCTION 'RS_VARIANT_CATALOG' IMPORTING sel_variant = gv_any.
  CALL FUNCTION 'RS_VARIANT_CONTENTS' TABLES valutab = gt_any.
  CALL FUNCTION 'RS_CREATE_VARIANT' TABLES vari_contents = gt_any vari_text = gt_any.
  CALL FUNCTION 'RS_CHANGE_CREATED_VARIANT' TABLES vari_contents = gt_any vari_text = gt_any.
  CALL FUNCTION 'RS_VARIANT_DELETE'.
  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY' EXPORTING buffer = gv_xstr IMPORTING output_length = gv_int TABLES binary_tab = gt_any.
  CALL FUNCTION 'DP_CREATE_URL' IMPORTING url = gv_any TABLES data = gt_any.
  CALL FUNCTION 'DP_PUBLISH_WWW_URL' IMPORTING url = gv_any.
  WRITE gv_value.
