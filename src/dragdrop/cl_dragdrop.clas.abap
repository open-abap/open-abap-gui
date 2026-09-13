CLASS cl_dragdrop DEFINITION PUBLIC.
  PUBLIC SECTION.

    METHODS constructor.

    CONSTANTS copy TYPE i VALUE 1.
    CONSTANTS move TYPE i VALUE 2.

    METHODS add
      IMPORTING
        flavor         TYPE c
        dragsrc        TYPE abap_bool
        droptarget     TYPE abap_bool
        effect         TYPE i OPTIONAL
        effect_in_ctrl TYPE i OPTIONAL
      EXCEPTIONS
        already_defined
        obj_invalid.

    METHODS get
      IMPORTING
        flavor         TYPE c
      EXPORTING
        isdragsrc      TYPE abap_bool
        isdroptarget   TYPE abap_bool
        effect         TYPE i
        effect_in_ctrl TYPE i
      EXCEPTIONS
        not_found
        obj_invalid.

    METHODS get_handle
      EXPORTING
        handle TYPE i
      EXCEPTIONS
        obj_invalid.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_flavor,
             flavor         TYPE cndd_flavor,
             is_drag_source TYPE abap_bool,
             is_drop_target TYPE abap_bool,
             effect         TYPE i,
             effect_in_ctrl TYPE i,
           END OF ty_flavor.
    TYPES ty_flavors TYPE STANDARD TABLE OF ty_flavor WITH DEFAULT KEY.
    CLASS-DATA mv_next_handle TYPE i.
    DATA mv_handle TYPE i.
    DATA mt_flavors TYPE ty_flavors.

ENDCLASS.

CLASS cl_dragdrop IMPLEMENTATION.
  METHOD constructor.
    mv_next_handle = mv_next_handle + 1.
    mv_handle = mv_next_handle.
  ENDMETHOD.

  METHOD add.
    READ TABLE mt_flavors TRANSPORTING NO FIELDS WITH KEY flavor = flavor.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    APPEND VALUE #( flavor         = flavor
                    is_drag_source = dragsrc
                    is_drop_target = droptarget
                    effect         = effect
                    effect_in_ctrl = effect_in_ctrl ) TO mt_flavors.
  ENDMETHOD.

  METHOD get_handle.
    handle = mv_handle.
  ENDMETHOD.

  METHOD get.
    CLEAR: isdragsrc, isdroptarget, effect, effect_in_ctrl.
    READ TABLE mt_flavors INTO DATA(ls_flavor) WITH KEY flavor = flavor.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    isdragsrc = ls_flavor-is_drag_source.
    isdroptarget = ls_flavor-is_drop_target.
    effect = ls_flavor-effect.
    effect_in_ctrl = ls_flavor-effect_in_ctrl.
  ENDMETHOD.

ENDCLASS.
