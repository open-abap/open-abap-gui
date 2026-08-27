INTERFACE if_alv_message PUBLIC.

  METHODS get_message
    RETURNING
      VALUE(r_s_msg) TYPE bal_s_msg.

ENDINTERFACE.
