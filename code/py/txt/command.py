import subprocess

'''run subprocess, capture result, undo is not currently supported'''
class Command:
    def __init__(self, command):
        self.command = command
        self.result = []
        pass

    
    def run(self, quiet=True):
        result = subprocess.run(self.command, capture_output=True, text=True)

        splits = lambda x: [l.strip() for l in x.split('\n')]

        if result.returncode == 0:
            self.result = splits(result.stdout)
        else:
            self.result = splits(result.stderr)

        if not quiet:
            output ='result' if result.returncode == 0 else 'error' 
            print((
                f'{output}'
                f'{self.result}'
            ))

        return self.result


