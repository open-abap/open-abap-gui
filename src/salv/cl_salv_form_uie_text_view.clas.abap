CLASS cl_salv_form_uie_text_view DEFINITION PUBLIC INHERITING FROM cl_salv_form_uie.
  PUBLIC SECTION.
    METHODS get_id
      RETURNING
        VALUE(result) TYPE string.
    METHODS set_label_id
      IMPORTING
        value TYPE string.
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
    DATA mv_id TYPE string.
    DATA mv_label_id TYPE string.
    CLASS-DATA mv_id_counter TYPE i.
    METHODS render_html REDEFINITION.
    METHODS html
      IMPORTING
        text          TYPE string
      RETURNING
        VALUE(result) TYPE string.
ENDCLASS.

CLASS cl_salv_form_uie_text_view IMPLEMENTATION.
  METHOD get_id.
    IF mv_id IS INITIAL.
      mv_id_counter = mv_id_counter + 1.
      mv_id = |gg-salv-form-{ mv_id_counter }|.
    ENDIF.
    result = mv_id.
  ENDMETHOD.

  METHOD set_label_id.
    mv_label_id = value.
  ENDMETHOD.

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
    result = |<span class="gg-salv-form-text" id="{ get_id( ) }"{ COND string( WHEN mv_label_id IS NOT INITIAL THEN | role="group" aria-labelledby="{ html( mv_label_id ) }"| ) } title="{ html( mv_tooltip ) }">{ html( mv_text ) }</span>|.
  ENDMETHOD.
ENDCLASS.
