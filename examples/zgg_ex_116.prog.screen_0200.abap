PROCESS BEFORE OUTPUT.
  MODULE status_0200.
  LOOP AT gt_shown INTO gs_flight WITH CONTROL tc_flights
    CURSOR tc_flights-current_line.
  ENDLOOP.

PROCESS AFTER INPUT.
  MODULE exit_0200 AT EXIT-COMMAND.
  LOOP AT gt_shown.
    MODULE modify_flight.
  ENDLOOP.
  MODULE user_command_0200.
