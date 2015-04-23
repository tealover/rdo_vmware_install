#!/bin/sh

tcpdump -i lo tcp and port 8774 -n -X -s 0 -w nova.cap
