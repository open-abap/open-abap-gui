CLASS cl_salv_form_text DEFINITION PUBLIC INHERITING FROM cl_salv_form_uie_text_view.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        text    TYPE any OPTIONAL
        tooltip TYPE any OPTIONAL.

ENDCLASS.

CLASS cl_salv_form_text IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
