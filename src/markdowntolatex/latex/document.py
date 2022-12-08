#-----------------------------------------------------------------------------#
# document.py                                                                 #
# Abstraction for document.                                                   #
#-----------------------------------------------------------------------------#
import json
import shlex
import shutil 
import subprocess

from markdowntolatex.constants import *
from markdowntolatex.utilities import *
from markdowntolatex.markdown.encoding import *
from markdowntolatex.markdown.parser import *
from markdowntolatex.markdown.tree import *


class Document():
    '''
        Abstraction for document.

        **user_preferences** is a path to a JSON preferences file. 

        :param user_preferences: A path to a *preferences* file. 
        :type: str
        :raise: FileNotFoundError if the path is not valid.
        :raise: JSONDecodeError if the preferences file being 
            deserialized is not a valid JSON document.
    '''
    def get_markdownn(self, arg):
        print(arg)

            #
        #
    def __init__(self, user_preferences=None):
        
        # Nested functions ---------------------------------------------------#
        def is_preferences_file(path):
            # Criterion: To be a JSON file: 
            return os.path.isfile(path) and path[-5:] == '.json'
        #
        def get_name(keyword=None, path=None):
            '''
                Returns the name of a file, given either the abspath or 
                an explanatory keyword, e.g 'preferences file.
            '''
            if keyword == 'preferences file' and path == None:
                abspath = self.preferences_file
            elif keyword == None and path != None:
                abspath = os.path.abspath(path)
            else:
                message = 'get_name could not get file name from arguments \
                    keyword=%s, path=%s.'%(str(keyword), str(path))
                raise FileNotFoundError(message)
            #
            if os.path.isfile(abspath):
                return os.path.split(abspath)[1]
            else:
                raise FileNotFoundError('No file at %s.'%abspath)
            #
        #
        def get_path(keyword, *suffix):
            '''
                Returns an absolute path, given 
                
                - An explanatory keyword, e.g. 'preferences', 
                    for the base path;
                
                - A suffix to append to the base path.
            '''
            pathof_folder = get_folder(keyword)
            return os.path.join(pathof_folder, *suffix)
        #
        def get_folder(arg):
            '''
                Returns absolute path of folder arg.
                arg may be: '.', 'markdown', 'xelatex', 'preferences'.
            '''
            folder = [self.folder]
            if arg in {'.', None}: pass
            elif arg in {'preferences', 'input', 'output'}: folder.append(arg)
            elif arg =='markdown': folder.extend(('input', 'markdown'))
            elif arg == 'xelatex': folder.extend(('output', 'xelatex'))
            else: folder.add(arg)
            return os.path.join(*folder)
        #
        def set_preferences_file(preferences_file=None):
            '''
                Write a preferences file in preferences folder, if necessary.
                self.preferences_file is assigned the absolute path of the 
                actual preferences file.
            '''
            if preferences_file in {None, ''}:
                # No preferences file: So we load the default file:
                origin  = ''
                name    = 'preferences.json'
                content = get_file('preferences.json', 'preferences')
            else: 
                # import content at 'preferences_file'
                origin  = os.path.abspath(preferences_file)
                name    = get_name(path=origin)
                content = open(origin,'rb').read()
            destination = get_path('preferences', name)
            if destination != origin:
                open(destination, 'wb').write(content)
            #
            self.preferences_file = get_path('preferences', name)
        # Nested functions: END ----------------------------------------------#
        
        # Init. process starts here: -----------------------------------------#
        # Tree and markdown do not exist yet:
        self.tree = None
        self.markdown_content= None

        # Folder '.' and the preferences file: Absolute paths.
        self.folder = os.path.abspath('.')
        self.preferences_file = None # MUST NOT be ''.
        
        # CREATE: Folders input, markdown, preferences/
        # FOR loop: mkdir. Order matters!
        [mkdir(get_folder(x)) for x in ('input', 'markdown', 'preferences')]

        # Preferences file ---------------------------------------------------#
        # Implement the policy; see documentation. 
        # First step: Checking for already existing preference file(s).
        preferences_file_ = set( # absolute path(s):
            x.path for x in os.scandir(get_folder('preferences')) 
            if is_preferences_file(x.path))
        
        # Message templates:
        message =('Remark: Input value for preferences file (flags: p, --prefe'
                  'rences) was dropped for the following reason:\n')
        warn = 'Preferences file%s\n%s\nalready exist%s in preferences folder.'
        
        if len(preferences_file_) == 1: # i.e single preferences file .
            found_file = preferences_file_.pop()
            set_preferences_file(found_file)

            # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
            # PRINT SUMMARY                                           #
            # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
            warn = warn%('', found_file, '')
            if user_preferences in {None, 's'}: summary = 'Remark: ' + warn 
            else: summary = message + warn
            print(summary)

        elif len(preferences_file_) > 1: # > 1 JSON file: Ambiguity
            
            # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
            # RAISE ERROR                                             #
            # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
            names        = (get_name(path=x) for x in preferences_file_)
            listof_files =', \n'.join('- '+x for x in names)
            warn         = warn%('s',listof_files,'')
            error        = ('But the preferences folder should not contain '
                            'more than one preferences file.')
            if user_preferences in {None, ''}:
                raise FileNotFoundError(warn + '\n' + error)
            else:
                raise FileNotFoundError(message + '\n' + warn + '\n' + error)
            
        else: # i.e no JSON file: Check user_preferences 
            if user_preferences in {None, ''}: # Default preferences.

                # Default preferences are copied and 
                # self.preferences_file is assigned the regular path 
                # $(pwd)/preferences/preferences.json
                set_preferences_file()

                # # # # # # # # # # # # # # # # # # # # # # # # # # # #
                # PRINT SUMMARY                                       #
                # # # # # # # # # # # # # # # # # # # # # # # # # # # #
                print('Preferences file: Created from template.')

            else: # Turn the -p argument into a single valid path.
                guess = set(x for x in (os.path.join(y, user_preferences) 
                    for y in (get_folder('.'), get_folder('preferences')))
                    if is_preferences_file(x))
                
                if len(guess) > 1: # i.e. ambiguity.
                    # # # # # # # # # # # # # # # # # # # # # # # # # #
                    # RAISE ERROR                                     #
                    # # # # # # # # # # # # # # # # # # # # # # # # # #
                    existing = '\n'.join('- '+ x for x in guess_)
                    message = ('Expected only one valid path for the '
                        'preferences file, but two were found: \n%s.')
                    raise FileNotFoundError(message%existing)

                elif len(guess) == 1: # i.e unique valid path
                    # Write its content into 'preferences/preferences.json'
                    preferences_file_to_import = guess.pop()
                    set_preferences_file(preferences_file_to_import)
                    
                    # # # # # # # # # # # # # # # # # # # # # # # # # #
                    # PRINT SUMMARY                                   #
                    # # # # # # # # # # # # # # # # # # # # # # # # # #
                    message = 'Preferences file %s was copied in preferences.'
                    print(message%preferences_file_to_import)
                
                else: # i.e. no preferences file
                    # # # # # # # # # # # # # # # # # # # # # # # # # #
                    # RAISE ERROR                                     #
                    # # # # # # # # # # # # # # # # # # # # # # # # # #
                    message = ('Input for preferences file (flags: -p, --prefe'
                        'rences) %s does not describe a preferences file.')
                    raise FileNotFoundError(message%user_preferences)
                #
            #
        # Now load the preferences file content, as a dictionary.
        self.dictionary = json.load(open(self.preferences_file, 'rb'))
        # Preferences file part : END ----------------------------------------#
        
        # We now deal with the markdown input: -------------------------------#
        # First step: Checking for already existing markdown file(s).
        markdown_file_ = set(x.path for x in os.scandir(get_folder('markdown'))
            if x.path[-3:] == '.md')
        
        if len(markdown_file_) == 1: # i.e single .md file .
            # md is set:
            self.markdown_content = open(markdown_file_.pop(), 'rb').read()

            # # # # # # # # # # # # # # # # # # # # # # # # # # # #
            # PRINT SUMMARY                                       #
            # # # # # # # # # # # # # # # # # # # # # # # # # # # #
            message = ('Markdown file found in input/markdown. Preference ' 
                '"import markdown" of preferences file was not read.')
            print(message)
        
        elif len(markdown_file_) > 1: # > 1 .md file: Ambiguity
            # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
            # RAISE ERROR                                             #
            # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
            names = (os.path.split(x)[1] for x in markdown_file_)
            message  = ('Found \n%s.\nFolder input/markdown should not '
                'contain more than one markdown file.')
            raise FileNotFoundError(message%'- '.join(names))
        
        # ELSE: No .md. 
        # First case: No markdown to import
        elif self.dictionary['import markdown'] in {None, ''}: 
            
            # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
            # RAISE ERROR                                             #
            # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
            message = ('No markdown in folder input/markdown, no markdown '
                'mentioned in preferences file.')
            raise FileNotFoundError(message)
        else: # Second case: Path to markdown in preferences file
            try:
                import_markdown = os.path.abspath(self.dictionary[
                    'import markdown'])
                self.markdown_content = open(import_markdown, 'rb').read()
            except FileNotFoundError as e:
                message = ('Folder input/markdown empty! \n'
                    'Moreover, the preferences file (field "import markdown") '
                    'does not provide a valid path/name for the markdown input.'
                    '\nA template file example.md was created in the folder '
                    'input/markdown.')
                print(message)
                content = get_file('example.md', 'input', 'markdown')
                destination =os.path.join(get_folder('markdown'), 'example.md')
                open(destination, 'wb').write(content)
                self.markdown_content = content
            #
        # Markdown input part: END -------------------------------------------#
    #
    def parse_markdown(self):
        '''
            Parses the document.
        '''
        parser = Parser()
        
        for e in self.markdown_content:
            if e < BELL:
                raise ValueError(
                '''
                    Code point < 7 was found. 
                    
                    Characters that are in the range [NULL, ..., WRU]
                    are not accepted.
                ''')
            elif e == CR:
                raise ValueError(
                    '''
                        Carriage return character (CR) was found!
                        
                        Go to your text editor settings then switch 
                        from Windows line ending (CRLF) to Unix line 
                        ending (LF). 

                        Similarly (kind reminder), set the characted 
                        encoding to 'UTF-8' if you have not done it 
                        yet. %s may not work with other encodings 
                        (e.g. Windows 1252, ISO latin).
                    '''%NAME
                )
            # else, regular case;
            parser.interpret(e)
        # ---------------------------------------------------------#
        # /!\ Now, self is being given the parser's tree  /!\:
        self.tree = parser.tree
        # ---------------------------------------------------------#
        # For chained calls:
        return self

    def get_latex(self):
        '''
            From Markdown to LaTeX.

            Creates the latex code after the parsing is done.

            Formally speaking, this method is a getter, 
            since a dictionary dict {'folder', 'document'} is returned.

            :return: A dictionary dict{folder, document}.
            :rtype: dict
        '''
        ## To be created (again): output/xelatex
        output_  = os.path.join(self.folder, 'output/')
        xelatex_ = os.path.join(self.folder, 'output', 'xelatex/')
        
        # DELETE: output/ and child folder(s) are deleted
        shutil.rmtree(output_, ignore_errors=True)
        
        # CREATE: output/xelatex
        [mkdir(x) for x in (output_, xelatex_)]
        
        # CREATE: LaTeX source code
        dictionary = self.__private__recursive(folder=xelatex_, index = 1)
        dictionary.update({
            'name': self.dictionary['name'], 
            'folder': self.folder})
        return dictionary
    #
    # Return folder, document 
    def __private__recursive(self, folder='', index=1, tree=None):
        '''
            Only called by method get_latex. 
            Recursively records the LateX code source. 

            Formally speaking, this is a getter, since the returned 
            value is a dictionary dict{folder, document}.

            :param folder: the base folder; 
            see https://docs.python.org/3.11/library/os.path.html
            :param index: heading number, e.g section 1, section 2, ...
            :param tree: The tree from which the LaTeX code is made.
            :type folder: posixpath, ntpath
            :type index: int
            :type tree: Tree
            :return: A dictionary dict{folder, document}.
            :rtype: dict
        '''
        # Nested function, to deal with Latex heading and input --------------#
        def latex_heading_and_input(folder, index, subtree):
            '''
                Returns the heading and the latex input, as a string.
            '''
            latex_heading = ''.join((
                '\\',subtree.to_string('level'),
                '{', subtree.to_string('heading'), '}'))

            # ----- Recursion is here: --------------------------------#
            dictionary =self.__private__recursive(folder,index, subtree)
            # ---------------------------------------------------------#
            latex_input = '{}{}'.format(*dictionary.values())
            return ''.join((latex_heading, '\n', '\input{', latex_input, '}'))
        # Latex heading and input: END ---------------------------------------#
        
        # "SWITCH CASE" ------------------------------------------------------#
        if tree == None:
            current_folder = folder
            #shutil.rmtree(folder, ignore_errors=True)
            
            # ----- Now, fetch the PARSER TREE ------------------------#
            tree     = self.tree 
            # ----- Now tree.level SHOULD BE 1 ------------------------#
            
            document = 'mainmatter.tex'
            latex_documentclass_ = self.dictionary['document class']
            xelatex_mainfont_    = self.dictionary['main font']
            updateDM = {
                # LaTeX \documentclass
                'class': latex_documentclass_['class'],
                'size':  latex_documentclass_['size'],
                'paper': latex_documentclass_['paper'],
                # XeLaTeX mainfont:
                'mainfontname':  xelatex_mainfont_['name'],
                'mainfontalias': xelatex_mainfont_['alias'],
                # About the author:
                'author': self.dictionary['author'],
                'email':  self.dictionary['email'],
                # About the content:
                'title': tree.to_string('heading'),
                # For LaTeX \input
                'root':  os.path.abspath(folder),
            }
            # Now update DM.tex:
            DM = get_file('DM.tex','input', 'xelatex', mode='r')
            for k, v in updateDM.items(): 
                DM = DM.replace('MarkdownToLaTeX:'+k, v)
            open(os.path.join(current_folder, 'DM.tex'), 'w').write(DM)
            #
        elif tree.level > 1:
            nameof_file    = tree.to_string('heading', whitespaces=False)
            document       = nameof_file + '.tex'
            current_folder = ''.join((folder, tree.to_string('level'), 
                '%d', '_', nameof_file, '/'))%(index+10)
            
            # CREATE: Current folder
            try:
                os.mkdir(current_folder)
            except OSError:
                # TODO: later, for verbose mode?
                pass
            #
        text = tree.to_string('text')
        content = [text]*(text != '')
        #
        if tree.branches != []: content.extend ((
                # - Recursion lies here, see latex_heading_and_input -#
                latex_heading_and_input(current_folder, index, subtree)
                for index, subtree in enumerate(tree.branches)
                # ----------------------------------------------------#
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

