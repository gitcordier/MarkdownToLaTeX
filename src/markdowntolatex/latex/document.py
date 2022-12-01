#-----------------------------------------------------------------------------#
# document.py                                                                 #
# Abstraction for document.                                                   #
#-----------------------------------------------------------------------------#
import json
import shlex
import shutil 
import subprocess

from markdowntolatex.constants import NAME
from markdowntolatex.utilities import *
from markdowntolatex.markdown.encoding import *
from markdowntolatex.markdown.parser import *
from markdowntolatex.markdown.tree import *
from markdowntolatex.utilities import *

class Document():
    '''
        Abstraction for document.

        :param preferences: a path to a *preferences* file. 
        :type: str
        :raise: FileNotFoundError if the path is not valid.
        :raise: JSONDecodeError if the data being deserialized is not a valid JSON document.
    '''
    def __init__(self, preferences):
        '''
            Instantiates the (**Document**) document *self*. 

            :param preferences: a path to a *preferences* file. 
            :type: str
            :raise: FileNotFoundError if the path is not valid.
            :raise: JSONDecodeError if the data being deserialized is not a valid JSON document.
        '''
        # self.current_folder ------------------------------------------------#
        # The current folder is identified with a path string
        # Such string is the one that is returned by the bash command 'pwd'. 
        pwd = subprocess.run('pwd', capture_output=True).stdout
        pwd = pwd.decode('utf-8').replace('\n', '')
        self.current_folder = pwd
        # self.currentfolder: END --------------------------------------------#
        #
        # self.preferences ---------------------------------------------------#
        self.preferences = preferences
        #
        try:
            with open(self.preferences, 'r') as f:
                try:
                    self.preferences = json.load(f)
                except json.JSONDecodeError as e:
                    raise e
                #
            #
        except FileNotFoundError as e:
            e.errno ='No preferences file, e.g. "preferences.json", was found.'
            raise e
        # self.preferences: END ----------------------------------------------#
        #
        # Markdown: Getting the markdown source file -------------------------#
        markdown_folder = os.path.join(self.current_folder, 'input/markdown/')
        markdown_files = [e for e in os.listdir(markdown_folder) 
            if os.path.isfile(os.path.join(markdown_folder, e)) and 
                # The extension must be '.md'. 
                # To see this, We read the string from right tp left:
                e[::-1][:len('.md')] == '.md'[::-1]
        ]
        
        # Markdown_file MUST contain exactly one markdown file. 
        # If more than one markdown file, or no markdown file at all, 
        # A ValueError is raised.
        try:
            assert(len(markdown_files) > 0)
        except AssertionError as e:
            raise ValueError("Folder input/markdown contains no markdown file.")
        try:
            assert len(markdown_files) == 1
        except AssertionError as e:
            raise ValueError("Folder input/markdown contains more than one markdown file.")
        #
        input_markdown = markdown_files[0]
        self.input_markdown = os.path.join(markdown_folder, input_markdown)
        with open(self.input_markdown, 'rb') as f:
            self.input_string = f.read()
        #
        # Markdown: Getting the markdown source file END ---------------------#
        #
        # Tree does not exist yet:
        self.tree = None
    #
    def parse_markdown(self):
        '''
            Parses the document.
        '''
        parser = Parser()
        
        for e in self.input_string:
            if e == CR:
                raise ValueError(
                    '''
                        Carriage return character (CR) was found!
                        
                        Go to your text editor settings then switch from Windows line ending (CRLF) 
                        to Unix line ending (LF). 

                        Similarly (kind reminder), set the characted encoding to 'UTF-8' if you have not done it yet. 
                        %s may not work with other encodings (e.g. Windows 1252, ISO latin).
                    '''%NAME
                )
            parser.interpret(e)
        # Now the document self is being given the parser's tree:
        self.tree = parser.tree
        # For chained calls:
        return self

    def get_latex(self):
        '''
            From Markdown to LaTeX.

            Creates the latex code after the parsing is done.

            Formally speaking, this is a getter, since a ditionary 
            dict {'folder', 'document'} is returned. 

            :return: A dictionary dict{folder, document}.
            :rtype: dict
        '''
        ## Clean up 
        root = os.path.join(self.current_folder, 'output/')
        shutil.rmtree(root, ignore_errors=True)
        try:
            os.mkdir(root)
        except FileExistsError:
            pass
        root = os.path.join(root, 'xelatex/')
        try: 
            os.mkdir(root)
        except FileExistsError:
            pass
        return self.__private__get_latex_recursively(folder=root, index = 1)
    #
    # Return folder, document 
    def __private__get_latex_recursively(self, folder='', index=1, tree=None):
        '''
            Recursicely records the LateX code source. 

            Formally speaking, this is a getter, since the returned value is a dictionary 
            dict{folder, document}.

            :param folder: the base folder; see https://docs.python.org/3.11/library/os.path.html
            :param index: heading number, e.g section 1, section 2, ...
            :param tree: The tree from which the LaTeX code is made.
            :type folder: posixpath, ntpath
            :type index: int
            :type tree: Tree
            :return: A dictionary dict{folder, document}.
            :rtype: dict
        '''
        def latex_heading_and_input(folder, index, subtree):
            '''
                Returns the heading and the latex input, as a string.
            '''
            latex_heading = ''.join((
                '\\',subtree.to_string('level'),
                '{', subtree.to_string('heading'), '}'))

            # ----- Recursion is here: ------------------------#
            dictionary = self.__private__get_latex_recursively(folder, index, subtree)
            # -------------------------------------------------#
            latex_input = '{}{}'.format(*dictionary.values())
            return ''.join((latex_heading, '\n', '\input{', latex_input, '}'))
        #
        if tree == None:
            #shutil.rmtree(folder, ignore_errors=True)
            tree = self.tree
            title = tree.to_string('heading')
            document = 'mainmatter.tex'
            DM = get_file('DM.tex','input/xelatex', mode='r')
            DM = DM.replace('TITLE IS DEFINED HERE', title)
            DM = DM.replace('ROOT IS DEFINED HERE', os.path.abspath(folder))
            #
            #shutil.rmtree(root, ignore_errors=True)
            #os.mkdir(root)
            with open(os.path.join(folder, 'DM.tex'), 'w') as f:
                f.write(DM)
            #
        elif tree.level > 1:
            nameof_file = tree.to_string('heading', whitespaces=False)
            folder = ''.join((
                folder, 
                tree.to_string('level'),
                str(index+1), 
                '_',
                nameof_file,
                '/'
            ))
            document = nameof_file + '.tex'

            try:
                os.mkdir(folder)
            except OSError:
                pass
        #
        text = tree.to_string('text')
        if text == '':
            content = []
        else:
            content = [text]
        #
        if tree.branches != []:
            content.extend ((
                # - Recursion lies here, see atex_heading_and_input - #
                latex_heading_and_input(folder, index, subtree)
                # ----------------------------------------------------#
                for index, subtree in enumerate(tree.branches)
            ))
        #
        with open(folder + document, 'w') as f:
            f.write('\n'.join(content))
        #
        return dict(folder=folder, document=document)
    #
    def __private__DEBUGdisplay(self):
        print('last read: %s, last state: %s, current level: %d, hash: %d, tree: \n%s'%(
                chr(self.read),
                self.state, 
                self.level, 
                self.count['hash'], 
                self.tree.__private__DEBUG_to_string()
        ))
    #
# END

