CLASS cl_dd_document DEFINITION PUBLIC INHERITING FROM cl_dd_area.
  PUBLIC SECTION.

    CONSTANTS heading TYPE c LENGTH 50 VALUE 'HEADING'.
    CONSTANTS list_heading_int TYPE c LENGTH 50 VALUE 'LIST_HEADING_INT'.
    CONSTANTS list_normal TYPE c LENGTH 50 VALUE 'LIST_NORMAL'.
    CONSTANTS medium TYPE c LENGTH 50 VALUE 'MEDIUM'.
    CONSTANTS small TYPE c LENGTH 50 VALUE 'SMALL'.

    METHODS add_picture
      IMPORTING
        picture_id TYPE any
        width      TYPE any.

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

ENDCLASS.

CLASS cl_dd_document IMPLEMENTATION.
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