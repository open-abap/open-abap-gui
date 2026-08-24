CLASS cl_salv_node DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS get_key
      RETURNING
        VALUE(value) TYPE salv_de_node_key.

    METHODS get_item
      IMPORTING
        columnname   TYPE lvc_fname
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_item
      RAISING
        cx_salv_msg.

    METHODS get_hierarchy_item
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_item.

    METHODS set_text
      IMPORTING
        value TYPE clike.

    METHODS get_text
      RETURNING
        VALUE(value) TYPE lvc_value.

    METHODS set_data_row
      IMPORTING
        value TYPE any.

    METHODS get_parent
      RETURNING
        VALUE(value) TYPE REF TO cl_salv_node
      RAISING
        cx_salv_msg.

    METHODS set_folder
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS set_expander
      IMPORTING
        value TYPE abap_bool DEFAULT abap_true.

    METHODS expand
      IMPORTING
        subtree TYPE abap_bool OPTIONAL.

    METHODS collapse.

ENDCLASS.

CLASS cl_salv_node IMPLEMENTATION.

  METHOD get_key.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_item.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_hierarchy_item.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_text.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_text.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_data_row.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD get_parent.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_folder.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD set_expander.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD expand.
    RETURN. " todo, implement method
  ENDMETHOD.

  METHOD collapse.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
