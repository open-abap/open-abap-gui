CLASS cl_dd_document DEFINITION PUBLIC INHERITING FROM cl_dd_area.
  PUBLIC SECTION.

    DATA html_control TYPE REF TO cl_gui_html_viewer.

    METHODS constructor
      IMPORTING
        style            TYPE sdydo_attribute OPTIONAL
        background_color TYPE i OPTIONAL
        bds_stylesheet   TYPE any OPTIONAL
        no_margins       TYPE abap_bool OPTIONAL.

    METHODS add_picture
      IMPORTING
        picture_id TYPE any
        width      TYPE any OPTIONAL.

    METHODS display_document
      IMPORTING
        reuse_control      TYPE abap_bool OPTIONAL
        reuse_registration TYPE abap_bool OPTIONAL
        container          TYPE clike OPTIONAL
        parent             TYPE REF TO cl_gui_container OPTIONAL.

    METHODS set_document_background
      IMPORTING
        picture_id TYPE any OPTIONAL.

    METHODS merge_document.

    METHODS initialize_document
      IMPORTING
        background_color TYPE i OPTIONAL.

    METHODS vertical_split
      IMPORTING
        split_area  TYPE REF TO cl_dd_area
        split_width TYPE clike OPTIONAL
      EXPORTING
        right_area  TYPE REF TO cl_dd_area.

    METHODS print_document
      IMPORTING
        reuse_control TYPE sdydo_flag OPTIONAL
      EXCEPTIONS
        html_print_error.

ENDCLASS.

CLASS cl_dd_document IMPLEMENTATION.
  METHOD constructor.
    initialize_document( background_color = background_color ).
  ENDMETHOD.

  METHOD print_document.
    cl_gui_control=>set_external_html( html_content ).
  ENDMETHOD.

  METHOD vertical_split.
    right_area = split_area.
    IF right_area IS NOT BOUND.
      right_area = NEW cl_dd_area( ).
    ENDIF.
    html_content = html_content && `<div class="gg-dd-split">`.
  ENDMETHOD.

  METHOD initialize_document.
    CLEAR html_content.
    html_content = |<section class="gg-dd-document" aria-label="Dynamic document" data-background="{ background_color }">|.
  ENDMETHOD.

  METHOD merge_document.
    html_content = html_content && `</section>`.
    fill_html_table( ).
  ENDMETHOD.

  METHOD display_document.
    DATA lt_html TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    fill_html_table( ).
    IF parent IS BOUND AND html_control IS NOT BOUND.
      html_control = NEW cl_gui_html_viewer( parent = parent ).
    ENDIF.
    IF html_control IS BOUND.
      APPEND html_content TO lt_html.
      html_control->load_data( CHANGING data_table = lt_html ).
    ELSE.
      cl_gui_control=>set_external_html( html_content ).
    ENDIF.
  ENDMETHOD.

  METHOD add_picture.
    html_content = html_content && |<img class="gg-dd-picture" src="{ cl_gui_control=>escape_html( CONV string( picture_id ) ) }" width="{ width }" alt="Dynamic document picture">|.
  ENDMETHOD.

  METHOD set_document_background.
    html_content = html_content && |<div class="gg-dd-background" data-picture="{ cl_gui_control=>escape_html( CONV string( picture_id ) ) }">|.
  ENDMETHOD.

ENDCLASS.
