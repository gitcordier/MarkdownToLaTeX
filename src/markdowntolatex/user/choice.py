#---------------------------------------------------------------------------------------------#
# choice.py
#---------------------------------------------------------------------------------------------#
# Description:
'''
    Choice is an abstraction for the User's choice.
'''
import sys
import json
import argparse
import subprocess
from pathlib import Path
from cli import CLI

#from markdowntolatex.constants import NAME, VERSION
#from markdowntolatex.utilities import get_file
from markdowntolatex.user.cli import *
#from markdowntolatex.latex.document import Document

NAME = "TOTO"
VERSION = "1.0"

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
    #s = get_file('xelatex_to_pdf_rough.sh', 'script', mode='rb')
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
    # The maximal number of input strings we expect from the user: 
    #    Two arguments (help, preferences), one value (for preferences). 
    #    Three, then
    MAX_NUMBEROF_INPUTS = 3 

    def __init__(self):        
        if len(sys.argv[1:]) > Choice.MAX_NUMBEROF_INPUTS:
            parser.error(f'Too many arguments given (Max: {Choice.MAX_NUMBEROF_INPUTS}).')
        else:
            parser = argparse.ArgumentParser(description='Markdown to LaTeX.', add_help=True)
            [parser.add_argument(*CLI[k]['flags'], **CLI[k]['params']) for k in ['version']]
            
            self.update(vars(parser.parse_args()))
            self['path']= Path.cwd()
        #
    # END of __init__
       
    def markdown_to_latex(self):
        print(self)
        if self['version'] == False:
            pass
            #preferences = self['preferences']
            #document = Document(preferences)
            #self.update(document.parse_markdown().get_latex())
            #print('LaTeX code was created in folder %s .'%self['folder'])
        else:
            print("%s's current version is %s."%(NAME, VERSION))
        #
        return self
    #
    def xelatex_to_pdf(self):
        if self['version'] == False:
            pass
            #name   = self['name'].encode('utf-8')
            #folder = self['folder'].encode('utf-8')
            #s = get_file('xelatex_to_pdf','script', mode='rb')%(name,folder)
            #subprocess.run(s, shell=True)
        else:
            print('MarkdownToLaTex: End.')
    # Choice: END 
# END

