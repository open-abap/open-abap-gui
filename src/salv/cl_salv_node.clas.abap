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

    METHODS set_text
      IMPORTING
        value TYPE clike.

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

  METHOD set_text.
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
