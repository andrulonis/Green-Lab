#!/bin/bash

scontrol show job $1 | sed -n -e 's/^ *JobState=\([A-Z]*\).*$/\1/p'
