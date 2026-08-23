TYPE-POOL slis.

CONSTANTS slis_ev_before_line_output TYPE c LENGTH 30 VALUE 'BEFORE_LINE_OUTPUT'.
CONSTANTS slis_ev_data_changed TYPE c LENGTH 30 VALUE 'DATA_CHANGED'.
CONSTANTS slis_ev_end_of_list TYPE c LENGTH 30 VALUE 'END_OF_LIST'.
CONSTANTS slis_ev_list_modify TYPE c LENGTH 30 VALUE 'LIST_MODIFY'.
CONSTANTS slis_ev_pf_status_set TYPE c LENGTH 30 VALUE 'PF_STATUS_SET'.
CONSTANTS slis_ev_subtotal_text TYPE c LENGTH 30 VALUE 'SUBTOTAL_TEXT'.
CONSTANTS slis_ev_top_of_list TYPE c LENGTH 30 VALUE 'TOP_OF_LIST'.
CONSTANTS slis_ev_top_of_page TYPE c LENGTH 30 VALUE 'TOP_OF_PAGE'.
CONSTANTS slis_ev_user_command TYPE c LENGTH 30 VALUE 'USER_COMMAND'.

TYPES slis_entry TYPE c LENGTH 60.

TYPES: BEGIN OF slis_listheader,
         typ  TYPE c LENGTH 1,
         key  TYPE c LENGTH 20,
         info TYPE slis_entry,
       END OF slis_listheader.
TYPES slis_t_listheader TYPE STANDARD TABLE OF slis_listheader WITH DEFAULT KEY.

TYPES slis_char_1 TYPE c LENGTH 1.
TYPES slis_coldesc TYPE c LENGTH 4.
TYPES slis_edit_mask TYPE c LENGTH 60.
TYPES slis_fieldname TYPE c LENGTH 30.
TYPES slis_formname TYPE c LENGTH 30.
TYPES slis_list_type TYPE n LENGTH 1.
TYPES slis_sel_tab_field TYPE c LENGTH 60.
TYPES slis_tabname TYPE c LENGTH 30.
TYPES slis_text40 TYPE c LENGTH 40.

* Field catalog, one entry per output column
TYPES: BEGIN OF slis_fieldcat_alv,
         row_pos           TYPE sy-curow,
         col_pos           TYPE sy-cucol,
         fieldname         TYPE slis_fieldname,
         tabname           TYPE slis_tabname,
         currency          TYPE c LENGTH 5,
         cfieldname        TYPE slis_fieldname,
         ctabname          TYPE slis_tabname,
         ifieldname        TYPE slis_fieldname,
         quantity          TYPE c LENGTH 3,
         qfieldname        TYPE slis_fieldname,
         qtabname          TYPE slis_tabname,
         round             TYPE i,
         exponent          TYPE c LENGTH 3,
         key               TYPE c LENGTH 1,
         icon              TYPE c LENGTH 1,
         symbol            TYPE c LENGTH 1,
         checkbox          TYPE c LENGTH 1,
         just              TYPE c LENGTH 1,
         lzero             TYPE c LENGTH 1,
         no_sign           TYPE c LENGTH 1,
         no_zero           TYPE c LENGTH 1,
         no_convext        TYPE c LENGTH 1,
         edit_mask         TYPE slis_edit_mask,
         emphasize         TYPE c LENGTH 4,
         fix_column        TYPE c LENGTH 1,
         do_sum            TYPE c LENGTH 1,
         no_out            TYPE c LENGTH 1,
         tech              TYPE c LENGTH 1,
         outputlen         TYPE n LENGTH 6,
         offset            TYPE n LENGTH 6,
         seltext_l         TYPE c LENGTH 40,
         seltext_m         TYPE c LENGTH 20,
         seltext_s         TYPE c LENGTH 10,
         ddictxt           TYPE c LENGTH 1,
         rollname          TYPE c LENGTH 30,
         datatype          TYPE c LENGTH 4,
         inttype           TYPE c LENGTH 1,
         intlen            TYPE n LENGTH 6,
         lowercase         TYPE c LENGTH 1,
         decfloat_style    TYPE n LENGTH 2,
         parameter0        TYPE c LENGTH 30,
         parameter1        TYPE c LENGTH 30,
         parameter2        TYPE c LENGTH 30,
         parameter3        TYPE c LENGTH 30,
         parameter4        TYPE c LENGTH 30,
         parameter5        TYPE i,
         parameter6        TYPE i,
         parameter7        TYPE i,
         parameter8        TYPE i,
         parameter9        TYPE i,
         ref_fieldname     TYPE c LENGTH 30,
         ref_tabname       TYPE c LENGTH 30,
         roundfieldname    TYPE slis_fieldname,
         roundtabname      TYPE slis_tabname,
         decimalsfieldname TYPE slis_fieldname,
         decimalstabname   TYPE slis_tabname,
         decimals_out      TYPE c LENGTH 6,
         text_fieldname    TYPE slis_fieldname,
         reptext_ddic      TYPE c LENGTH 55,
         ddic_outputlen    TYPE n LENGTH 6,
         key_sel           TYPE c LENGTH 1,
         no_sum            TYPE c LENGTH 1,
         sp_group          TYPE c LENGTH 4,
         reprep            TYPE c LENGTH 1,
         input             TYPE c LENGTH 1,
         edit              TYPE c LENGTH 1,
         hotspot           TYPE c LENGTH 1,
       END OF slis_fieldcat_alv.
