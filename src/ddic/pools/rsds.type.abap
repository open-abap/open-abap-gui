TYPE-POOL rsds.

* Ranges format, one RANGES table per field of a node
TYPES rsds_selopt_t TYPE STANDARD TABLE OF rsdsselopt WITH DEFAULT KEY.

TYPES: BEGIN OF rsds_frange,
         fieldname TYPE c LENGTH 30,
         selopt_t  TYPE rsds_selopt_t,
       END OF rsds_frange.
TYPES rsds_frange_t TYPE STANDARD TABLE OF rsds_frange WITH DEFAULT KEY.

TYPES: BEGIN OF rsds_range,
         tablename TYPE c LENGTH 30,
         frange_t  TYPE rsds_frange_t,
       END OF rsds_range.
TYPES rsds_trange TYPE STANDARD TABLE OF rsds_range WITH DEFAULT KEY.

* WHERE clause format, directly usable in a dynamic WHERE condition
TYPES rsds_where_tab TYPE STANDARD TABLE OF rsdswhere WITH DEFAULT KEY.

TYPES: BEGIN OF rsds_where,
         tablename TYPE c LENGTH 30,
         where_tab TYPE rsds_where_tab,
       END OF rsds_where.
TYPES rsds_twhere TYPE STANDARD TABLE OF rsds_where WITH DEFAULT KEY.

* Internal format, reverse Polish notation
TYPES rsds_expr_tab TYPE STANDARD TABLE OF rsdsexpr WITH DEFAULT KEY.

TYPES: BEGIN OF rsds_expr,
         tablename TYPE c LENGTH 30,
         expr_tab  TYPE rsds_expr_tab,
       END OF rsds_expr.
TYPES rsds_texpr TYPE STANDARD TABLE OF rsds_expr WITH DEFAULT KEY.

* Type of the DYN_SEL parameter of a logical database
TYPES: BEGIN OF rsds_type,
         clauses TYPE rsds_twhere,
         texpr   TYPE rsds_texpr,
         trange  TYPE rsds_trange,
       END OF rsds_type.
