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
LF = 10                                 # aka u'\u000A': Line Feed/EOL
'''**LF**, aka U+000A: Line Feed/EOL'''
CR = 13
HASH = 35                               # aka u'\u0023': Hash (#)
''' **#** , aka U+0023: Hash'''
SPACE = 32                              # aka u'\u0020': Space
''' \' \' , aka U+0020: Space'''
DOLLAR = 36                             # aka u'\u0024': Dollar ($) 
'''**$** , aka U+0024: Dollar'''
ASTERISK = 42                           # aka u'\u002A': Asterisk (*)
'''**\*** , aka U+002A: Asterisk'''
UNDERSCORE = 95                         # aka u'\u005F': Underscore (_)
'''**_** ,aka U+005F: Underscore'''
BACKSLASH = 92                          # aka u'\u005C': Backslash (\) 
'''**\\\** , aka U+005C: Backslash'''
SPECIAL_CHARACTERS = {LF, HASH, SPACE} 
'''
        LF, hash, space are the *special characters*.
'''

#----------------------------------------------------------------------#
# LaTeX commands: As code points sequences
#----------------------------------------------------------------------#
# \backslah = (\, b, a, c, k, s, l, ...)
LATEX_BACKSLASH = [92, 98, 97, 99, 107, 115, 108, 97, 115, 104]
'''\\backslah = (\\\, b, a, c, k, s, l, ...)'''
# Similarly, \newline = (\, \)
LATEX_NEWLINE = [92, 92]
'''\\newline = (\\\, \\\)'''

LATEX_COMMAND_ = {
    'LATEX_BACKSLASH': LATEX_BACKSLASH, 
    'LATEX_NEWLINE': LATEX_NEWLINE
}
# END
