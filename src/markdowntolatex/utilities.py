#-----------------------------------------------------------------------------#
# utilities.py                                                                #
# Misc functions, to make the code more expressive / readable                 #
#-----------------------------------------------------------------------------#
import os 
import importlib.resources 

from markdowntolatex.constants import NAME

def get_file(name, *prefix, **kwargs):
    '''
        Fetch a file *name* the from **package_data** folder (only).

        :param name: The file's name.
        :type name: str
        :raise ModuleNotFoundError: If the package metadata 
            do not mention the package name. 
        :raise FileNotFoundError: If the folder **package_data** do not exist. 
        :return: The desired file, as a string or a byte array
        :rtype: str or byte array
    '''
    # ModuleNotFoundError
    try:
        package = importlib.resources.files(NAME.lower())
    except ModuleNotFoundError:
        # IF troubble, then update NAME in metadata.py
        raise ModuleNotFoundError(
            '''
                Call of get_file(nameof_file, ...) failed. Reason:  
                The variable NAME in metadata.py does not expose 
                the right name of the package. 
            '''
        )
    #
    with importlib.resources.as_file(package) as root:
        urlof_file = os.path.join(root, 'package_data', *prefix, name)
    #
    if 'mode' in kwargs and kwargs['mode'] in {'r', 'rb'}:
        mode = kwargs['mode']
    else:
        mode = 'rb'
    #
    try:
        with open(urlof_file, mode) as f:
            return f.read()
        #
    except FileNotFoundError as e: 
        e.errno = '''
                Call of get_file(nameof_file, ...) failed. Reason:
                Folder %s/src/%s/package_data does not exist.
            '''%(NAME, NAME.lower())
        raise e
    #
#
def mkdir(path):
    try: 
        os.mkdir(path)
        print('Folder %s has been created.'%path)
    except FileExistsError:
        print('Remark: Folder %s already exists.'%path)
    #

def is_integer(x):
    '''
        :param x: Any value, object
        :return: True iff x in an integer.
        :rtype: Boolean
    '''
    try:
        assert int(x) == x
    except (TypeError, ValueError, AssertionError):
        return False
    return True
#
def is_positive(x):
    '''
        :param x: Any value, object
        :return: True iff x is a positive **integer**.
        :rtype: Boolean
    '''
    
    return is_integer(x) and x > 0
#
def is_even(x):
    '''
        :param x: Any value, object
        :return: True iff x is an even number.
        :rtype: Boolean
    '''
    return is_integer(x) and x % 2 == 0
#
def is_positive_even(x):
    '''
        :param x: Any value, object
        :return: True iff x is a positive even number.
        :rtype: Boolean
    '''
    return is_integer(x) and x > 0 and x % 2 == 0
#
def is_odd(x):
    '''
        :param x: Any value, object
        :return: True iff x is an an odd integer
        :rtype: Boolean
    '''
    return is_integer(x) and x % 2 == 1 
#
def is_positive_odd(x):
    '''
        :param x: Any value, object
        :return: True iff x is a positive odd number.
        :rtype: Boolean
    '''
    return is_integer(x) and x > 0 and x % 2 == 1
#
