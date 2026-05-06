#---------------------------------------------------------------------------------------------#
# choice.py
#---------------------------------------------------------------------------------------------#
# Description:
'''
    Choice is an abstraction for the User's choice.
'''
import sys
import argparse
import subprocess

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
    def __init__(self):
        parser = argparse.ArgumentParser(description='Markdown to LaTeX.', add_help=True)

        ARGUMENT = get_arguments()
        
        for key in ['version']:
            parser.add_argument(
                *ARGUMENT[key]['flags'],
                **ARGUMENT[key]['params']
            )
        
        user_input = sys.argv[1:]
        if len(user_input) > MAX_NUMBEROF_INPUTS:
            parser.error(f'Too many arguments given (Max: {MAX_NUMBEROF_INPUTS}).')

        parsed_args = vars(parser.parse_args())
        self.update(parsed_args)
        
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
# If you don't use the binary, you may uncomment the below line.
c = Choice()
c.markdown_to_latex()
#latex_to_pdf()
#markdown_to_pdf()
# END

