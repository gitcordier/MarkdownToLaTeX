#---------------------------------------------------------------------------------------------#
# cli.py                                                                                      #
#---------------------------------------------------------------------------------------------#
# Description
'''
    The CLI is encoded as a Python dictionary whose keys are "version", "params". 
    "help" option is implemented by an argparse.ArgumentParser instance.
'''

CLI = {
    "version": {
        "flags": [
            "-v",
            "--version"
        ],
        "params": {
            "dest": "version",
            "action": "store_true",
            "default": False,
            "help": "Package version, following the usual \"major.minor.micro\" scheme."
        }
    }
}
