#!/bin/sh

results=`grep -B 1 "def " "intertwine.py" | grep -A 1 "@app.route"`
echo -n "$results"
