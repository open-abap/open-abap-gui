CLASS cl_progress_indicator DEFINITION PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS progress_indicate
      IMPORTING
        i_text               TYPE any OPTIONAL
        i_processed          TYPE sy-tabix OPTIONAL
        i_total              TYPE sy-tabix OPTIONAL
        i_output_immediately TYPE abap_bool OPTIONAL
        i_msgid              TYPE sy-msgid OPTIONAL
        i_msgno              TYPE sy-msgno OPTIONAL
        i_msgv1              TYPE any OPTIONAL
        i_msgv2              TYPE any OPTIONAL
        i_msgv3              TYPE any OPTIONAL
        i_msgv4              TYPE any OPTIONAL
      EXPORTING
        e_progress_sent      TYPE abap_bool.
ENDCLASS.

CLASS cl_progress_indicator IMPLEMENTATION.
  METHOD progress_indicate.
* do nothing, gui is not supported, but background logic might indicatoe progress
    RETURN.
  ENDMETHOD.
ENDCLASS.