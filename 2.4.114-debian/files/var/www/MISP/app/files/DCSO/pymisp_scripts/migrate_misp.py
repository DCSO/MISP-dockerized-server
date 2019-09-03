#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
#   The target of the python script is to migrate events with the same local ID from one MISP to another MISP instance.
#   Status: Experimental
#

from pymisp import PyMISP
import argparse
import logging
import json
import requests
import os
import time
import datetime
# https://pyopenssl.org/en/stable/api/crypto.html#x509-objects
# http://www.yothenberg.com/validate-x509-certificate-in-python/
from OpenSSL import crypto
# Deactivate InsecureRequestWarnings
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

# Load keys
from keys import misp_old_url, misp_old_key, misp_old_verifycert, misp_new_url, misp_new_key, misp_new_verifycert


# Logging
#logging.getLogger('pymisp').setLevel(logging.DEBUG)
logging.basicConfig(level=logging.DEBUG, filename="debug.log", filemode='w+')

# For python2 & 3 compat, a bit dirty, but it seems to be the least bad one
try:
    input = raw_input
except NameError:
    pass

def init(url, key, misp_verifycert):
    #
    #   Initialize function
    #
    return PyMISP(url, key, misp_verifycert, 'json', debug=False)

def init_logging(args):
    """Initialize logging."""
    logging.basicConfig(
        level=logging.WARN,
        format="%(asctime)s | %(levelname)s | %(module)s.%(funcName)s.%(lineno)d | %(message)s"
    )
    logger = logging.getLogger()
    if args.debug == 1:
        logger.setLevel('WARN')
    elif args.debug == 2:
        logger.setLevel('INFO')
    elif args.debug >= 3:
        logger.setLevel('DEBUG')


def update_new_misp(misp_new):
    #
    # Update new Instance
    #
    print('Update Galaxies...')
    print(misp_new.update_galaxies())
    
    print('Update Object Templates...')
    print(json.dumps(misp_new.update_object_templates(),indent=4))

    print('Update Taxonomies...')
    print(misp_new.update_taxonomies())
    
    print('Update Warninglists...')
    print(misp_new.update_warninglists())
    
    # Wait for User
    input("Press Enter to continue...")

def migrate_taxonomies(misp_new, misp_old):
    #
    #   Add Taxonomies
    #
    print('Activate all Taxonomies on the new one which are activated on the old one...')
    all_taxonomies = misp_old.get_taxonomies_list()
    for TAXONOMY in all_taxonomies.get('response'):
        if ( TAXONOMY.get('Taxonomy').get('enabled') == True ):
             # Get out the current Taxonomy:
             print(TAXONOMY)
             # Activate Taxonomy on new MISP
             misp_new.enable_taxonomy(TAXONOMY.get('Taxonomy').get('id'))
    input("Press Enter to continue...")

def migrate_events(START_EVENT_ID,END_EVENT_ID, misp_new, misp_old, sql_handler):
    #
    #   Migrate Events from old to new Instance
    #
    print('Migrate events...')
    START_TIME = datetime.datetime.now().time()
    for EVENT_ID in range(START_EVENT_ID, END_EVENT_ID+1):
        tmp_event = misp_old.get_event(EVENT_ID)
        # if DEBUG is True:
        #     print(json.dumps(tmp_event, indent=4))
        # If event ID is not more used ignore it.
        if 'name' in tmp_event:
            if tmp_event['name'] == 'Invalid event':
                #print('tmp_EVENT EXCEPT')
                tmp_event = {
                    "info": "" 
                    }
                tmp_event['info'] = 'ToDELETE_'+str(EVENT_ID)
                print('Exception: add dummy event ToDELETE_'+str(EVENT_ID))
        
        # Add Events to new MISP
        NEW_EVENT = misp_new.add_event(tmp_event)
        
        if 'Event' in NEW_EVENT:
            print(str(START_TIME) + ': ' + str(EVENT_ID)+' / '+ str(END_EVENT_ID)+' events migrated...New ID: '+ NEW_EVENT['Event']['id'] + '...UUID: ' + NEW_EVENT['Event']['uuid'])
        
        if 'name' in NEW_EVENT:
            if NEW_EVENT['name'] == 'Event already exists, if you would like to edit it, use the url in the location header.':
                print(str(EVENT_ID)+' Event already exists')
                continue
            if NEW_EVENT['name'] == 'Could not add Event':
                print(str(EVENT_ID)+' Could not add Event.')
                print(NEW_EVENT)
                continue
            print(NEW_EVENT)
    

    print(str(datetime.datetime.now().time()) + ': Migrate events...finished')
    input("Press Enter to continue...")     

def migrate_roles(misp_new, misp_old):
    print ('Migrate roles...')
    # body = '{
    #     "name": "mandatory",
    #     "perm_delegate": "optional",
    #     "perm_sync": "optional",
    #     "perm_admin": "optional",
    #     "perm_audit": "optional",
    #     "perm_auth": "optional",
    #     "perm_site_admin": "optional",
    #     "perm_regexp_access": "optional",
    #     "perm_tagger": "optional",
    #     "perm_template": "optional",
    #     "perm_sharing_group": "optional",
    #     "perm_tag_editor": "optional",
    #     "default_role": "optional",
    #     "perm_sighting": "optional",
    #     "permission": "optional"
    # }'
    
    for element in misp_old.get_roles_list():
        tmp_role = element['Role']
        if tmp_role['id'] == '9':
            body = {
                "name": "to_delete"
            }
            roles_add(misp_new, body)
            continue

        del tmp_role['id']
        del tmp_role['created']
        del tmp_role['modified']
        del tmp_role['memory_limit']
        del tmp_role['max_execution_time']
        print (json.dumps(tmp_role['name'], indent=4))
        roles_add(misp_new, tmp_role)
    
    print ('Migrate roles...finished')
    input("Press Enter to continue...")     

