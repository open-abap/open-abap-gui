* Types, data and field symbols of ZGG_EX_209.

TYPES: BEGIN OF ty_player,
         name   TYPE string,
         points TYPE i,
       END OF ty_player.
TYPES ty_players TYPE STANDARD TABLE OF ty_player WITH DEFAULT KEY.

TYPES: BEGIN OF ty_code,
         country TYPE c LENGTH 2,
         number  TYPE c LENGTH 4,
       END OF ty_code.

DATA gt_players TYPE ty_players.
DATA gv_code TYPE c LENGTH 6 VALUE 'DK1234'.

FIELD-SYMBOLS <gs_player> TYPE ty_player.
FIELD-SYMBOLS <gv_field>.
