REPORT zgg_ex_154.

TYPES: BEGIN OF ty_flight,
         carrid   TYPE c LENGTH 3,
         connid   TYPE n LENGTH 4,
         cityfrom TYPE c LENGTH 20,
         cityto   TYPE c LENGTH 20,
       END OF ty_flight.

DATA gt_flights TYPE STANDARD TABLE OF ty_flight WITH DEFAULT KEY.
DATA gt_lines TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA gt_files TYPE filetable.
DATA gs_file TYPE file_table.
DATA gv_rc TYPE i.
DATA gv_action TYPE i.
DATA gv_filename TYPE string.
DATA gv_path TYPE string.
DATA gv_fullpath TYPE string.
DATA gv_length TYPE i.
DATA gv_ok_code TYPE sy-ucomm.
DATA gv_state TYPE c LENGTH 60.
DATA gv_first_line TYPE c LENGTH 60.

START-OF-SELECTION.
  gt_flights = VALUE #(
    ( carrid = 'LH' connid = '0400' cityfrom = 'Frankfurt' cityto = 'New York' )
    ( carrid = 'UA' connid = '0941' cityfrom = 'Frankfurt' cityto = 'San Francisco' )
    ( carrid = 'AF' connid = '0010' cityfrom = 'Paris' cityto = 'New York' ) ).
  CALL SCREEN 100.

MODULE user_command_0100 INPUT.
  CASE gv_ok_code.
    WHEN 'DOWNLOAD'.
      cl_gui_frontend_services=>file_save_dialog(
        EXPORTING
          window_title      = 'Download flights'
          default_extension = 'txt'
          default_file_name = 'flights.txt'
        CHANGING
          filename          = gv_filename
          path              = gv_path
          fullpath          = gv_fullpath
          user_action       = gv_action
        EXCEPTIONS
          OTHERS            = 1 ).
      IF sy-subrc <> 0 OR gv_action <> cl_gui_frontend_services=>action_ok.
        gv_state = 'Download cancelled'.
      ELSE.
        cl_gui_frontend_services=>gui_download(
          EXPORTING
            filename              = gv_fullpath
            write_field_separator = abap_true
          IMPORTING
            filelength            = gv_length
          CHANGING
            data_tab              = gt_flights
          EXCEPTIONS
            OTHERS                = 1 ).
        IF sy-subrc = 0.
          gv_state = |{ gv_filename }: { gv_length } bytes downloaded|.
        ELSE.
          gv_state = 'Download failed'.
        ENDIF.
      ENDIF.
    WHEN 'UPLOAD'.
      cl_gui_frontend_services=>file_open_dialog(
        EXPORTING
          window_title      = 'Upload text file'
          default_extension = 'txt'
        CHANGING
          file_table        = gt_files
          rc                = gv_rc
          user_action       = gv_action
        EXCEPTIONS
          OTHERS            = 1 ).
      IF sy-subrc <> 0 OR gv_action <> cl_gui_frontend_services=>action_ok OR gv_rc <> 1.
        gv_state = 'Upload cancelled'.
      ELSE.
        READ TABLE gt_files INTO gs_file INDEX 1.
        gv_filename = gs_file-filename.
        CLEAR gt_lines.
        cl_gui_frontend_services=>gui_upload(
          EXPORTING
            filename   = gv_filename
          IMPORTING
            filelength = gv_length
          CHANGING
            data_tab   = gt_lines
          EXCEPTIONS
            OTHERS     = 1 ).
        IF sy-subrc = 0.
          gv_state = |{ gv_filename }: { lines( gt_lines ) } lines, { gv_length } bytes|.
          READ TABLE gt_lines INTO DATA(gv_line) INDEX 1.
          gv_first_line = gv_line.
        ELSE.
          gv_state = 'Upload failed'.
        ENDIF.
      ENDIF.
  ENDCASE.
  CLEAR gv_ok_code.
ENDMODULE.
