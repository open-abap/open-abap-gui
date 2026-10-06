# Open items

## Transpiler

- Program `AT USER-COMMAND` blocks are compiled (they throw at runtime) while
  `AT LINE-SELECTION` and `AT SELECTION-SCREEN` blocks are dropped;
  `MODIFY LINE` is not supported, so a program with `MODIFY LINE` in
  `AT USER-COMMAND` fails to transpile.
- `CLEANUP` blocks are ignored.
- `line_exists( io_session->get_status( )-exit_ucomm[ table_line = x ] )`, a
  table expression on a method call's result, is translated wrongly: the
  program ended.