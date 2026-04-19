CLASS cl_dd_document DEFINITION PUBLIC INHERITING FROM cl_dd_area.
  PUBLIC SECTION.

    DATA html_control TYPE REF TO cl_gui_html_viewer.

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

    METHODS new_line
      IMPORTING
        repeat TYPE i OPTIONAL.

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
  METHOD print_document.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD vertical_split.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD initialize_document.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD merge_document.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD display_document.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD add_picture.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD new_line.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_document_background.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.