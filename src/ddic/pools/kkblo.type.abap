TYPE-POOL kkblo.

TYPES kkblo_selfield TYPE slis_selfield.

" kkblo_layout
" kkblo_t_event_exit
" kkblo_t_extab
" kkblo_t_filter


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