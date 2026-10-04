CLASS zcl_gg_rich_list_base DEFINITION PUBLIC ABSTRACT CREATE PUBLIC.

* Shared implementation for the list examples 92-95, which act on the
* standard list functions: page scrolling, find, print view and download.
* The numbered classes only select a feature mode and publish transaction
* metadata. All behavior still crosses the public report/list contracts.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_list_processing_v1.

    METHODS constructor
      IMPORTING
        iv_mode TYPE string.

  PRIVATE SECTION.
    DATA mv_mode TYPE string.
    DATA mv_page TYPE i.
    DATA mv_find TYPE i.

    METHODS set_status
      IMPORTING
        io_session TYPE REF TO zif_gg_session_v1.

    METHODS write_line
      IMPORTING
        io_writer TYPE REF TO zif_gg_list_writer_v1
        iv_text   TYPE string
        it_hide   TYPE zif_gg_list_processing_types_v1=>ty_hidden_fields OPTIONAL.

    METHODS write_page_rows
      IMPORTING
        io_writer TYPE REF TO zif_gg_list_writer_v1.
ENDCLASS.

CLASS zcl_gg_rich_list_base IMPLEMENTATION.

  METHOD constructor.
    mv_mode = iv_mode.
    IF mv_mode = '92'.
      mv_page = 1.
    ENDIF.
  ENDMETHOD.

  METHOD write_line.
    io_writer->write_field( VALUE #(
      text      = iv_text
      placement = VALUE #( new_line = abap_true )
      hide      = it_hide ) ).
  ENDMETHOD.

  METHOD set_status.
    CASE mv_mode.
      WHEN '92'.
        io_session->get_list( )->set_status( VALUE #(
          status       = |PAGE { mv_page }|
          active_ucomm = VALUE #( ( zif_gg_session_types_v1=>command_first_page )
                                  ( zif_gg_session_types_v1=>command_previous_page )
                                  ( zif_gg_session_types_v1=>command_next_page )
                                  ( zif_gg_session_types_v1=>command_last_page ) )
          icon_bar     = VALUE #(
            ( ucomm = zif_gg_session_types_v1=>command_first_page label = 'First' icon = 'first-page' )
            ( ucomm = zif_gg_session_types_v1=>command_previous_page label = 'Previous' icon = 'previous-page' )
            ( ucomm = zif_gg_session_types_v1=>command_next_page label = 'Next' icon = 'next-page' )
            ( ucomm = zif_gg_session_types_v1=>command_last_page label = 'Last' icon = 'last-page' ) ) ) ).
      WHEN '93'.
        io_session->get_list( )->set_status( VALUE #(
          status       = COND #( WHEN mv_find = 0 THEN 'SEARCH' ELSE |FOUND { mv_find }| )
          active_ucomm = VALUE #( ( zif_gg_session_types_v1=>command_find )
                                  ( zif_gg_session_types_v1=>command_find_next ) )
          icon_bar     = VALUE #(
            ( ucomm = zif_gg_session_types_v1=>command_find label = 'Find' icon = 'search' )
            ( ucomm = zif_gg_session_types_v1=>command_find_next label = 'Find next' icon = 'search-plus' ) ) ) ).
      WHEN '94'.
        io_session->get_list( )->set_status( VALUE #(
          status       = 'INTERACTIVE'
          active_ucomm = VALUE #( ( 'PRINT_VIEW' ) )
          icon_bar     = VALUE #( ( ucomm = 'PRINT_VIEW' label = 'Print view' icon = 'printer' ) ) ) ).
      WHEN '95'.
        io_session->get_list( )->set_status( VALUE #(
          status       = 'INTERACTIVE'
          active_ucomm = VALUE #( ( 'DOWNLOAD' ) )
          icon_bar     = VALUE #( ( ucomm = 'DOWNLOAD' label = 'Download' icon = 'download' ) ) ) ).
      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD write_page_rows.
    DATA lv_index TYPE i.
    DO 3 TIMES.
      lv_index = ( mv_page - 1 ) * 3 + sy-index.
      write_line( io_writer = io_writer
                  iv_text   = |Flight { lv_index }|
                  it_hide   = VALUE #( ( name = 'FLIGHT_ID' value = |{ lv_index }| ) ) ).
    ENDDO.
  ENDMETHOD.

  METHOD zif_gg_report_v1~build_screen.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~load_of_program.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_logical_database.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~get_list_processing.
    ro_list_processing = me.
  ENDMETHOD.

  METHOD zif_gg_report_v1~initialization.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_output.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_field.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_end_of.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_block.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_radio.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_value_req.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_help_req.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_selection_screen_on_exit.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_get.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~at_get_late.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~end_of_selection.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    DATA(lo_writer) = io_session->get_list( )->get_writer( ).
    io_session->get_list( )->set_title( |ZCL_GG_EX_{ mv_mode }| ).
    set_status( io_session ).
    CASE mv_mode.
      WHEN '92'.
        write_page_rows( lo_writer ).
      WHEN '93'.
        write_line( io_writer = lo_writer
                    iv_text   = 'AA flight' ).
        write_line( io_writer = lo_writer
                    iv_text   = 'LH flight' ).
        write_line( io_writer = lo_writer
                    iv_text   = 'UA flight' ).
      WHEN '94'.
        write_line( io_writer = lo_writer
                    iv_text   = 'interactive list' ).
      WHEN '95'.
        write_line( io_writer = lo_writer
                    iv_text   = 'id,name' ).
        write_line( io_writer = lo_writer
                    iv_text   = '1,"Alpha, Inc."' ).
        write_line( io_writer = lo_writer
                    iv_text   = '2,"Bravo"' ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~get_settings.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~top_of_page.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~end_of_page.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~top_of_page_during_line_sel.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_line_selection.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_user_command.
    DATA(lo_writer) = io_session->get_list( )->get_writer( ).
    CASE mv_mode.
      WHEN '92'.
        CASE iv_ucomm.
          WHEN zif_gg_session_types_v1=>command_first_page.
            mv_page = 1.
          WHEN zif_gg_session_types_v1=>command_previous_page.
            IF mv_page > 1.
              mv_page = mv_page - 1.
            ELSE.
              io_session->message( VALUE #( type = zif_gg_session_types_v1=>message_type_warning text = 'Already on first page' ) ).
            ENDIF.
          WHEN zif_gg_session_types_v1=>command_next_page.
            IF mv_page < 4.
              mv_page = mv_page + 1.
            ELSE.
              io_session->message( VALUE #( type = zif_gg_session_types_v1=>message_type_warning text = 'Already on last page' ) ).
            ENDIF.
          WHEN zif_gg_session_types_v1=>command_last_page.
            mv_page = 4.
        ENDCASE.
        set_status( io_session ).
        write_page_rows( lo_writer ).
      WHEN '93'.
        IF iv_ucomm = zif_gg_session_types_v1=>command_find
            OR iv_ucomm = zif_gg_session_types_v1=>command_find_next.
          mv_find = mv_find + 1.
          IF mv_find > 3.
            mv_find = 0.
            io_session->message( VALUE #( type = zif_gg_session_types_v1=>message_type_warning text = 'No matching flight found' ) ).
          ELSE.
            set_status( io_session ).
            write_line( io_writer = lo_writer
                        iv_text   = |Found LH at row { mv_find }| ).
          ENDIF.
        ENDIF.
      WHEN '94'.
        IF iv_ucomm = 'PRINT_VIEW'.
          write_line( io_writer = lo_writer
                      iv_text   = 'PRINT VIEW - static representation' ).
        ENDIF.
      WHEN '95'.
        IF iv_ucomm = 'DOWNLOAD'.
          write_line( io_writer = lo_writer
                      iv_text   = 'download prepared: flights.csv (text/csv)' ).
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_pf.
    RETURN.
  ENDMETHOD.

ENDCLASS.
