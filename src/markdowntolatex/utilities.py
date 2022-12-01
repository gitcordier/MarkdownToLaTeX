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
        :raise ModuleNotFoundError: If the package metadata do not mention the package name. 
        :raise FileNotFoundError: If the folder **package_data** do not exist. 
        :return: The desired file, as a string.
        :rtype: str
    '''
    # ModuleNotFoundError
    try:
        package = importlib.resources.files(NAME.lower())
    except ModuleNotFoundError:
        # IF troubble, then update NAME in metadata.py
        raise ModuleNotFoundError(
            '''
                Call of get_file(nameof_file, ...) failed because 
                the variable NAME in metadata.py does not expose 
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
                Call of get_file(nameof_file, ...) failed because 
                folder %s/src/%s/package_data does not exist.
            '''%(NAME, NAME.lower())
        raise e
    #
#
def is_integer(x):
    '''
        :param x: Any value, object
        :return: True iff x in an integer.
        :rtype: Boolean
    '''
    try:
        return int(x) == x
    except (TypeError, ValueError):
        return False
def is_positive(n):
    '''
        :param n: An integer
        :type n: int
        :raise TypeError: If n is not an integer.
        :return: True iff n is a positive integer.
        :rtype: Boolean
    '''
    try:
        assert is_integer(n)
    except AssertionError as e:
        return TypeError('%s is not an integer'%str(n))
    return n > 0
#
def is_even(n):
    '''
        :param n: An integer
        :type n: int
        :raise TypeError: If n is not an integer.
        :return: True iff n is even.
        :rtype: Boolean
    '''
    try:
        assert is_integer(n)
    except AssertionError as e:
        return TypeError('%s is not an integer'%str(n))
    return n > 0
#
def is_positive_even(n):
    '''
        :param n: An integer
        :type n: int
        :raise TypeError: If n is not an integer.
        :return: True iff n is a positive even integer.
        :rtype: Boolean
    '''
    try:
        assert is_integer(n)
    except AssertionError as e:
        return TypeError('%s is not an integer'%str(n))
    return n > 0 and n % 2 == 0
#
def is_odd(n):
    '''
        :param n: An integer
        :type n: int
        :raise TypeError: If n is not an integer.
        :return: True iff n is odd.
        :rtype: Boolean
    '''
    try:
        assert is_integer(n)
    except AssertionError as e:
        return TypeError('%s is not an integer'%str(n))
    return n % 2 == 1 
#
