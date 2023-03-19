#!/bin/bash

find="0.0.0.0"
replace='"2.2.2.2"'
sed -i "s/$find/$replace/g" test.json