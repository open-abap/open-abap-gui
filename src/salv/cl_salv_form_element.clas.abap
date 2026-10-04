* A SALV form (top or end of list) is a tree of elements. Each element renders
* itself; cl_salv_table shows the HTML above or below the list.
CLASS cl_salv_form_element DEFINITION PUBLIC
  FRIENDS cl_salv_table cl_salv_form_layout_grid cl_salv_form_layout_flow.
  PUBLIC SECTION.
  PROTECTED SECTION.
    METHODS render_html
      RETURNING
        VALUE(result) TYPE string.
ENDCLASS.

CLASS cl_salv_form_element IMPLEMENTATION.
  METHOD render_html.
    RETURN.
  ENDMETHOD.
ENDCLASS.
