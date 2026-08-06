import os
import sys
from pprint import pprint
import subprocess
from commands.command import Command

# this is done to keep track when debugging and allow dynamic testfiles later on
commands  = [
    ['git', 'ls-files', '--other'],
]

def stamps_bulk_read(add_newline=False):
    c = Command(commands[0])
    results = [c.replace('\"', '') for c in c.run() if c != '']
    
    cats = [Command(['cat', f'{file}']).run() for file in results ]

    if add_newline:
        newlines = [Command(['echo', '\n', '>>', f'{file}']).run() for file in results]

    pprint(cats)

if __name__ == '__main__':
    add_newline = True if len(sys.argv) > 1 else False

    stamps_bulk_read(add_newline)
