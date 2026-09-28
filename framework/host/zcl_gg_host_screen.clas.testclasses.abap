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
