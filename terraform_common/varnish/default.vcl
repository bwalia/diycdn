# This is the default VCL file for Varnish.
vcl 4.1;

import std;

# We have to have a backend, even if we do not use it

backend default_backend {
    .host = "localhost";
    .port = "80";
}
sub vcl_recv {
return (synth(503));
}
