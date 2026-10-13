CLASS zcl_gg_exception_text DEFINITION PUBLIC FINAL CREATE PUBLIC.

* The explanation of an exception no program handled: its class, its text,
* its public attributes and the exceptions chained through PREVIOUS. An
* exception without a text of its own still names its class and the values
* it carries, such as the FUNCTION of CX_SY_DYN_CALL_ILLEGAL_FUNC.

  PUBLIC SECTION.
    CLASS-METHODS describe
      IMPORTING
        ix_error       TYPE REF TO cx_root
      RETURNING
        VALUE(rv_text) TYPE string.

  PRIVATE SECTION.
* The chain is followed this far, so a cycle ends it.
    CONSTANTS c_max_chain TYPE i VALUE 10.
    CONSTANTS c_fallback TYPE string VALUE `Unknown error (no message available)`.
* The text open-abap gives an exception that has no text of its own.
    CONSTANTS c_generic_text TYPE string VALUE `An exception was raised.`.

    CLASS-METHODS describe_one
      IMPORTING
        ix_error       TYPE REF TO cx_root
      RETURNING
        VALUE(rv_text) TYPE string.

    CLASS-METHODS attributes
      IMPORTING
        ix_error       TYPE REF TO cx_root
        iv_text        TYPE string
      RETURNING
        VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS zcl_gg_exception_text IMPLEMENTATION.

  METHOD describe.
    DATA lx_current TYPE REF TO cx_root.
    DATA lv_count TYPE i.

    lx_current = ix_error.
    WHILE lx_current IS BOUND AND lv_count < c_max_chain.
      IF lv_count = 0.
        rv_text = describe_one( lx_current ).
      ELSE.
        rv_text = rv_text && |\nCaused by: | && describe_one( lx_current ).
      ENDIF.
      lv_count = lv_count + 1.
      lx_current = lx_current->previous.
    ENDWHILE.
    IF rv_text IS INITIAL.
      rv_text = c_fallback.
    ENDIF.
  ENDMETHOD.

  METHOD describe_one.
    DATA lv_text TYPE string.
    DATA lv_attributes TYPE string.

    rv_text = cl_abap_typedescr=>describe_by_object_ref( ix_error )->get_relative_name( ).
    lv_text = ix_error->get_text( ).
    CONDENSE lv_text.
    IF lv_text = c_generic_text.
      CLEAR lv_text.
    ENDIF.
    lv_attributes = attributes( ix_error = ix_error
                                iv_text  = lv_text ).
    IF lv_attributes IS NOT INITIAL.
      rv_text = |{ rv_text } ({ lv_attributes })|.
    ENDIF.
    IF lv_text IS NOT INITIAL.
      rv_text = |{ rv_text }: { lv_text }|.
    ENDIF.
  ENDMETHOD.

  METHOD attributes.
    DATA lo_class TYPE REF TO cl_abap_classdescr.
    DATA lv_value TYPE string.
    FIELD-SYMBOLS <lv_value> TYPE any.

* The nonempty elementary public instance attributes. CX_ROOT's own are left
* out; PREVIOUS is shown as the chain.
    lo_class ?= cl_abap_typedescr=>describe_by_object_ref( ix_error ).
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
      IF lv_value IS INITIAL OR lv_value = iv_text.
        CONTINUE.
      ENDIF.
      IF rv_text IS NOT INITIAL.
        rv_text = rv_text && `, `.
      ENDIF.
      rv_text = |{ rv_text }{ ls_attribute-name } = { lv_value }|.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
