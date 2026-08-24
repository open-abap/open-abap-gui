CLASS cl_salv_form_label DEFINITION PUBLIC INHERITING FROM cl_salv_form_uie_text_view.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        r_label_for TYPE REF TO cl_salv_form_text OPTIONAL
        text        TYPE any OPTIONAL
        tooltip     TYPE any OPTIONAL.

    METHODS set_label_for
      IMPORTING
        value TYPE REF TO cl_salv_form_uie_text_view.

    METHODS get_label_for
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_form_uie_text_view.

ENDCLASS.

CLASS cl_salv_form_label IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_label_for.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_label_for.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
