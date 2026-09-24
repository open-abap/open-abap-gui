REPORT zexample_lstatic.

DATA gv_greeting TYPE string.

CLASS lcl_greeter DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS greet
      IMPORTING iv_name        TYPE string
      RETURNING VALUE(rv_text) TYPE string.
    CLASS-METHODS remember IMPORTING iv_text TYPE string.
ENDCLASS.

CLASS lcl_greeter IMPLEMENTATION.
  METHOD greet.
    rv_text = |Hello { iv_name }|.
  ENDMETHOD.

  METHOD remember.
    gv_greeting = iv_text.
  ENDMETHOD.
ENDCLASS.

START-OF-SELECTION.
  DATA(lv_text) = lcl_greeter=>greet( `World` ).
  lcl_greeter=>remember( lv_text ).
  WRITE: / gv_greeting.
