CLASS cl_salv_form_header_info DEFINITION PUBLIC INHERITING FROM cl_salv_form_uie_text_view.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        text    TYPE any OPTIONAL
        tooltip TYPE any OPTIONAL.
  PROTECTED SECTION.
    METHODS render_html REDEFINITION.
ENDCLASS.

CLASS cl_salv_form_header_info IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    mv_text = text.
    mv_tooltip = tooltip.
  ENDMETHOD.

  METHOD render_html.
    result = |<strong class="gg-salv-form-header" title="{ html( mv_tooltip ) }">{ html( mv_text ) }</strong>|.
  ENDMETHOD.
ENDCLASS.
