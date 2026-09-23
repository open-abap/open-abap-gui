INTERFACE zif_gg_host_environment_v1 PUBLIC.

* Process-wide state an application needs before its programs run, such as
* database fixtures. The HTTP handler discovers every implementation, calls
* setup once before the first program starts and teardown on shutdown, so the
* host never names application classes. Implementations need a public
* constructor without mandatory parameters.

  METHODS setup.

  METHODS teardown.

ENDINTERFACE.
