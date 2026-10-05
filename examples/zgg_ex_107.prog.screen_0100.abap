PROCESS BEFORE OUTPUT.
  MODULE status_0100.
  LOOP AT gt_flights INTO gs_flight WITH CONTROL tc_flights
    CURSOR tc_flights-current_line.
  ENDLOOP.

PROCESS AFTER INPUT.
  MODULE exit_0100 AT EXIT-COMMAND.
  LOOP AT gt_flights.
  ENDLOOP.
  MODULE user_command_0100.
