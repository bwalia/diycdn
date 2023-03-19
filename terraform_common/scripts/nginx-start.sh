#!/bin/bash

set -x

/usr/local/openresty/bin/openresty -t && systemctl start openresty.service