TYPES slis_t_fieldcat_alv TYPE STANDARD TABLE OF slis_fieldcat_alv WITH DEFAULT KEY.

* List layout
TYPES: BEGIN OF slis_layout_alv,
         dummy                TYPE c LENGTH 1,
         no_colhead           TYPE c LENGTH 1,
         no_hotspot           TYPE c LENGTH 1,
         zebra                TYPE c LENGTH 1,
         no_vline             TYPE c LENGTH 1,
         no_hline             TYPE c LENGTH 1,
         cell_merge           TYPE c LENGTH 1,
         edit                 TYPE c LENGTH 1,
         edit_mode            TYPE c LENGTH 1,
         numc_sum             TYPE c LENGTH 1,
         no_input             TYPE c LENGTH 1,
         f2code               TYPE sy-ucomm,
         reprep               TYPE c LENGTH 1,
         no_keyfix            TYPE c LENGTH 1,
         expand_all           TYPE c LENGTH 1,
         no_author            TYPE c LENGTH 1,
         def_status           TYPE c LENGTH 1,
         item_text            TYPE c LENGTH 20,
         countfname           TYPE lvc_fname,
         colwidth_optimize    TYPE c LENGTH 1,
         no_min_linesize      TYPE c LENGTH 1,
         min_linesize         TYPE sy-linsz,
         max_linesize         TYPE sy-linsz,
         window_titlebar      TYPE sy-title,
         no_uline_hs          TYPE c LENGTH 1,
         lights_fieldname     TYPE slis_fieldname,
         lights_tabname       TYPE slis_tabname,
         lights_rollname      TYPE c LENGTH 30,
         lights_condense      TYPE c LENGTH 1,
         no_sumchoice         TYPE c LENGTH 1,
         no_totalline         TYPE c LENGTH 1,
         no_subchoice         TYPE c LENGTH 1,
         no_subtotals         TYPE c LENGTH 1,
         no_unit_splitting    TYPE c LENGTH 1,
         totals_before_items  TYPE c LENGTH 1,
         totals_only          TYPE c LENGTH 1,
         totals_text          TYPE c LENGTH 60,
         subtotals_text       TYPE c LENGTH 60,
         box_fieldname        TYPE slis_fieldname,
         box_tabname          TYPE slis_tabname,
         box_rollname         TYPE c LENGTH 30,
         expand_fieldname     TYPE slis_fieldname,
         hotspot_fieldname    TYPE slis_fieldname,
         confirmation_prompt  TYPE c LENGTH 1,
         key_hotspot          TYPE c LENGTH 1,
         flexible_key         TYPE c LENGTH 1,
         group_buttons        TYPE c LENGTH 1,
         get_selinfos         TYPE c LENGTH 1,
         group_change_edit    TYPE c LENGTH 1,
         no_scrolling         TYPE c LENGTH 1,
         detail_popup         TYPE c LENGTH 1,
         detail_initial_lines TYPE c LENGTH 1,
         detail_titlebar      TYPE sy-title,
         header_text          TYPE c LENGTH 20,
         default_item         TYPE c LENGTH 1,
         info_fieldname       TYPE slis_fieldname,
         coltab_fieldname     TYPE slis_fieldname,
         list_append          TYPE c LENGTH 1,
         xifunckey            TYPE c LENGTH 30,
         xidirect             TYPE c LENGTH 1,
