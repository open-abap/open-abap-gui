CLASS cl_dragdropobject DEFINITION PUBLIC.
  PUBLIC SECTION.
    DATA object TYPE REF TO object.
    DATA effect TYPE i.

    DATA flavor TYPE c LENGTH 40 READ-ONLY.
    DATA state TYPE i VALUE 0 READ-ONLY.

    METHODS abort.
ENDCLASS.

CLASS cl_dragdropobject IMPLEMENTATION.
  METHOD abort.
    RETURN. " todo, implement method
  ENDMETHOD.

ENDCLASS.