#-----------------------------------------------------------------------------#
# encoding.py                                                                 #
# Useful constants                                                            #
#-----------------------------------------------------------------------------#

'''
    Unicode UTF-8 code points of characters that play a special role: 
    LF, #, \ , ... , and so on. 
    Note for Windows users:
    the CRLF EOL is not taken into account. Please switch to LF.
'''
# Characters code points (UTF-8):
BELL = 7
LF = 10
'''**LF**, code point: U+000A.'''
CR = 13
HASH = 35
''' **#**, code point: U+0023. '''
SPACE = 32
''' \' \' , code point: U+0020.'''
DOLLAR = 36
'''**$**, code point: U+0024.'''
ASTERISK = 42
'''**\***, code point: U+002A.'''
UNDERSCORE = 95
'''**_**,code point: U+005F.'''
BACKSLASH = 92 
'''**\\\**, code point: U+005C.'''
SPECIAL_CHARACTERS = {LF, HASH, SPACE} 
'''
        LF, hash, space are the *special characters*.
'''

#----------------------------------------------------------------------#
# LaTeX commands: As code points sequences
#----------------------------------------------------------------------#
LATEX_BACKSLASH = [92, 98, 97, 99, 107, 115, 108, 97, 115, 104]
'''\\backslah = (\\\, b, a, c, k, s, l, a, s, h)'''
LATEX_NEWLINE = [92, 92]
'''\\newline = (\\\, \\\)'''
LATEX_COMMAND_ = {
    'LATEX_BACKSLASH': LATEX_BACKSLASH, 
    'LATEX_NEWLINE': LATEX_NEWLINE
}
# END