*        DTC_LAYOUT TYPE dtc_s_layo is omitted, DTC_S_LAYO is not part of the
*        dependency surface
         allow_switch_to_list TYPE c LENGTH 1,
       END OF slis_layout_alv.

* Excluding table, function codes
TYPES: BEGIN OF slis_extab,
         fcode TYPE c LENGTH 20,
       END OF slis_extab.
TYPES slis_t_extab TYPE STANDARD TABLE OF slis_extab WITH DEFAULT KEY.

* Cursor position passed to the USER_COMMAND callback
TYPES: BEGIN OF slis_selfield,
         tabname       TYPE slis_tabname,
         tabindex      TYPE sy-tabix,
         sumindex      TYPE sy-tabix,
         endsum        TYPE c LENGTH 1,
         sel_tab_field TYPE slis_sel_tab_field,
         value         TYPE slis_entry,
         before_action TYPE c LENGTH 1,
         after_action  TYPE c LENGTH 1,
         refresh       TYPE c LENGTH 1,
         ignore_multi  TYPE c LENGTH 1,
         col_stable    TYPE c LENGTH 1,
         row_stable    TYPE c LENGTH 1,
         exit          TYPE c LENGTH 1,
         fieldname     TYPE slis_fieldname,
         grouplevel    TYPE i,
         collect_from  TYPE i,
         collect_to    TYPE i,
       END OF slis_selfield.

* Sort and subtotal criteria
TYPES: BEGIN OF slis_sortinfo_alv,
         spos       TYPE n LENGTH 2,
         fieldname  TYPE slis_fieldname,
         tabname    TYPE slis_fieldname,
         up         TYPE c LENGTH 1,
         down       TYPE c LENGTH 1,
         group      TYPE c LENGTH 2,
         subtot     TYPE c LENGTH 1,
         comp       TYPE c LENGTH 1,
         expa       TYPE c LENGTH 1,
         obligatory TYPE c LENGTH 1,
       END OF slis_sortinfo_alv.
TYPES slis_t_sortinfo_alv TYPE STANDARD TABLE OF slis_sortinfo_alv WITH DEFAULT KEY.

* Event name and the form routine handling it
TYPES: BEGIN OF slis_alv_event,
         name TYPE c LENGTH 30,
         form TYPE c LENGTH 30,
       END OF slis_alv_event.
TYPES slis_t_event TYPE STANDARD TABLE OF slis_alv_event WITH DEFAULT KEY.

* Key fields linking header and item table
TYPES: BEGIN OF slis_keyinfo_alv,
         header01 TYPE slis_fieldname,
         item01   TYPE slis_fieldname,
         header02 TYPE slis_fieldname,
         item02   TYPE slis_fieldname,
         header03 TYPE slis_fieldname,
         item03   TYPE slis_fieldname,
         header04 TYPE slis_fieldname,
         item04   TYPE slis_fieldname,
         header05 TYPE slis_fieldname,
         item05   TYPE slis_fieldname,
       END OF slis_keyinfo_alv.
