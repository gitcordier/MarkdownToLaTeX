#-----------------------------------------------------------------------------#
# choice.py
#-----------------------------------------------------------------------------#
# Description:
'''
    Choice is an abstraction for the User's choice.
'''
import sys
import argparse

from markdowntolatex.constants import NAME, VERSION
from markdowntolatex.utilities import *
from markdowntolatex.latex.document import Document
from markdowntolatex.user.cli import *

def markdown_to_latex():
    '''
        Performs the whole "markdown to LaTex" process. 
        
        When the binary is run, this method is called hunder the hood.
    '''
    Choice().markdown_to_latex()
#
class Choice(dict):
    '''
        User's inputs are collected then recorded into a dictionary, 
        which is the **Choice** instance itself.
    '''
    def __init__(self):
        # Let's instantiate the parser:
        parser = argparse.ArgumentParser(description='Markdown to LaTeX.')
        
        # Custom help option
        parser.add_argument(
            **ARGUMENT['help']['parameters for CLI']
        )
        # Version
        parser.add_argument(
            *ARGUMENT['version']['flags'],
            **ARGUMENT['version']['parameters for CLI']
        )
        
        # Add option for preferences
        parser.add_argument(
            *ARGUMENT['preferences']['flags'], 
            **ARGUMENT['preferences']['parameters for CLI']
        )
        
        # We check for redundancies among inputs: ----------------------------#
        user_input = sys.argv[1:]
        
        # Exit criterion: Too many arguments
        try:
            assert len(user_input) <= MAX_NUMBEROF_INPUTS
        except AssertionError:
            raise ValueError('Too many arguments were given.')
        # Check for redundancies among inputs: END ---------------------------#
        
        # Collect all parsed inputs: 
        self.update(vars(parser.parse_args()))
        
        # Default for preferences: Let us allow the special word “none”:
        if self['preferences'].lower() == 'none':
            self['preferences'] = DEFAULT_PREFERENCES
        #
    # Init: END 
    def markdown_to_latex(self):
        if self['version'] == False:
            preferences = self['preferences']
            document = Document(preferences)
            dictionary = document.parse_markdown().get_latex()
            print('LaTeX code was created in folder %s .'%dictionary['folder'])
        else:
            print("%s's current version is %s."%(NAME, VERSION))
            return
        #
        print('From markdown to LaTex: Done!')
    #
# Choice: END

# If you don't use the binary, uncomment the below line.
#markdown_to_latex()
# END

