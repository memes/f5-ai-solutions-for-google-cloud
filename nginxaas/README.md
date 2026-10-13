# NGINXaaS configuration files

These files can be uploaded or copy and pasted into an NGINXaaS configuration. The TLS certificate bundle will be
sourced from existing Google Secret Manager secret.

Differences from NGINXaaS starting config:

## [nginx.conf](nginx.conf)

* Added `gw` upstream which resolves to NGF or GKE Inference Gateway deployment
* Added SSL certificate directives to combined certificate and key PEM

## [default.conf](conf.d/default.conf)

* HTTP to HTTPS redirect

## [f5-ai.conf](conf.d/f5-ai.conf)

* Proxy requests to F5 AI console deployed to upstream cluster(s)

## `welcome.conf` - deleted
