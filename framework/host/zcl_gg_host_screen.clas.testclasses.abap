CLASS ltcl_gg_host_screen DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

* A selection text with dictionary reference is the field label of the data
* element behind the field; a field without one keeps its name.

  PRIVATE SECTION.
    METHODS ddic_text_of_parameter FOR TESTING.
    METHODS ddic_text_of_select_option FOR TESTING.
    METHODS ddic_text_without_dictionary FOR TESTING.

ENDCLASS.

CLASS ltcl_gg_host_screen IMPLEMENTATION.

  METHOD ddic_text_of_parameter.
    DATA lv_program TYPE program.
    DATA lo_builder TYPE REF TO zif_gg_selection_screen_builder_v1.

    lo_builder = NEW zcl_gg_host_screen( ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_builder->get_ddic_text( ig_field = lv_program
                                       iv_name  = 'P_PROG' )
      exp = `ABAP program name` ).
  ENDMETHOD.

  METHOD ddic_text_of_select_option.
    DATA lt_programs TYPE RANGE OF program.
    DATA lo_builder TYPE REF TO zif_gg_selection_screen_builder_v1.

    lo_builder = NEW zcl_gg_host_screen( ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_builder->get_ddic_text( ig_field = lt_programs
                                       iv_name  = 'S_PROG' )
      exp = `ABAP program name` ).
  ENDMETHOD.

  METHOD ddic_text_without_dictionary.
    DATA lv_plain TYPE c LENGTH 5.
    DATA lo_builder TYPE REF TO zif_gg_selection_screen_builder_v1.

    lo_builder = NEW zcl_gg_host_screen( ).
    cl_abap_unit_assert=>assert_equals(
      act = lo_builder->get_ddic_text( ig_field = lv_plain
                                       iv_name  = 'P_PLAIN' )
      exp = `P_PLAIN` ).
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_gg_host_radio_group DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.

* Exactly one button of a radio group starts selected: the one with DEFAULT
* 'X', otherwise the first button of the group.

  PRIVATE SECTION.
    METHODS first_button_without_default FOR TESTING.
    METHODS later_button_with_default FOR TESTING.
    METHODS groups_are_independent FOR TESTING.

    METHODS value
      IMPORTING
        io_screen       TYPE REF TO zcl_gg_host_screen
        iv_name         TYPE zif_gg_selection_screen_types=>ty_name
      RETURNING
        VALUE(rv_value) TYPE string.

ENDCLASS.

CLASS ltcl_gg_host_radio_group IMPLEMENTATION.

  METHOD first_button_without_default.
    DATA(lo_screen) = NEW zcl_gg_host_screen( ).
    DATA(lo_builder) = CAST zif_gg_selection_screen_builder_v1( lo_screen ).

    lo_builder->add_radiobutton( VALUE #( name = 'P_SYNC' radio_group = 'G1' ) ).
    lo_builder->add_radiobutton( VALUE #( name = 'P_BACK' radio_group = 'G1' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = value( io_screen = lo_screen
                   iv_name   = 'P_SYNC' )
      exp = `X` ).
    cl_abap_unit_assert=>assert_equals(
      act = value( io_screen = lo_screen
                   iv_name   = 'P_BACK' )
      exp = `` ).
  ENDMETHOD.

  METHOD later_button_with_default.
    DATA(lo_screen) = NEW zcl_gg_host_screen( ).
    DATA(lo_builder) = CAST zif_gg_selection_screen_builder_v1( lo_screen ).

    lo_builder->add_radiobutton( VALUE #( name = 'P_SYNC' radio_group = 'G1' ) ).
    lo_builder->add_radiobutton( VALUE #( name = 'P_BACK' radio_group = 'G1' default = abap_true ) ).

    cl_abap_unit_assert=>assert_equals(
      act = value( io_screen = lo_screen
                   iv_name   = 'P_SYNC' )
      exp = `` ).
    cl_abap_unit_assert=>assert_equals(
      act = value( io_screen = lo_screen
                   iv_name   = 'P_BACK' )
      exp = `X` ).
  ENDMETHOD.

  METHOD groups_are_independent.
    DATA(lo_screen) = NEW zcl_gg_host_screen( ).
    DATA(lo_builder) = CAST zif_gg_selection_screen_builder_v1( lo_screen ).

    lo_builder->add_radiobutton( VALUE #( name = 'P_A1' radio_group = 'G1' ) ).
    lo_builder->add_radiobutton( VALUE #( name = 'P_A2' radio_group = 'G1' ) ).
    lo_builder->add_radiobutton( VALUE #( name = 'P_B1' radio_group = 'G2' ) ).
    lo_builder->add_radiobutton( VALUE #( name = 'P_B2' radio_group = 'G2' default = abap_true ) ).

    cl_abap_unit_assert=>assert_equals(
      act = value( io_screen = lo_screen
                   iv_name   = 'P_A1' )
      exp = `X` ).
    cl_abap_unit_assert=>assert_equals(
      act = value( io_screen = lo_screen
                   iv_name   = 'P_B1' )
      exp = `` ).
    cl_abap_unit_assert=>assert_equals(
      act = value( io_screen = lo_screen
                   iv_name   = 'P_B2' )
      exp = `X` ).
  ENDMETHOD.

  METHOD value.
    DATA(lt_values) = io_screen->get_values( ).
    READ TABLE lt_values INTO DATA(ls_value) WITH KEY name = iv_name.
    rv_value = ls_value-value.
  ENDMETHOD.

ENDCLASS.
