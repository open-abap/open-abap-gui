CLASS zcl_gg_list_memory DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
* ABAPLIST is opaque. This host uses length-prefixed UTF-8 JSON.
    CLASS-METHODS from_lines
      IMPORTING it_lines TYPE string_table
      CHANGING ct_list   TYPE STANDARD TABLE.
    CLASS-METHODS to_ascii
      IMPORTING it_list TYPE STANDARD TABLE
      CHANGING ct_ascii TYPE STANDARD TABLE.
ENDCLASS.

CLASS zcl_gg_list_memory IMPLEMENTATION.
  METHOD from_lines.
    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <raw> TYPE any.
    DATA lv_offset TYPE i.
    DATA lv_size TYPE i.
    CLEAR ct_list.
    APPEND INITIAL LINE TO ct_list ASSIGNING <row>.
    ASSIGN COMPONENT 'LINE' OF STRUCTURE <row> TO <raw>.
    IF sy-subrc <> 0.
      CLEAR ct_list.
      LOOP AT it_lines INTO DATA(lv_line).
        APPEND lv_line TO ct_list.
      ENDLOOP.
      RETURN.
    ENDIF.
    DATA(lv_json) = /ui2/cl_json=>serialize( it_lines ).
    DATA(lv_length) = xstrlen( cl_abap_codepage=>convert_to( lv_json ) ).
    DATA(lv_data) = cl_abap_codepage=>convert_to( |{ lv_length WIDTH = 10 ALIGN = RIGHT PAD = '0' }{ lv_json }| ).
    CLEAR ct_list.
    WHILE lv_offset < xstrlen( lv_data ).
      APPEND INITIAL LINE TO ct_list ASSIGNING <row>.
      ASSIGN COMPONENT 'LINE' OF STRUCTURE <row> TO <raw>.
      lv_size = nmin( val1 = 1000
                      val2 = xstrlen( lv_data ) - lv_offset ).
      <raw> = lv_data+lv_offset(lv_size).
      lv_offset = lv_offset + lv_size.
    ENDWHILE.
  ENDMETHOD.

  METHOD to_ascii.
    FIELD-SYMBOLS <row> TYPE any.
    FIELD-SYMBOLS <raw> TYPE any.
    DATA lv_data TYPE xstring.
    DATA lt_lines TYPE string_table.
    CLEAR ct_ascii.
    LOOP AT it_list ASSIGNING <row>.
      ASSIGN COMPONENT 'LINE' OF STRUCTURE <row> TO <raw>.
      IF sy-subrc <> 0.
        APPEND <row> TO ct_ascii.
        CONTINUE.
      ENDIF.
      CONCATENATE lv_data <raw> INTO lv_data IN BYTE MODE.
    ENDLOOP.
    IF xstrlen( lv_data ) < 10.
      RETURN.
    ENDIF.
    DATA(lv_header) = lv_data(10).
    DATA(lv_length) = CONV i( cl_abap_codepage=>convert_from( lv_header ) ).
    IF lv_length < 0 OR lv_length > xstrlen( lv_data ) - 10.
      RETURN.
    ENDIF.
    DATA(lv_payload) = lv_data+10(lv_length).
    DATA(lv_json) = cl_abap_codepage=>convert_from( lv_payload ).
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = lt_lines ).
    LOOP AT lt_lines INTO DATA(lv_line).
      APPEND lv_line TO ct_ascii.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
