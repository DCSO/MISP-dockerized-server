#!/usr/bin/env python
# -*- coding: utf-8 -*-

#
#   The target of the python script is to start an cron job for MISP
#   Status: Experimental
#


from pymisp import PyMISP
from keys import misp_old_url, misp_old_key, misp_old_verifycert, misp_new_url, misp_new_key, misp_new_verifycert
import argparse
import logging
import json
import requests

# Deactivate InsecureRequestWarnings
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)


# Logging
#logging.getLogger('pymisp').setLevel(logging.DEBUG)

# For python2 & 3 compat, a bit dirty, but it seems to be the least bad one
try:
    input = raw_input
except NameError:
    pass


#
#   Initialize function
#
def init():
    misp_new_url = 'https://misp-proxy/'
    misp_new_key = 'sAwfM2mNQBVgKOSe2yI1AQISuP2IvskQcSQZbiso' # The MISP auth key can be found on the MISP web interface under the automation section
    misp_new_verifycert = False
    return PyMISP(url, key, misp_verifycert, 'json', debug=False)


  

if __name__ == '__main__':

    # Configure and Initialize MISP 
    misp_instance = init()
    print('############################## START ###################################')

    print('pull all server...')
    misp_instance.server_pull
    print('push all server...')
    misp_instance.server_push
    print('cache all feeds...')
    misp_instance.cache_feeds_all()
    misp_instance.cache_all_feeds
    
