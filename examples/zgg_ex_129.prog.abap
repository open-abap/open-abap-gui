REPORT zgg_ex_129.

DATA go_document TYPE REF TO cl_dd_document.
DATA go_table TYPE REF TO cl_dd_table_element.
DATA go_column_field TYPE REF TO cl_dd_area.
DATA go_column_value TYPE REF TO cl_dd_area.

START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  IF go_document IS INITIAL.
    go_document = NEW #( ).
    go_document->add_text( text      = 'Dynamic & safe document'
                           sap_style = cl_dd_area=>heading ).
    go_document->new_line( ).
    go_document->add_text( text = 'Text with <markup> & attributes stays text.' ).
    go_document->new_line( ).
    go_document->add_link( url  = '/safe/document'
                           text = 'Open document'
                           name = 'SAFE_DOCUMENT' ).
    go_document->new_line( ).
    go_document->add_table( EXPORTING no_of_columns = 2
                                      with_heading  = abap_true
                                      border        = '1'
                            IMPORTING table         = go_table ).
    go_table->add_column( EXPORTING heading = 'Field'
                          IMPORTING column  = go_column_field ).
    go_table->add_column( EXPORTING heading = 'Value'
                          IMPORTING column  = go_column_value ).
    go_column_field->add_text( text = 'Status' ).
    go_column_value->add_text( text = 'Draft' ).
    go_document->merge_document( ).
    go_document->display_document( container = 'CC_MAIN' ).
  ENDIF.
ENDMODULE.
