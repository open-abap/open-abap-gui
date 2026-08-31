CLASS zcl_gg_rich_list_base DEFINITION PUBLIC ABSTRACT CREATE PUBLIC.

* Shared implementation for the advanced classic-list examples 83-98.
* The numbered classes only select a feature mode and publish transaction
* metadata. All behavior still crosses the public report/list contracts.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.
    INTERFACES zif_gg_list_processing_v1.
    INTERFACES zif_gg_resumable_v1.

    METHODS constructor
      IMPORTING
        iv_mode TYPE string.

  PRIVATE SECTION.
    DATA mv_mode TYPE string.
    DATA mv_refresh TYPE i.
    DATA mv_page TYPE i.
    DATA mv_find TYPE i.
    DATA mv_sorted TYPE abap_bool.
    DATA mv_filtered TYPE abap_bool.

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

    CLASS-METHODS unicode_text
      IMPORTING
        iv_hex         TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.
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

  METHOD unicode_text.
    DATA(lv_utf8) = CONV xstring( iv_hex ).
    DATA(lo_converter) = cl_abap_conv_in_ce=>create( input = lv_utf8 encoding = 'UTF-8' ).
    lo_converter->read( IMPORTING data = rv_text ).
  ENDMETHOD.

  METHOD set_status.
    CASE mv_mode.
      WHEN '85'.
        io_session->get_list( )->set_status( VALUE #(
          status = COND #( WHEN mv_refresh = 0 THEN 'READY' ELSE 'REFRESHED' )
          active_ucomm = VALUE #( ( 'REFRESH' ) )
          icon_bar = VALUE #( ( ucomm = 'REFRESH' label = 'Refresh' icon = 'refresh' ) ) ) ).
      WHEN '86'.
        io_session->get_list( )->set_status( VALUE #(
          status = 'EDITABLE'
          active_ucomm = VALUE #( ( 'MODIFY' ) )
          icon_bar = VALUE #( ( ucomm = 'MODIFY' label = 'Modify lines' icon = 'edit' ) ) ) ).
      WHEN '92'.
        io_session->get_list( )->set_status( VALUE #(
          status = |PAGE { mv_page }|
          active_ucomm = VALUE #( ( zif_gg_session_types_v1=>command_first_page )
                                  ( zif_gg_session_types_v1=>command_previous_page )
                                  ( zif_gg_session_types_v1=>command_next_page )
                                  ( zif_gg_session_types_v1=>command_last_page ) )
          icon_bar = VALUE #(
            ( ucomm = zif_gg_session_types_v1=>command_first_page label = 'First' icon = 'first-page' )
            ( ucomm = zif_gg_session_types_v1=>command_previous_page label = 'Previous' icon = 'previous-page' )
            ( ucomm = zif_gg_session_types_v1=>command_next_page label = 'Next' icon = 'next-page' )
            ( ucomm = zif_gg_session_types_v1=>command_last_page label = 'Last' icon = 'last-page' ) ) ) ).
      WHEN '93'.
        io_session->get_list( )->set_status( VALUE #(
          status = COND #( WHEN mv_find = 0 THEN 'SEARCH' ELSE |FOUND { mv_find }| )
          active_ucomm = VALUE #( ( zif_gg_session_types_v1=>command_find )
                                  ( zif_gg_session_types_v1=>command_find_next ) )
          icon_bar = VALUE #(
            ( ucomm = zif_gg_session_types_v1=>command_find label = 'Find' icon = 'search' )
            ( ucomm = zif_gg_session_types_v1=>command_find_next label = 'Find next' icon = 'search-plus' ) ) ) ).
      WHEN '94'.
        io_session->get_list( )->set_status( VALUE #(
          status = 'INTERACTIVE'
          active_ucomm = VALUE #( ( 'PRINT_VIEW' ) )
          icon_bar = VALUE #( ( ucomm = 'PRINT_VIEW' label = 'Print view' icon = 'printer' ) ) ) ).
      WHEN '95'.
        io_session->get_list( )->set_status( VALUE #(
          status = 'INTERACTIVE'
          active_ucomm = VALUE #( ( 'DOWNLOAD' ) )
          icon_bar = VALUE #( ( ucomm = 'DOWNLOAD' label = 'Download' icon = 'download' ) ) ) ).
      WHEN '96'.
        io_session->get_list( )->set_status( VALUE #(
          status = 'MESSAGES'
          active_ucomm = VALUE #( ( 'MESSAGES' ) )
          icon_bar = VALUE #( ( ucomm = 'MESSAGES' label = 'Messages' icon = 'message' ) ) ) ).
      WHEN '98'.
        io_session->get_list( )->set_status( VALUE #(
          status = COND #( WHEN mv_filtered = abap_true THEN 'FILTERED'
                           WHEN mv_sorted = abap_true THEN 'SORTED'
                           ELSE 'FLIGHTS' )
          active_ucomm = VALUE #( ( 'FILTER' ) ( 'SORT' ) ( 'REFRESH' ) )
          icon_bar = VALUE #(
            ( ucomm = 'FILTER' label = 'Filter' icon = 'filter' )
            ( ucomm = 'SORT' label = 'Sort' icon = 'sort' separator = abap_true )
            ( ucomm = 'REFRESH' label = 'Refresh' icon = 'refresh' ) ) ) ).
      WHEN OTHERS.
        RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD write_page_rows.
    DATA lv_first TYPE i.
    DATA lv_last TYPE i.
    DATA lv_index TYPE i.
    DATA lv_text TYPE string.

    lv_first = ( mv_page - 1 ) * 3 + 1.
    lv_last = lv_first + 2.
    DO 3 TIMES.
      lv_index = lv_first + sy-index - 1.
      lv_text = |Flight { lv_index }|
        && COND string( WHEN mv_sorted = abap_true THEN ' sorted' ELSE `` )
        && COND string( WHEN mv_filtered = abap_true THEN ' filtered' ELSE `` ).
      write_line( io_writer = io_writer
                  iv_text   = lv_text
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

  METHOD zif_gg_resumable_v1~resume.
    IF mv_mode = '97' AND is_resume-continuation-id = 'AFTER_LIST_MEMORY'.
      write_line( io_writer = io_session->get_list( )->get_writer( )
                  iv_text   = 'nested submit memory: hello world' ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_report_v1~start_of_selection.
    DATA(lo_writer) = io_session->get_list( )->get_writer( ).

    io_session->get_list( )->set_title( |ZCL_GG_EX_{ mv_mode }| ).
    set_status( io_session ).

    CASE mv_mode.
      WHEN '83'.
        write_line( io_writer = lo_writer iv_text = 'Basic list'
                    it_hide = VALUE #( ( name = 'LEVEL' value = '1' )
                                       ( name = 'NODE' value = 'DETAIL' ) ) ).
      WHEN '84'.
        write_line( io_writer = lo_writer iv_text = 'Repeated row'
                    it_hide = VALUE #( ( name = 'ROW_ID' value = 'A' )
                                       ( name = 'SECRET' value = 'alpha' ) ) ).
        write_line( io_writer = lo_writer iv_text = 'Repeated row'
                    it_hide = VALUE #( ( name = 'ROW_ID' value = 'B' )
                                       ( name = 'SECRET' value = 'bravo' ) ) ).
      WHEN '85'.
        write_line( io_writer = lo_writer
                    iv_text = COND #( WHEN mv_refresh = 0 THEN 'before refresh' ELSE 'after refresh' ) ).
      WHEN '86'.
        lo_writer->set_format( VALUE #( color = zif_gg_list_processing_types_v1=>color_heading intensified = abap_true ) ).
        lo_writer->write_field( VALUE #( text = 'Row one'
          placement = VALUE #( new_line = abap_true )
          hide = VALUE #( ( name = 'ROW' value = '1' ) ) ) ).
        lo_writer->set_position( 16 ).
        lo_writer->set_format( VALUE #( color = zif_gg_list_processing_types_v1=>color_key ) ).
        lo_writer->write_field( VALUE #( text = 'fragment A' ) ).
        lo_writer->reset_format( ).
        lo_writer->write_field( VALUE #( text = 'Row two'
          placement = VALUE #( new_line = abap_true )
          hide = VALUE #( ( name = 'ROW' value = '2' ) ) ) ).
        lo_writer->set_position( 16 ).
        lo_writer->set_format( VALUE #( color = zif_gg_list_processing_types_v1=>color_positive ) ).
        lo_writer->write_field( VALUE #( text = 'fragment B' ) ).
        lo_writer->reset_format( ).
      WHEN '87'.
        lo_writer->set_format( VALUE #( color = zif_gg_list_processing_types_v1=>color_heading intensified = abap_true quickinfo = 'Heading & <safe>' ) ).
        lo_writer->write_field( VALUE #( text = 'heading' placement = VALUE #( new_line = abap_true ) ) ).
        lo_writer->set_format( VALUE #( color = zif_gg_list_processing_types_v1=>color_positive hotspot = abap_true quickinfo = 'Positive' ) ).
        lo_writer->write_field( VALUE #( text = ' positive' ) ).
        lo_writer->set_format( VALUE #( color = zif_gg_list_processing_types_v1=>color_negative inverse = abap_true quickinfo = 'Negative' ) ).
        lo_writer->write_field( VALUE #( text = ' negative' ) ).
        lo_writer->reset_format( ).
      WHEN '88'.
        lo_writer->set_format( VALUE #( quickinfo = 'Icon & <safe>' ) ).
        lo_writer->write_icon( VALUE #( name = 'circle-check' placement = VALUE #( new_line = abap_true ) ) ).
        lo_writer->write_symbol( VALUE #( name = 'search' ) ).
        lo_writer->write_checkbox( VALUE #( name = 'ACTIVE' value = abap_true ) ).
        lo_writer->reset_format( ).
      WHEN '89'.
        lo_writer->write_field( VALUE #( text = '42.50'
          placement = VALUE #( new_line = abap_true length = 10 )
          write_format = VALUE #( justification = zif_gg_list_processing_types_v1=>justify_right decimals = 2 ) ) ).
        lo_writer->write_field( VALUE #( text = '2026-08-30'
          placement = VALUE #( position = 14 length = 12 )
          write_format = VALUE #( justification = zif_gg_list_processing_types_v1=>justify_center ) ) ).
        lo_writer->write_field( VALUE #( text = '0'
          placement = VALUE #( position = 28 length = 8 )
          write_format = VALUE #( justification = zif_gg_list_processing_types_v1=>justify_right no_zero = abap_true ) ) ).
        lo_writer->write_field( VALUE #( text = '123456789'
          placement = VALUE #( position = 38 length = 5 )
          write_format = VALUE #( justification = zif_gg_list_processing_types_v1=>justify_right ) ) ).
      WHEN '90'.
        write_line( io_writer = lo_writer iv_text = |{ unicode_text( `E888AAE7A9BA20E29C88EFB88F2065CC8120E2809420D985D8B1D8ADD8A8D8A7203C776964653E` ) }| ).
        lo_writer->set_position( 28 ).
        lo_writer->write_field( VALUE #( text = 'logical column' ) ).
      WHEN '91'.
        lo_writer->set_blank_lines( abap_true ).
        DO 8 TIMES.
          write_line( io_writer = lo_writer iv_text = |body { sy-index }| ).
        ENDDO.
      WHEN '92'.
        write_page_rows( lo_writer ).
      WHEN '93'.
        write_line( io_writer = lo_writer iv_text = 'AA flight' ).
        write_line( io_writer = lo_writer iv_text = 'LH flight' ).
        write_line( io_writer = lo_writer iv_text = 'UA flight' ).
      WHEN '94'.
        write_line( io_writer = lo_writer iv_text = 'interactive list' ).
      WHEN '95'.
        write_line( io_writer = lo_writer iv_text = 'id,name' ).
        write_line( io_writer = lo_writer iv_text = '1,"Alpha, Inc."' ).
        write_line( io_writer = lo_writer iv_text = '2,"Bravo"' ).
      WHEN '96'.
        write_line( io_writer = lo_writer iv_text = 'message list' ).
        io_session->message( VALUE #( type = zif_gg_session_types_v1=>message_type_success text = 'Saved successfully' ) ).
        io_session->message( VALUE #( type = zif_gg_session_types_v1=>message_type_warning text = 'Review the selection' ) ).
      WHEN '97'.
        io_session->get_navigation( )->submit_and_return(
          is_submit = VALUE #( program = 'ZGG_EX_01' list_to_memory = abap_true )
          is_continuation = VALUE #( id = 'AFTER_LIST_MEMORY' ) ).
      WHEN '98'.
        write_page_rows( lo_writer ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~get_settings.
    IF mv_mode = '91'.
      rs_settings = VALUE #( line_count = 4 footer_lines = 1 ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~top_of_page.
    IF mv_mode = '91'.
      write_line( io_writer = io_session->get_list( )->get_writer( )
                  iv_text = |header page { iv_page }| ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~end_of_page.
    IF mv_mode = '91'.
      write_line( io_writer = io_session->get_list( )->get_writer( )
                  iv_text = |footer page { iv_page }| ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~top_of_page_during_line_sel.
    RETURN.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_line_selection.
    DATA(lo_writer) = io_session->get_list( )->get_writer( ).
    DATA lv_value TYPE string.

    CASE mv_mode.
      WHEN '83'.
        READ TABLE is_line-fields INTO DATA(ls_level) WITH KEY name = 'LEVEL'.
        IF sy-subrc = 0 AND ls_level-value = '1'.
          write_line( io_writer = lo_writer iv_text = 'Detail list'
                      it_hide = VALUE #( ( name = 'LEVEL' value = '2' )
                                         ( name = 'NODE' value = 'SUBDETAIL' ) ) ).
        ELSE.
          write_line( io_writer = lo_writer iv_text = 'Subdetail list'
                      it_hide = VALUE #( ( name = 'LEVEL' value = '3' ) ) ).
        ENDIF.
      WHEN '84'.
        READ TABLE is_line-fields INTO DATA(ls_secret) WITH KEY name = 'SECRET'.
        IF sy-subrc = 0.
          write_line( io_writer = lo_writer iv_text = |selected { ls_secret-value }| ).
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_user_command.
    DATA(lo_writer) = io_session->get_list( )->get_writer( ).
    DATA ls_line TYPE zif_gg_list_processing_types_v1=>ty_line.

    CASE mv_mode.
      WHEN '85'.
        IF iv_ucomm = 'REFRESH'.
          mv_refresh = mv_refresh + 1.
          set_status( io_session ).
          write_line( io_writer = lo_writer iv_text = 'refreshed from server state' ).
        ENDIF.
      WHEN '86'.
        IF iv_ucomm = 'MODIFY'.
          ls_line = io_session->get_list( )->read_line( iv_index = 1 ).
          ls_line-format-intensified = abap_true.
          ls_line-format-color = zif_gg_list_processing_types_v1=>color_positive.
          io_session->get_list( )->modify_line( ls_line ).
          ls_line = io_session->get_list( )->read_line( iv_index = 2 ).
          ls_line-format-inverse = abap_true.
          ls_line-format-color = zif_gg_list_processing_types_v1=>color_negative.
          io_session->get_list( )->modify_line( ls_line ).
        ENDIF.
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
            write_line( io_writer = lo_writer iv_text = |Found LH at row { mv_find }| ).
          ENDIF.
        ENDIF.
      WHEN '94'.
        IF iv_ucomm = 'PRINT_VIEW'.
          write_line( io_writer = lo_writer iv_text = 'PRINT VIEW - static representation' ).
        ENDIF.
      WHEN '95'.
        IF iv_ucomm = 'DOWNLOAD'.
          write_line( io_writer = lo_writer iv_text = 'download prepared: flights.csv (text/csv)' ).
        ENDIF.
      WHEN '96'.
        IF iv_ucomm = 'MESSAGES'.
          io_session->message( VALUE #( type = zif_gg_session_types_v1=>message_type_success text = 'Success message' ) ).
          io_session->message( VALUE #( type = zif_gg_session_types_v1=>message_type_warning text = 'Warning message' ) ).
          io_session->message( VALUE #( type = zif_gg_session_types_v1=>message_type_error text = 'Error message' ) ).
        ENDIF.
      WHEN '98'.
        CASE iv_ucomm.
          WHEN 'FILTER'.
            mv_filtered = abap_true.
          WHEN 'SORT'.
            mv_sorted = abap_true.
            CLEAR mv_filtered.
          WHEN 'REFRESH'.
            CLEAR: mv_filtered, mv_sorted.
        ENDCASE.
        set_status( io_session ).
        write_page_rows( lo_writer ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_gg_list_processing_v1~at_pf.
    RETURN.
  ENDMETHOD.

ENDCLASS.
