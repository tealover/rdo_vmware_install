#!/usr/bin/env python

import sys
import re
import json

def main():
    print "Parser starting"

    reHttpRequest = re.compile(".*HTTP\/1.1", re.X)
    reHttpResponse = re.compile("^\{.*}", re.X)

    while True:
        x = sys.stdin.readline()
        if len(x) == 0:
	    break
        x = x.strip('\n')

        matchRequest = re.match(reHttpRequest, x)
        matchResponse = re.match(reHttpResponse, x)
        if matchRequest:
            print "Request: %s" % x
        elif matchResponse:
            matched = matchResponse.group()
            print "Response: %s" % json.dumps(json.loads(matched), indent=4, sort_keys=True)
#        else:
#            print "Unmatched input: %s" % x

main()
