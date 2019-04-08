#!/bin/bash

base=$1
local=$2
remote=$3
merged=$4

if [ -r $base ];then
    emacsclient -a "" -c -n --eval "(require 'ediff)" --eval "(ediff-merge-with-ancestor \"$local\" \"$remote\" \"$base\" nil \"$merged\")"
else
    emacsclient -a "" -c -n --eval "(require 'ediff)" --eval "(ediff-merge \"$local\" \"$remote\" nil \"$merged\")"
fi