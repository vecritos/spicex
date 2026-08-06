import os
import sys

quit_phrase = 'q'
skip_phrase = 's'

# works for lines formatted as "00000000000000 summary of timestamp"
def get_explanation(line):
    words = line.split()    
    timestamp = words[0]
    print(line)
    
    lines = []
    explanation = ''
    
    while explanation != quit_phrase and explanation != skip_phrase:
        explanation = input('? ')
        
        if explanation != quit_phrase and explanation != skip_phrase:
            lines.append(explanation)

    if explanation != skip_phrase:
        lines.append(f'\n\n-|{timestamp}\n')
    
        file = open(f'{timestamp}.txt', 'w')
        file.writelines(lines)
        file.close()   

def get_file_explanation(filename):
    file = open(filename, 'r')
    for line in file:
        get_explanation(line)


if __name__ == '__main__':
    print(f'type "{quit_phrase}" to quit writing about this timestamp\
        type "{skip_phrase}" to ignore the entry and move to next')

    get_file_explanation(sys.argv[1])
