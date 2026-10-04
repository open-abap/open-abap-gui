REPORT zgg_ex_134.

TYPES ty_html_line TYPE c LENGTH 255.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_splitter TYPE REF TO cl_gui_splitter_container.
DATA go_editor TYPE REF TO cl_gui_textedit.
DATA go_viewer TYPE REF TO cl_gui_html_viewer.
DATA gt_html TYPE STANDARD TABLE OF ty_html_line WITH DEFAULT KEY.
DATA gv_url TYPE c LENGTH 255.
DATA gv_text TYPE string VALUE 'Document text'.
DATA gv_ok_code TYPE sy-ucomm.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    CREATE OBJECT go_container
      EXPORTING
        container_name = 'CC_MAIN'.
    CREATE OBJECT go_splitter
      EXPORTING
        parent  = go_container
        rows    = 1
        columns = 2.
    DATA(lo_left) = go_splitter->get_container( row    = 1
                                                column = 1 ).
    CREATE OBJECT go_editor
      EXPORTING
        parent = lo_left.
    go_editor->set_textstream( gv_text ).
    DATA(lo_right) = go_splitter->get_container( row    = 1
                                                 column = 2 ).
    CREATE OBJECT go_viewer
      EXPORTING
        parent = lo_right.
    PERFORM show_document.
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  IF gv_ok_code = 'SHOW'.
    go_editor->get_textstream( IMPORTING text = gv_text ).
    cl_gui_cfw=>flush( ).
    PERFORM show_document.
  ENDIF.
  CLEAR gv_ok_code.
ENDMODULE.

FORM show_document.
  DATA(lv_escaped) = escape( val    = gv_text
                             format = cl_abap_format=>e_html_text ).
  gt_html = VALUE #( ( '<h2>Document viewer</h2>' )
                     ( CONV ty_html_line( |<p>{ lv_escaped }</p>| ) ) ).
  go_viewer->load_data( IMPORTING assigned_url = gv_url
                        CHANGING  data_table   = gt_html ).
  go_viewer->show_url( url = gv_url ).
ENDFORM.
