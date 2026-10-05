CLASS cl_salv_form_layout_flow DEFINITION PUBLIC INHERITING FROM cl_salv_form_uie.
  PUBLIC SECTION.
    METHODS create_text
      IMPORTING
        position       TYPE i OPTIONAL
        text           TYPE any OPTIONAL
        tooltip        TYPE any OPTIONAL
      RETURNING
        VALUE(r_value) TYPE REF TO cl_salv_form_text.
    METHODS create_label
      IMPORTING
        position       TYPE i OPTIONAL
        r_label_for    TYPE REF TO cl_salv_form_text OPTIONAL
        text           TYPE any OPTIONAL
        tooltip        TYPE any OPTIONAL
      RETURNING
        VALUE(r_value) TYPE REF TO cl_salv_form_label.
    METHODS create_header_information
      IMPORTING
        position       TYPE i OPTIONAL
        text           TYPE any OPTIONAL
        tooltip        TYPE any OPTIONAL
      RETURNING
        VALUE(r_value) TYPE REF TO cl_salv_form_header_info.
    METHODS create_flow
      IMPORTING
        position       TYPE i OPTIONAL
      RETURNING
        VALUE(r_value) TYPE REF TO cl_salv_form_layout_flow.
  PROTECTED SECTION.
    METHODS render_html REDEFINITION.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_child,
             position TYPE i,
             element  TYPE REF TO cl_salv_form_element,
           END OF ty_child.
    DATA mt_children TYPE STANDARD TABLE OF ty_child WITH DEFAULT KEY.
    METHODS add
      IMPORTING
        position TYPE i
        element  TYPE REF TO cl_salv_form_element.
ENDCLASS.

CLASS cl_salv_form_layout_flow IMPLEMENTATION.
  METHOD add.
    DATA(lv_position) = position.
    IF lv_position = 0.
      lv_position = lines( mt_children ) + 1.
    ENDIF.
    DELETE mt_children WHERE position = lv_position.
    APPEND VALUE #( position = lv_position
                    element  = element ) TO mt_children.
    SORT mt_children BY position.
  ENDMETHOD.

  METHOD create_text.
    r_value = NEW #( text    = text
                     tooltip = tooltip ).
    add( position = position
         element  = r_value ).
  ENDMETHOD.

  METHOD create_label.
    r_value = NEW #( r_label_for = r_label_for
                     text        = text
                     tooltip     = tooltip ).
    add( position = position
         element  = r_value ).
  ENDMETHOD.

  METHOD create_header_information.
    r_value = NEW #( text    = text
                     tooltip = tooltip ).
    add( position = position
         element  = r_value ).
  ENDMETHOD.

  METHOD create_flow.
    r_value = NEW #( ).
    add( position = position
         element  = r_value ).
  ENDMETHOD.

  METHOD render_html.
    LOOP AT mt_children INTO DATA(ls_child).
      result = result && ls_child-element->render_html( ) && | |.
    ENDLOOP.
    result = |<span class="gg-salv-form-flow">{ result }</span>|.
  ENDMETHOD.
ENDCLASS.
