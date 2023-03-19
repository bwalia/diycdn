#!/bin/bash

set -x
#/usr/local/openresty/bin/openresty -t && 
systemctl restart varnish.service
