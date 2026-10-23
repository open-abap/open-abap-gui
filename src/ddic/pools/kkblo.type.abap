TYPE-POOL kkblo.

TYPES kkblo_selfield TYPE slis_selfield.

TYPES BEGIN OF kkblo_fieldcat.
        INCLUDE STRUCTURE alv_s_fcat.
        INCLUDE STRUCTURE kkb_s_fcat.
INCLUDE TYPE slis_fieldcat_alv1.
TYPES: rollname_ddic    TYPE c LENGTH 30,
         tech_row_pos   LIKE sy-cucol,
         tech_col_pos   LIKE sy-cucol,
         tech_complete  TYPE c LENGTH 1,
       END OF kkblo_fieldcat.

TYPES kkblo_t_fieldcat TYPE kkblo_fieldcat OCCURS 1.

TYPES kkblo_fieldname TYPE slis_fieldname.

TYPES: BEGIN OF kkblo_keyinfo,
         master01 TYPE kkblo_fieldname,
         slave01  TYPE kkblo_fieldname,
         master02 TYPE kkblo_fieldname,
         slave02  TYPE kkblo_fieldname,
         master03 TYPE kkblo_fieldname,
         slave03  TYPE kkblo_fieldname,
         master04 TYPE kkblo_fieldname,
         slave04  TYPE kkblo_fieldname,
         master05 TYPE kkblo_fieldname,
         slave05  TYPE kkblo_fieldname,
       END OF kkblo_keyinfo.

TYPES BEGIN OF kkblo_sortinfo.
        INCLUDE STRUCTURE alv_s_sort.
        INCLUDE STRUCTURE kkb_s_sort.
TYPES END OF kkblo_sortinfo.
TYPES kkblo_t_sortinfo TYPE kkblo_sortinfo OCCURS 0.

TYPES BEGIN OF kkblo_sp_group.
INCLUDE STRUCTURE alv_s_sgrp.
INCLUDE STRUCTURE kkb_s_sgrp.
TYPES END OF kkblo_sp_group.
TYPES kkblo_t_sp_group TYPE kkblo_sp_group OCCURS 1.

TYPES BEGIN OF kkblo_filter.
        INCLUDE STRUCTURE alv_s_filt.
        INCLUDE STRUCTURE kkb_s_filt.
INCLUDE TYPE slis_filter_alv1.
TYPES END OF kkblo_filter.
TYPES kkblo_t_filter TYPE kkblo_filter OCCURS 1.

TYPES kkblo_extab TYPE slis_extab.
TYPES kkblo_t_extab TYPE kkblo_extab OCCURS 1.

TYPES kkblo_t_event_exit TYPE slis_t_event_exit.

TYPES BEGIN OF kkblo_coltypes.
INCLUDE TYPE slis_coltypes.
TYPES END OF kkblo_coltypes.

TYPES: BEGIN OF kkblo_incl_layout1,
         no_selinfos        TYPE c LENGTH 1,
         rowno_change       TYPE c LENGTH 1,
         no_numc_sum        TYPE c LENGTH 1,
         zebra_multi        TYPE c LENGTH 1,
         no_static_subtot   TYPE c LENGTH 1,
         colors             TYPE kkblo_coltypes,
         suppress_dynpro    TYPE c LENGTH 1,
         internet_prepare   TYPE c LENGTH 1,
         interface_complete TYPE c LENGTH 1,
         no_filter_confirm  TYPE c LENGTH 1,
         detail_only        TYPE c LENGTH 1,
         detail_exit        TYPE c LENGTH 1,
         s_variant          LIKE disvariant,
         weblook            TYPE c LENGTH 10,
         webstyle           TYPE x LENGTH 4,
         webrows            TYPE i,
         webxwidth          TYPE i,
         webxheight         TYPE i,
       END OF kkblo_incl_layout1.

TYPES BEGIN OF kkblo_layout.
        INCLUDE STRUCTURE alv_s_layo.
        INCLUDE STRUCTURE kkb_s_layo.
        INCLUDE STRUCTURE alv_s_prnt.
INCLUDE TYPE slis_layout_alv1.
INCLUDE TYPE slis_print_alv1.
INCLUDE TYPE kkblo_incl_layout1.
TYPES END OF kkblo_layout.