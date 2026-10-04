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
  PROTECTED SECTION.
    METHODS render_html REDEFINITION.
  PRIVATE SECTION.
    DATA mo_label_for TYPE REF TO cl_salv_form_uie_text_view.
ENDCLASS.

CLASS cl_salv_form_label IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    mv_text = text.
    mv_tooltip = tooltip.
    mo_label_for = r_label_for.
  ENDMETHOD.

  METHOD set_label_for.
    mo_label_for = value.
  ENDMETHOD.

  METHOD get_label_for.
    value = mo_label_for.
  ENDMETHOD.

  METHOD render_html.
    result = |<span class="gg-salv-form-label" title="{ html( mv_tooltip ) }">{ html( mv_text ) }</span>|.
  ENDMETHOD.
ENDCLASS.
