#!/bin/bash
while true; do echo bye | nc -l 7777; done &
disown