def roles_add(misp_new, tmp_role):
    relative_path = '/admin/roles/add'
    misp_new.direct_call(relative_path, tmp_role)

def roles_edit(misp_new, tmp_role):
    relative_path = '/admin/roles/edit'
    misp_new.direct_call(relative_path, tmp_role)

def migrate_user(misp_new, misp_old):
    print('Migrate users...')

    CURRENT_ID=1
    for tmp_user in misp_old.get_users_list()['response']:
        print('### Current User:')
        print (json.dumps(tmp_user, indent=4))
        print()

        # Create skeleton
        body = {
            #"id": "",
            "email": "",
            "org_id": "",
            "role_id": "",
            "password": "StartStart123!",
            # "external_auth_required": "optional",
            # "external_auth_key": "optional",
            "enable_password": "true",
            "nids_sid": "",
            "server_id": "",
            "gpgkey": "",
            "certif_public": "",
            "autoalert": "",
            "contactalert": "",
            "disabled": "",
            "change_pw": "1",
            "termsaccepted": "",
            "newsread": ""
        }
        # Change vars to current user
        body['email'] = tmp_user['User']['email']
        body['org_id'] = tmp_user['User']['org_id']
        body['role_id'] = tmp_user['User']['role_id']
        body['nids_sid'] = tmp_user['User']['nids_sid']
        body['server_id'] = tmp_user['User']['server_id']
        body['gpgkey'] = tmp_user['User']['gpgkey']
        
        # Check first if cert is expired, if this is true then do not store the cert, else store the cert
        if 'User' in tmp_user:
            if tmp_user['User']['certif_public']:
                if not crypto.load_certificate(crypto.FILETYPE_PEM, tmp_user['User']['certif_public'] ).has_expired():
                    body['certif_public'] = tmp_user['User']['certif_public']
            else:
                print('For the user ' + tmp_user['User']['email'] + ', no cert is available')
        else:
            print(tmp_user)

        body['autoalert'] = tmp_user['User']['autoalert']
        body['contactalert'] = tmp_user['User']['contactalert']
        body['disabled'] = tmp_user['User']['disabled']
        body['termsaccepted'] = tmp_user['User']['termsaccepted']
        body['newsread'] = tmp_user['User']['newsread']

        FILE='tmp_misp_user.json'
        with open(FILE,"w") as f:
            print("############### WRITING FILE")
            #json.dump(body, f)
            print (json.dump(body, f, indent=4))
            print("############### WRITING FILE")

        print(' ')
        CURRENT_USER = misp_new.get_user(CURRENT_ID)
        print(CURRENT_USER)
        if 'name' in CURRENT_USER:
            if CURRENT_USER['name'] == 'Invalid user':
                print('### added new User')
                print(misp_new.add_user_json(FILE))
            else:
                print(CURRENT_USER)
        else:
            # 'name' not existing as key
            print('### edited existing User')
            print(misp_new.edit_user_json(FILE, CURRENT_ID))
        print(' ')

        # Add +1 to CURRENT_ID
        CURRENT_ID = CURRENT_ID+1
        print('######################################################################')

    print('Migrate users...finished')
    input("Press Enter to continue...")   



#####################################
###
###     MAIN
###
#####################################

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Migration and updater helperscript.')
    parser.add_argument("-u", "--update", help="[true|false] Update Taxonomies, Warninglist, Template Objects, Galaxies.")
    parser.add_argument("-m", "--migrate_events", help="[true|false] Migrate MISP events from one MISP to another. Attention! This method change the event_creator_email adress.")
    parser.add_argument("-mu", "--migrate_users", help="[true|false] Migrate MISP users from one MISP to another.")
    parser.add_argument("-mr", "--migrate_roles", help="[true|false] Migrate MISP users roles from one MISP to another.")
    parser.add_argument("-mesID", "--migrate_event_start_ID", type=int, help="Start Event ID greater than 1. Default 1")
    parser.add_argument("-meeID", "--migrate_event_end_ID", type=int, help="End Event ID greater than 1. No default, is required.")
    args = parser.parse_args()

    # Configure and Initialize MISP 
    misp_new = init(misp_new_url, misp_new_key, misp_new_verifycert)
    misp_old = init(misp_old_url, misp_old_key, misp_old_verifycert)

    print('############################## START ###################################')

    # # Update the new Instance
    if args.update != None:
        print ('Update new MISP instance...')
        update_new_misp(misp_new)

    # Migrate Roles
    if args.migrate_roles != None:
        migrate_roles(misp_new, misp_old)

    # Migrate Users
    if args.migrate_users != None:
        migrate_user(misp_new, misp_old)

    # Migrate Events
    if args.migrate_events != None:
        # Check if migrate-event-start-id is available
        if args.migrate_event_start_ID == None:
            START_EVENT_ID = 1
        elif args.migrate_event_start_ID < 1:
            print('Please only numbers greater than 1')
            exit(1)
        else:
            START_EVENT_ID = args.migrate_event_start_ID
        
        # Check if migrate-event-end-ID is available
        if args.migrate_event_end_ID == None:
            print('Error no migrate-event-end-ID as parameter. Please set this first.')
            exit(1)
        else:
            END_EVENT_ID = args.migrate_event_end_ID

        # start Event Migration
        migrate_events(START_EVENT_ID,END_EVENT_ID,misp_new,misp_old, None)
