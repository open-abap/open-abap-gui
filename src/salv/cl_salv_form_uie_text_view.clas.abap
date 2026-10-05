CLASS cl_salv_form_uie_text_view DEFINITION PUBLIC INHERITING FROM cl_salv_form_uie.
  PUBLIC SECTION.
    METHODS set_text
      IMPORTING
        value TYPE any.
    METHODS get_text
      RETURNING
        VALUE(value) TYPE string.
    METHODS set_tooltip
      IMPORTING
        value TYPE any.
    METHODS get_tooltip
      RETURNING
        VALUE(value) TYPE string.
  PROTECTED SECTION.
    DATA mv_text TYPE string.
    DATA mv_tooltip TYPE string.
    METHODS render_html REDEFINITION.
    METHODS html
      IMPORTING
        text          TYPE string
      RETURNING
        VALUE(result) TYPE string.
ENDCLASS.

CLASS cl_salv_form_uie_text_view IMPLEMENTATION.
  METHOD set_text.
    mv_text = value.
  ENDMETHOD.

  METHOD get_text.
    value = mv_text.
  ENDMETHOD.

  METHOD set_tooltip.
    mv_tooltip = value.
  ENDMETHOD.

  METHOD get_tooltip.
    value = mv_tooltip.
  ENDMETHOD.

  METHOD html.
    result = escape( val    = text
                     format = cl_abap_format=>e_html_text ).
  ENDMETHOD.

  METHOD render_html.
    result = |<span class="gg-salv-form-text" title="{ html( mv_tooltip ) }">{ html( mv_text ) }</span>|.
  ENDMETHOD.
ENDCLASS.
