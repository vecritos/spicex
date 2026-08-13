import sys


def remove_duplicates(filename='', target='export.txt'):
    if len(filename) == 0:
        print('no file name given')
        return
    
    file = open(filename, 'r')

    lines = []
    for line in file:
        if line in lines:
            continue
        lines.append(line)
    
    file = open(target, 'w')
    
    file.writelines(lines)
    file.close()


if __name__ == "__main__":
    remove_duplicates(sys.argv[1], sys.argv[2])
        