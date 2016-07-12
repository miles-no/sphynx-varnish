vcl 4.0;

backend sphynx {
  .host = "127.0.0.1";
  .port = "3000";
}

backend modules {
  .host = "127.0.0.1";
  .port = "3001";
}

sub vcl_recv {
  if (req.http.host ~ "(?i)^localhost:5000$") {
    set req.http.host = "127.0.0.1:3000";
    set req.backend_hint = sphynx;
  } elsif (req.http.host ~ "(?i)^localhost:3001$") {
    set req.http.host = "127.0.0.1:3001";
    set req.backend_hint = modules;
  } else {
    return (synth(404, req.http.host));
  }
  # Send Surrogate-Capability headers to announce ESI support to backend
  set req.http.Surrogate-Capability = "key=ESI/1.0";

  # Do not cach anything
  set req.hash_always_miss = true;
}

sub vcl_backend_fetch {

}

sub vcl_backend_response {
# Enable ESI processing
  if (beresp.http.Surrogate-Control ~ "ESI/1.0") {
    unset beresp.http.Surrogate-Control;
    set beresp.do_esi = true;
    set beresp.ttl = 0s;
  }
}
