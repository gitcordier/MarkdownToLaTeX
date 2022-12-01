#-----------------------------------------------------------------------------#
# tree.py                                                                     #
# The tree that "grows" as the parsing starts.                                #
#-----------------------------------------------------------------------------#
import os 
import shutil

from markdowntolatex.markdown.encoding import *

class Tree():
    '''
        Tree is the tree

        :param height: The tree's height at instantiation. Positive integer.
        :type height: int
        :param level: The tree's level at instantiation. Positive integer.
        :param type: int
        
        TODO: Exceptions
    '''
    def __init__(self, height, level): # height = 1, 2, 3, ...
        self.height = height
        self.level = level
        self.branches = []
        self.heading = []
        #self.height_max = height
        self.text = []
    #
    def get_level_max(self):
        '''
            return: *level_max* (see mathsheet)
        '''
        return self.height + self.level -1
    #
    def find_diagonal_up(self):
        '''
            Find the upper diagonal element and returns it.

            :return: The subtree (should be a **Node**)
            :rtype: **Tree**

            TODO: Warning if diagonal element is not a **Node**
        '''
        tree = self
        while tree.branches != []:
            tree = tree.branches[-1]
        return tree
    #
    def update_diagonal(self, subtree):
        '''
            TODO: Compare with **add_branch**.
        '''
        diagonal = self.find_diagonal_up()
        diagonal.branches.append(subtree)
        self.height += subtree.height
        diagonal.height = self.height + self.level - diagonal.level 
    #
    def add_branch(self, level, subtree):
        '''
            Adds branch (a "subtree") to **self.tree**.

            The height of the tree is updated accordingly.
        '''
        branches = self.branches
        for s in range(self.level, level-1):
            branches = branches[-1].branches
        branches.append(subtree)
        self.height = level - self.level + subtree.height
    #
    def update_heading(self, read):
        '''
            updates the curent heading with *read*.
        '''
        self.heading.append(read)
    #
    def update_text(self, read):
        '''
            updates the curent text heading with *read*.
        '''
        self.text.append(read)
    #
    def to_string(self, arg, whitespaces=True):
        '''
            TODO: !
        '''
        if arg == 'level':
            if self.level == 3:
                return 'subsection'
            elif self.level == 2:
                return 'section'
            elif self.level == 1:
                return 'title'
            #
        #
        elif arg == 'heading':
            heading = ''.join(chr(x) for x in self.heading)
            if whitespaces == True:
                return heading
            else:
                return heading.replace(chr(SPACE), chr(UNDERSCORE)).lower()
            #
        #
        elif arg == 'text':
            return ''.join(chr(x) for x in self.text)
        else:
            pass
        #
    #
    def __private__DEBUG_to_string(self, n=1, tree=None):
        if tree == None:
            tree = self
        s = ', '.join(('-'*n,
            #'height max: ',         str(tree.height_max), 
            'height (diagonal): ',  str(tree.height), 
            'heading: ',            tree.to_string('heading', whitespaces=True),
            'level (of tree): ',    str(tree.level),
            '\n'
        ))
        for e in tree.branches:
            s += self.__private__DEBUG_to_string(n+1, e)
        #
        return s
    #
#

