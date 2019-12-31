#!/usr/bin/python3
#
# Given a magnet link, send to Transmission via its RPC protocol.
#
# Uses requests
# http://docs.python-requests.org/en/latest/
#


# Dependencies
import sys
import requests
from json import dumps
from sys import argv, exit
from urllib.parse import unquote


# Settings
url = 'http://naseron:9092/transmission/rpc'
username = ''
password = ''


# Functions

# Get RPC Session ID
def get_session_id():
    sessionid_request = requests.get(url, auth=(username, password), verify=False)
    return sessionid_request.headers['x-transmission-session-id']

# Post Magnet Link
def post_link(magnetlink, names, trackers):
    sessionid = get_session_id()
    if sessionid:
        headers = {"X-Transmission-Session-Id": sessionid}
        body = dumps({"method": "torrent-add", "arguments": {"filename": magnetlink}})
        post_request = requests.post(url, data=body, headers=headers, auth=(username, password), verify=False)
        if str(post_request.text).find("success") == -1:
            sys.stderr.write(f'{argv[0]} ERROR: {post_request.text.rstrip()}; {magnetlink}\n')          
        else:
            all_names = ', '.join(names)
            all_trackers = ', '.join(trackers)
            sys.stderr.write(f'{argv[0]} SUCCESS: Names={all_names}; Trackers={all_trackers}\n') 

# End of Functions

# Main prog
if __name__ == '__main__':

    if len(argv) < 2:
        sys.stderr.write(f'Usage: {argv[0]} [magnet_url]\n')
        exit(1)
        
    if not argv[1].startswith('magnet'):
        sys.stderr.write(f'This is not a magnet url: {argv[0]}\n')
        exit(1)

    names = []
    trackers = []
    for item in argv[1].split('&'):
        decoded = unquote(item)
        if decoded.startswith('dn='):
            names.append(decoded.replace('dn=', ''))
        if decoded.startswith('tr='):
            trackers.append(decoded.replace('tr=', ''))
    
    post_link(argv[1], names, trackers)
