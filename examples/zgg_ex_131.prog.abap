REPORT zgg_ex_131.

DATA go_container TYPE REF TO cl_gui_custom_container.
DATA go_splitter TYPE REF TO cl_gui_splitter_container.
DATA go_editor TYPE REF TO cl_gui_textedit.
DATA go_picture TYPE REF TO cl_gui_picture.
DATA go_toolbar TYPE REF TO cl_gui_toolbar.
DATA gv_url TYPE c LENGTH 255 VALUE '/assets/icons/refresh.svg'.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_container IS INITIAL.
    go_container = NEW #( container_name = 'CC_MAIN' ).
    go_splitter = NEW #( parent  = go_container
                         rows    = 1
                         columns = 3 ).
    DATA(lo_first) = go_splitter->get_container( row    = 1
                                                 column = 1 ).
    go_editor = NEW #( parent = lo_first ).
    go_editor->set_textstream( 'Editor in cell 1' ).
    DATA(lo_second) = go_splitter->get_container( row    = 1
                                                  column = 2 ).
    go_picture = NEW #( parent = lo_second ).
    go_picture->load_picture_from_url_async( gv_url ).
    DATA(lo_third) = go_splitter->get_container( row    = 1
                                                 column = 3 ).
    go_toolbar = NEW #( parent = lo_third ).
    go_toolbar->add_button( fcode     = 'APPLY'
                            icon      = icon_okay
                            butn_type = cntb_btype_button
                            text      = 'Apply'
                            quickinfo = 'Apply nested control' ).
  ENDIF.
ENDMODULE.
