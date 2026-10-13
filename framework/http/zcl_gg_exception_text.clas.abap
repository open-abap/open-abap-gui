CLASS zcl_gg_exception_text DEFINITION PUBLIC FINAL CREATE PUBLIC.

* The explanation of an exception no program handled: its class, its text,
* its public attributes and the exceptions chained through PREVIOUS. An
* exception without a text of its own still names its class and the values
* it carries, such as the FUNCTION of CX_SY_DYN_CALL_ILLEGAL_FUNC.

  PUBLIC SECTION.
* One line per exception, for a JSON error.
    CLASS-METHODS describe
      IMPORTING
        ix_error       TYPE REF TO cx_root
      RETURNING
        VALUE(rv_text) TYPE string.

* One line per detail, for a page that shows the exception, with where each
* exception was raised when that is known.
    CLASS-METHODS details
      IMPORTING
        ix_error       TYPE REF TO cx_root
      RETURNING
        VALUE(rv_text) TYPE string.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_part,
             class_name TYPE string,
             text       TYPE string,
             position   TYPE string,
             attributes TYPE string_table,
           END OF ty_part.
    TYPES ty_parts TYPE STANDARD TABLE OF ty_part WITH EMPTY KEY.

* The chain is followed this far, so a cycle ends it.
    CONSTANTS c_max_chain TYPE i VALUE 10.
    CONSTANTS c_fallback TYPE string VALUE `Unknown error (no message available)`.
* The text open-abap gives an exception that has no text of its own.
    CONSTANTS c_generic_text TYPE string VALUE `An exception was raised.`.
* The program open-abap gives an exception the runtime raised, rather than a
* RAISE EXCEPTION statement; where it was raised is not known.
    CONSTANTS c_unknown_program TYPE string VALUE `error`.

    CLASS-METHODS parts
      IMPORTING
        ix_error        TYPE REF TO cx_root
      RETURNING
        VALUE(rt_parts) TYPE ty_parts.

    CLASS-METHODS part
      IMPORTING
        ix_error       TYPE REF TO cx_root
      RETURNING
        VALUE(rs_part) TYPE ty_part.

    CLASS-METHODS position
      IMPORTING
        ix_error           TYPE REF TO cx_root
      RETURNING
        VALUE(rv_position) TYPE string.
ENDCLASS.

CLASS zcl_gg_exception_text IMPLEMENTATION.

  METHOD describe.
    DATA lv_line TYPE string.

    LOOP AT parts( ix_error ) INTO DATA(ls_part).
      lv_line = ls_part-class_name.
      IF ls_part-attributes IS NOT INITIAL.
        lv_line = |{ lv_line } ({ concat_lines_of( table = ls_part-attributes
                                                   sep   = `, ` ) })|.
      ENDIF.
      IF ls_part-text IS NOT INITIAL.
        lv_line = |{ lv_line }: { ls_part-text }|.
      ENDIF.
      IF sy-tabix = 1.
        rv_text = lv_line.
      ELSE.
        rv_text = |{ rv_text }\nCaused by: { lv_line }|.
      ENDIF.
    ENDLOOP.
    IF rv_text IS INITIAL.
      rv_text = c_fallback.
    ENDIF.
  ENDMETHOD.

  METHOD details.
    LOOP AT parts( ix_error ) INTO DATA(ls_part).
      IF sy-tabix = 1.
        rv_text = |Unhandled exception { ls_part-class_name }|.
      ELSE.
        rv_text = |{ rv_text }\n\nCaused by { ls_part-class_name }|.
      ENDIF.
      IF ls_part-position IS NOT INITIAL.
        rv_text = |{ rv_text }\n{ ls_part-position }|.
      ENDIF.
      IF ls_part-text IS NOT INITIAL.
        rv_text = |{ rv_text }\n{ ls_part-text }|.
      ENDIF.
      LOOP AT ls_part-attributes INTO DATA(lv_attribute).
        rv_text = |{ rv_text }\n{ lv_attribute }|.
      ENDLOOP.
    ENDLOOP.
    IF rv_text IS INITIAL.
      rv_text = c_fallback.
    ENDIF.
  ENDMETHOD.

  METHOD parts.
    DATA lx_current TYPE REF TO cx_root.

    lx_current = ix_error.
    WHILE lx_current IS BOUND AND lines( rt_parts ) < c_max_chain.
      APPEND part( lx_current ) TO rt_parts.
      lx_current = lx_current->previous.
    ENDWHILE.
  ENDMETHOD.

  METHOD part.
    DATA lo_class TYPE REF TO cl_abap_classdescr.
    DATA lv_value TYPE string.
    FIELD-SYMBOLS <lv_value> TYPE any.

    lo_class ?= cl_abap_typedescr=>describe_by_object_ref( ix_error ).
    rs_part-class_name = lo_class->get_relative_name( ).
    rs_part-text = ix_error->get_text( ).
    CONDENSE rs_part-text.
    IF rs_part-text = c_generic_text.
      CLEAR rs_part-text.
    ENDIF.
    rs_part-position = position( ix_error ).

* The nonempty elementary public instance attributes. CX_ROOT's own are left
* out; PREVIOUS is shown as the chain.
    LOOP AT lo_class->attributes INTO DATA(ls_attribute)
        WHERE visibility = cl_abap_objectdescr=>public
        AND is_constant = abap_false
        AND is_class = abap_false
        AND is_interface = abap_false.
      IF ls_attribute-name = 'PREVIOUS'
          OR ls_attribute-name = 'TEXTID'
          OR ls_attribute-name = 'KERNEL_ERRID'.
        CONTINUE.
      ENDIF.
      ASSIGN ix_error->(ls_attribute-name) TO <lv_value>.
      IF sy-subrc <> 0 OR <lv_value> IS INITIAL.
        CONTINUE.
      ENDIF.
      IF cl_abap_typedescr=>describe_by_data( <lv_value> )->kind <> cl_abap_typedescr=>kind_elem.
        CONTINUE.
      ENDIF.
      lv_value = |{ <lv_value> }|.
      CONDENSE lv_value.
      IF lv_value IS INITIAL OR lv_value = rs_part-text.
        CONTINUE.
      ENDIF.
      APPEND |{ ls_attribute-name } = { lv_value }| TO rs_part-attributes.
    ENDLOOP.
  ENDMETHOD.

  METHOD position.
    DATA lv_program TYPE syrepid.
    DATA lv_include TYPE syrepid.
    DATA lv_line TYPE i.

    ix_error->get_source_position(
      IMPORTING
        program_name = lv_program
        include_name = lv_include
        source_line  = lv_line ).
    IF lv_program IS INITIAL OR lv_program = c_unknown_program OR lv_line <= 0.
      RETURN.
    ENDIF.
    rv_position = |Raised at { lv_program }|.
    IF lv_include IS NOT INITIAL AND lv_include <> lv_program.
      rv_position = |{ rv_position } ({ lv_include })|.
    ENDIF.
    rv_position = |{ rv_position }, line { lv_line }|.
  ENDMETHOD.

ENDCLASS.
