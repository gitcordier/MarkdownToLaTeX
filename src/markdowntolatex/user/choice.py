#-----------------------------------------------------------------------------#
# choice.py
#-----------------------------------------------------------------------------#
# Description:
'''
    Choice is an abstraction for the User's choice.
'''
import sys
import argparse
import subprocess

from markdowntolatex.constants import NAME, VERSION
from markdowntolatex.utilities import get_file
from markdowntolatex.user.cli import *
from markdowntolatex.latex.document import Document


def markdown_to_latex():
    '''
        Performs the whole "markdown to LaTex" process. 
        
        When the binary is run, this method is called hunder the hood.
    '''
    Choice().markdown_to_latex()
#
def latex_to_pdf():
    '''
        Performs the whole "LaTex to PDF" process. 
        
        When the binary is run, this method is called hunder the hood.
    '''
    s = get_file('xelatex_to_pdf_rough.sh', 'script', mode='rb')
    subprocess.run(s, shell=True)
#

def markdown_to_pdf():
    '''
        Performs the whole "Markdown to PDF" process. 
        
        When the binary is run, this method is called hunder the hood.
    '''
    Choice().markdown_to_latex().xelatex_to_pdf()
#
class Choice(dict):
    '''
        User's inputs are collected then recorded into a dictionary, 
        which is the **Choice** instance itself.
    '''
    def __init__(self):
        # Let's instantiate the parser: --------------------------------------#
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
        
        # We check for redundancies among inputs:
        user_input = sys.argv[1:]
        
        # Exit criterion: Too many arguments
        try:
            assert len(user_input) <= MAX_NUMBEROF_INPUTS
        except AssertionError:
            raise ValueError('Too many arguments were given.')
        #

        # Collect all parsed inputs: 
        self.update(vars(parser.parse_args()))
        
        # Default for preferences: Let us allow the special word “none”:
        if self['preferences'].lower() == 'none': 
            self['preferences'] = None
        #
    # Init: END --------------------------------------------------------------#
    def markdown_to_latex(self):
        print(self)
        if self['version'] == False:
            preferences = self['preferences']
            document = Document(preferences)
            self.update(document.parse_markdown().get_latex())
            print('LaTeX code was created in folder %s .'%self['folder'])
        else:
            print("%s's current version is %s."%(NAME, VERSION))
        #
        return self
    #
    def xelatex_to_pdf(self):
        if self['version'] == False:
            name   = self['name'].encode('utf-8')
            folder = self['folder'].encode('utf-8')
            s = get_file('xelatex_to_pdf','script', mode='rb')%(name,folder)
            subprocess.run(s, shell=True)
        else:
            print('MarkdownToLaTex: End.')
    # Choice: END
# If you don't use the binary, you may uncomment the below line.
#markdown_to_latex()
#latex_to_pdf()
#markdown_to_pdf()
# END

