#-----------------------------------------------------------------------------#
# cli.py                                                                      #
#-----------------------------------------------------------------------------#
# Description
'''
    Command line interface definition. 
    A dictionary **ARGUMENT** stores all arguments definitions. 
'''
from markdowntolatex.constants import DEFAULT_PATH_FOR_PREFERENCES


MAX_NUMBEROF_INPUTS = 3 
'''
    The maximal number of input strings we expect from the user: 
    Two arguments (help, preferences), one value (for preferences). 
    Three, then
'''

ARGUMENT = {
    'help': {
        'flags': ['-h', '--help'], # Don't use
        'parameters for CLI':{
            'dest': 'help',
            'nargs': '?',
            'help': 
                '''
                    MarkdownToLaTeX help
                '''
        }
    },
    'version': {
        'flags': ['-v', '--version'], 
        'parameters for CLI':{
            'dest': 'version',
            'nargs': '?',
            'const': True,
            'default': False, # If 'version' not present.
            'help': 
                '''
                    Package version, following the usual 
                    “major.minor.micro” scheme 
                    (1.1.1, 1.2.3, 3.2.1, and so on).
                '''
        }
    },
    'preferences': {
        'flags': ['-p', '--preferences'], 
        'parameters for CLI':{
            'nargs':'?', 
            'dest': 'preferences', 
            'const': DEFAULT_PATH_FOR_PREFERENCES, 
            'default': DEFAULT_PATH_FOR_PREFERENCES, # If no 'preferences'
            'metavar': 'JSON file',
            'help': 
                '''
                    Path to the JSON file that stores your preferences. 
                    
                    Default is set to 'preferences/preferences.json'.
                '''
        }
    }
}
'''
    The dictionary **ARGUMENT** stores all arguments definitions. 
'''
# END
