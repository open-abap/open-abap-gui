CLASS ltcl_gg_host_status DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS accepts_well_formed_entries FOR TESTING.
    METHODS rejects_missing_fields FOR TESTING.
    METHODS rejects_duplicate_commands FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_host_status IMPLEMENTATION.

  METHOD accepts_well_formed_entries.
    DATA(lv_error) = zcl_gg_host_status=>validate( VALUE #(
      icon_bar = VALUE #( ( ucomm = 'ONE' label = 'One' icon = 'refresh' )
                          ( ucomm = 'TWO' label = 'Two' icon = 'printer' separator = abap_true ) ) ) ).

    cl_abap_unit_assert=>assert_initial( lv_error ).
  ENDMETHOD.

  METHOD rejects_missing_fields.
    DATA(lv_error) = zcl_gg_host_status=>validate( VALUE #(
      icon_bar = VALUE #( ( ucomm = 'ONE' icon = 'refresh' ) ) ) ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_error CS 'requires a label' ) ).
  ENDMETHOD.

  METHOD rejects_duplicate_commands.
    DATA(lv_error) = zcl_gg_host_status=>validate( VALUE #(
      icon_bar = VALUE #( ( ucomm = 'ONE' label = 'One' icon = 'refresh' )
                          ( ucomm = 'ONE' label = 'Again' icon = 'printer' ) ) ) ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( lv_error CS 'Duplicate' ) ).
  ENDMETHOD.

ENDCLASS.
