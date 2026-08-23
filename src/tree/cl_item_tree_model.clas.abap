CLASS cl_item_tree_model DEFINITION PUBLIC INHERITING FROM cl_tree_model.
  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        node_selection_mode TYPE i OPTIONAL
        hide_selection      TYPE abap_bool OPTIONAL
        item_selection      TYPE abap_bool OPTIONAL.

ENDCLASS.

CLASS cl_item_tree_model IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.
