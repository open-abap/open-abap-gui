TYPE-POOL vrm.

TYPES vrm_id TYPE c LENGTH 132.
TYPES vrm_key TYPE c LENGTH 80.
TYPES vrm_text TYPE c LENGTH 80.

TYPES: BEGIN OF vrm_value,
         key  TYPE vrm_key,
         text TYPE vrm_text,
       END OF vrm_value.

TYPES vrm_values TYPE STANDARD TABLE OF vrm_value WITH DEFAULT KEY.
