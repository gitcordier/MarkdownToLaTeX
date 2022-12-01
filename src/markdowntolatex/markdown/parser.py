#-----------------------------------------------------------------------------#
# parser.py                                                                   #
#-----------------------------------------------------------------------------#
# Description: 
'''
    The Markdown parser.
'''
from markdowntolatex.markdown.encoding import *
from markdowntolatex.markdown.tree import *
from markdowntolatex.utilities import *


class Parser():
    def __init__(self, dialect='Github'):
        self.state = 'ANYTHING'
        self.read = -1
        self.level = 0
        self.tree = None
        # TODO: unicode range

        # Counts for backslash, hash, space. ---------------------------------#
        # Kept into a dictionary;
        self.count = dict(zip(('backslash', 'hash', 'space'), [0]*3))
        self.mode = 'text'
        # Counts for backslash, hash, space. END -----------------------------#
    #
    @staticmethod
    def is_regular_character(read):
        '''
            A character is a regular character 
            **iff** it is not a *special character*.
        '''
        return read not in SPECIAL_CHARACTERS
    #
    @staticmethod
    def latex(command, card=1, line_break=False):
    #----------------------------------------------------------------------#
        '''
            Given a LaTex command *command* and a cardinality *card*, 
            returns the sequence *command* +  … + *command* (*card* time(s)).

            Optionally, appends n (n = 0, 1, 2, ...) line break(s) 
            at the end of the sequence **iff** 'line_break' is set to n. 

            Note that (1) *line_break=True* means *line_break=1*, 
            (2) *line_break=False* means *line_break=0*.

            TODO: Exceptions (card)
            :param command: plain text that denotes a LaTeX command ("backslash", "newline", …).
            :param card: the number of times *command* is repeated.
            :type card: int
            :param line_break: Appended line break(s).
            :type line_break: int 
            :return: A LaTeX command, as a list of code points.
            :rtype: list
        '''
        try: 
            latex_command = LATEX_COMMAND_['LATEX_' + command.upper()]
        except:
            raise ValueError('''"%s" is an illegal command. "backslash", "newline" are legal commands.'''%command)
        #
        try:
            assert int(line_break) >= 0
        except AssertionError:
            raise ValueError('line_break was not assigned a legal value (Found linebreak=%s).'%str(line_break))
        #
        return latex_command*card + [LF]*line_break
    #

    def interpret(self, read):
        '''
            The automaton that rules the markdown parsing.

            :param read: the currently read character, as an int.
            :type: int
            :raise: **ValueError** iff read is not a legal code point.

            TODO: Define the legal range for code points.
            TODO: Implement ValueError.
        '''
        if self.state == 'ANYTHING':
            if read == LF:
                self.update_text(LF)
            elif read == HASH:
                self.set_state('MAYBE LEVEL')
                self.update_count('hash')
            elif read == SPACE:
                # TODO: Implement "The opening # character may be
                # indented 0-3 spaces."
                # See:4.2ATX headings
                self.set_state('IS READING TEXT')
                self.update_text(SPACE)
            elif read == DOLLAR:
                self.set_state('IS READING TEXT')
                self.mode = 'latex'
            elif self.is_regular_character(read):
                self.set_state('IS READING TEXT')
                self.update_text(read)
            #
        elif self.state == 'MAYBE LEVEL':
            if read == LF:
                self.set_state('ANYTHING')
                self.update_text(LF)
            elif read == HASH:
                if self.count['hash'] < 3:
                    self.update_count('hash')
                else:  # CASE 3, a fourth '#' is read.
                    self.set_state('IS READING TEXT')
                    [self.update_text(HASH, head=BACKSLASH)
                                      for i in range(3)]
                    self.reset_count('hash')
            elif read == SPACE:
                self.set_state('HAS READ LEVEL')
                self.level = self.count['hash']
                # self.set_level('hash')
                self.update_tree()
                self.reset_count('hash')
            elif self.is_regular_character(read):
                self.set_state('IS READING TEXT')
                self.update_text(read, prefix=[HASH]*self.count['hash'])
                self.reset_count('hash')
            #
        elif self.state == 'HAS READ LEVEL':
            if read == LF:
                self.set_state('ANYTHING')
                self.update_text(LF)
            elif read == SPACE:  # UNCHANGED <<state, level, tree>>
                pass
            elif self.is_regular_character(read) or read == HASH:
                self.set_state('IS READING HEADING')
                self.update_heading(read)
            #
        elif self.state == 'IS READING HEADING':
            if read == LF:
                self.set_state('ANYTHING')
            elif read == HASH:
                self.update_heading(HASH, prefix=BACKSLASH)
            elif read == SPACE:
                self.update_count('space')
            elif self.is_regular_character(read):
                self.update_heading(
                        read, prefix=[SPACE]*self.count['space'])
                self.reset_count('space')
            #
        elif self.state == 'IS READING TEXT':
            if read == LF:
                if self.is_count_positive('backslash'):
                    if self.is_count_even('backslash'):
                        n = int(self.count['backslash']/2)
                        prefix = self.latex('backslash', n)
                        if self.mode == 'latex':
                            pass
                        else:
                            prefix.insert(0, DOLLAR)
                            prefix.append(DOLLAR)
                        suffix = []
                    else:
                        n = int((self.count['backslash'] - 1) / 2)
                        prefix = self.latex('backslash', n)
                        suffix = self.latex('newline', line_break=True)
                    self.update_text(LF, prefix=prefix, suffix=suffix)
                    self.reset_count('backslash')
                elif self.is_count_positive('space'):
                    if self.count['space'] > 1:
                        suffix = self.latex('newline', line_break=True)
                        self.update_text(LF, suffix=suffix)
                    else:
                        pass
                    self.reset_count('space')
                #
                self.set_state('ANYTHING')
            elif read == SPACE:
                self.update_text(SPACE)
                self.count['space'] == 1
            elif read == BACKSLASH:
                self.count['backslash'] += 1
            elif read == HASH:  # TODO
                if self.backslash == 1:
                    self.update_text(read, head=BACKSLASH)
                    self.backslash = 0
            elif read == ASTERISK:  # TODO
                self.update_text(ASTERISK)
            elif read == DOLLAR:
                self.update_text(DOLLAR)
                self.update_mode()
            elif self.is_regular_character(read):
                if self.count['space'] > 0:
                    self.update_text(read, head=SPACE)
                    self.reset_count('space')
                elif self.count['backslash'] > 0:
                    n = int((self.count['backslash'] - 1) / 2)
                    prefix = self.latex('backslash', n).append(BACKSLASH)
                    self.update_text(read, prefix=prefix)
                    self.reset_count('backslash')
                else:
                    self.update_text(read)
            #
        #
        self.read = read
    #

    def set_state(self, state):
        '''
            **state** is assigned the value of *state*.
        '''
        self.state = state
    #

    def set_level(self, level):
        '''
            the inner **level** is updated with respect to the given value of *level*.
        '''
        if level == 'hash':
            self.level = self.count['hash']
        else:
            self.level = level
        #
    #

    def __private__substitute(self, value=None, array=None):
        '''
            TODO.
        '''
        if value == None:
            if array == None:
                new_array = []
            else:
                new_array = array
        else:
            new_array = [value]
        return new_array
    #
    
    def __private__get_data_for_update(self, read, head=None, prefix=None, 
        tail=None, suffix=None):
        '''
            Given *read$, creates word made from **read**, prefix, suffix. 

            Both prefix and suffix can be [].

            :param read: The read character.
            :type read: int
            :param prefix: An optional prefix
            :type prefix: list
            :param tail: An optional tail
            :type tail: list
            :param suffix: An optional suffix (if no **tail**)
            :type suffix: list
        '''
        subtree = self.tree.find_diagonal_up()
        new_prefix = self.__private__substitute(head, prefix)
        new_suffix = self.__private__substitute(tail, suffix)
        #
        return subtree, new_prefix + [read] + new_suffix
    #

    def update_heading(self, read, head=None, prefix=None, tail=None, 
        suffix=None):
        '''
            Given *read**, updates the heading. 

            :param read: The read character.
            :type read: int
            :param prefix: An optional prefix
            :type prefix: list
            :param tail: An optional tail
            :type tail: list
            :param suffix: An optional suffix (if no **tail**)
            :type suffix: list
        '''
        subtree, array = self.__private__get_data_for_update(
                read, head, prefix, tail, suffix)
        [subtree.update_heading(x) for x in array]
    #

    def update_text(self, read, head=None, prefix=None, tail=None,suffix=None):
        '''
            Given *read**, updates the text. 

            :param read: The read character.
            :type read: int
            :param prefix: An optional prefix
            :type prefix: list
            :param tail: An optional tail
            :type tail: list
            :param suffix: An optional suffix (if no **tail**)
            :type suffix: list

            Updates the (core) text that will be injected 
            into the LaTeX code source.
        '''
        subtree, array = self.__private__get_data_for_update(
                read, head, prefix, tail, suffix)
        [subtree.update_text(x) for x in array]
    #

    def update_tree(self):
        '''
            Updates the current tree by appending a node at the upper right extremity.
            If the tree does not exist yet, the node becomes the tree. 
        '''
        node = Tree(height=1, level=self.level)
        if self.level == 1 and self.tree == None:
            self.tree = node
        elif self.level == self.tree.height + 1:
            self.tree.update_diagonal(node)
        elif self.level < self.tree.height + 1:
            self.tree.add_branch(self.level, node)
        #
    #

    def reset_count(self, key):
        '''
            Resets self.count[*key*] to 0.

            :param: *key* a key for the dictionary *count*.
            :type: str
            :raise: **KeyError** iff key is not a key for count.
        '''
        self.count[key] = 0
    #

    def update_count(self, key, n=1):
        '''
            Given a counting number n=1, 2, 3, …,   @increases self.count[*key*] by n.

            :param: *key*, a key for the dictionary *count*.
            :type: str
            :param: n the value that adds to  self.count[*key*].
            :type: int
            :raise: **KeyError** iff key is not a key for count.
            :raise: **TypeError** iff n is not an integer
            :raise: **ValueError** iff n is not a positive integer.
        '''
        self.count[key] += n
    #

    def is_count_positive(self, key):
        '''
            :param: *key*, a key for the dictionary *count*.
            :type: str
            :return: **True** iff self.count[*key*] is positive.
            :rtype: Boolean
            :raise: **TypeError** iff self.count[*key*] is not an integer.

            TODO: Implement exceptions management.
        '''
        return is_positive(self.count[key])
    #

    def is_count_even(self, key):
        '''
            :param: *key*, a key for the dictionary *count*.
            :type: str
            :return: **True** iff self.count[*key*] is an even interger.
            :rtype: Boolean
            :raise: **TypeError** iff self.count[*key*] is not an integer.

            TODO: Implement exceptions management.
        '''
        return is_positive(self.count[key])
    #

    def is_count_odd(self, key):
        '''
            :param: *key*, a key for the dictionary *count*.
            :type: str
            :return: **True** iff self.count[*key*] is an odd interger.
            :rtype: Boolean
            :raise: **TypeError** iff self.count[*key*] is not an integer.

            TODO: Implement exceptions management.
        '''
        return is_odd(self.count[key])
    #

    def update_mode(self, mode=None):
        '''
            Sets **self.mode** to **mode**. 

            :param: *mode*, a mode identifier.
            :type: str
            :raise: ValueError iff **mode** is not a legal mode.

            TODO: Implement exceptions management.
        '''
        if mode == None:
            if self.mode == 'text':
                self.mode = 'latex'
            else:
                self.mode = 'text'
        else:
            self.mode = mode
        #
    #
# END
