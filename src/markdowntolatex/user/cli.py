#-----------------------------------------------------------------------------#
# cli.py                                                                      #
#-----------------------------------------------------------------------------#
# Description
'''
    Command line interface definition. 
    A dictionary **ARGUMENT** stores arguments definitions. 
'''
from markdowntolatex.constants import DEFAULT_PREFERENCES


MAX_NUMBEROF_INPUTS = 3 
'''
    The maximal number of input strings we expect from the user: 
    Two arguments (help, preferences), one value (for preferences). 3, then
'''

ARGUMENT  = {
    'help': {
        'flags': ['-h', '--help'], # Don't use
        'parameters for CLI':{
            'dest': 'help',
            'nargs': '?',
            'help': 
            ''''
                MarkdownToLaTeX 
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
            'help': 'Package version, following the usual “major.minor.micro” scheme (1.1.1, 1.2.3, 3.2.1, and so on).'
        }
    },
    'preferences': {
        'flags': ['-p', '--preferences'], 
        'parameters for CLI':{
            'nargs':'?', 
            'dest': 'preferences', 
            'const': DEFAULT_PREFERENCES, 
            'default': DEFAULT_PREFERENCES, # If 'preferences' not present.
            'metavar': 'JSON file',
            'help': '''
                Path to the JSON file that stores your preferences. 
                Default is set to \'preferences/preferences.json\' .'''
        }
    }
}
# END
