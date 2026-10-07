REPORT zgg_ex_130.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_clicked FOR EVENT clicked OF cl_dd_link_element
      IMPORTING sender.
ENDCLASS.

DATA go_document TYPE REF TO cl_dd_document.
DATA go_link TYPE REF TO cl_dd_link_element.
DATA gv_state TYPE c LENGTH 60.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_clicked.
    gv_state = |Link { sender->name } clicked|.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_document IS INITIAL.
    go_document = NEW #( ).
    go_document->add_text( text      = 'Document events'
                           sap_style = cl_dd_area=>heading ).
    go_document->new_line( ).
    go_document->add_link( EXPORTING url  = '/safe/document'
                                     text = 'Open document'
                                     name = 'OPEN_DOC'
                           IMPORTING link = go_link ).
    SET HANDLER lcl_handler=>on_clicked FOR go_link.
    go_document->merge_document( ).
    go_document->display_document( container = 'CC_MAIN' ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  cl_gui_cfw=>dispatch( ).
ENDMODULE.
