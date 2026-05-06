#---------------------------------------------------------------------------------------------#
# cli.py                                                                                      #
#---------------------------------------------------------------------------------------------#
# Description
'''
    Command line interface definition. 
    A dictionary **ARGUMENT** stores all arguments definitions. 
'''

import json

#The maximal number of input strings we expect from the user: 
#    Two arguments (help, preferences), one value (for preferences). 
#    Three, then
MAX_NUMBEROF_INPUTS = 3 


def get_arguments():
    with open("cli.json", "r", encoding="utf-8") as f:
        return json.load(f)
    

#The dictionary **ARGUMENT** stores all arguments definitions. 

# END
