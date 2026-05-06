import configparser

config = configparser.ConfigParser(inline_comment_prefixes=(';'))
config.read("preferences.ini") 

def cleanup(s):
    return s.replace('$', '#')

prefs = {}

for section in config.sections():
    dct = dict(config[section])
    for k, v in dct.items(): 
        dct[k] = cleanup(v)
    prefs[section] = dct

#prefs['general']['import_markdown'] = config.getboolean('general', 'import_markdown')
print(prefs)
    
