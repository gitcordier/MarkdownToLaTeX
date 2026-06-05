#---------------------------------------------------------------------------------------------#
# workspace.py                                                                                #
# Abstraction for the User's workspace.                                                       #
#---------------------------------------------------------------------------------------------#
"""
    Workspace readiness check for MarkdownToLaTeX 1.0.0.

    This module provides :class:`Workspace`, a stateful abstraction over the User's
    working directory ``DIR``. The readiness chain is the Python realization of the
    formal specification ``Directory.tla``: ``DIR`` is *ready* iff

    1. ``DIR/preferences`` is a directory, and
    2. ``DIR/preferences/preferences.ini`` is a regular file.

    Each call to :meth:`Workspace.load_preferences` runs the state machine from
    ``InitDirectory`` to one terminal state. ``AllProved`` reaches normal return; the
    other two terminal states raise :exc:`Workspace.Error` with the matching
    :class:`Prove` verdict.

    Note:
        ``DIR`` is :func:`pathlib.Path.cwd`. The precondition "``DIR`` exists and is
        a directory" is discharged by the OS for the current working directory and
        is therefore not modeled in ``Directory.tla``.
"""
from __future__ import annotations 
from enum import Enum
from pathlib import Path
from string import Template
import configparser



class Verdict(Enum):
    """
        Failure verdicts of the workspace readiness chain.

        Each member names one terminal state of ``Directory.tla`` that maps to a
        :exc:`Workspace.Error`. The third terminal state (``AllProved``) is the
        success path and is not represented here.

        Attributes:
            NO_FILE__HAS_SUBDIR: the preferences subdirectory exists, but the
                ``preferences.ini`` file inside it does not. TLA terminal:
                ``{has_preferences_file: disproved, has_preferences_subd: proven}``.
            NO_FILE__NO_SUBDIR: neither the preferences subdirectory nor the file
                exists. TLA terminal: ``AllDisproved``.
    """
    NO_FILE__HAS_SUBDIR = "no preferences file, has preferences subdirectory"
    NO_FILE__NO_SUBDIR  = "no preferences file, no preferences subdirectory"


class Workspace:
    """
        Stateful abstraction over the User's working directory.

        On construction, :class:`Workspace` derives the canonical paths under
        :func:`pathlib.Path.cwd` but performs no disk I/O. Preferences are loaded
        only when :meth:`load_preferences` is called.

        Attributes:
            path (:class:`pathlib.Path`): the working directory; ``Path.cwd()``.
            pref_subd (:class:`pathlib.Path`): ``path / "preferences"``.
            pref_file (:class:`pathlib.Path`): ``pref_subd / "preferences.ini"``.
            pref_dict (dict): preferences loaded from :attr:`pref_file`. Empty
                until :meth:`load_preferences` succeeds.

        Example:
            >>> ws = Workspace().load_preferences()
            >>> ws.pref_dict["author"]
            'Alan Berliner'
    """

    class Error(Exception):
        """
            Raised when the working directory fails the readiness chain.
        """
        msg = Template("workspace not ready: $step failed.\nCould not find $path")

        def __init__(self, step: Prove, path: Path) -> None:         
            super().__init__(self.msg.substitute(step=step.value, path=path))
        #
    # END: nested class Error

    def __init__(self) -> None:
        self.path      = Path.cwd()
        self.pref_subd = self.path / "preferences"
        self.pref_file = self.pref_subd / "preferences.ini"
        self.pref_dict = {}
    #
    def __load_preferences__(self):
        config = configparser.ConfigParser(inline_comment_prefixes=(';'))
        config.read(self.pref_file) 

        self.pref_dict.update(
            (section, {k: v.replace('$', '#') for k, v in dict(config[section]).items()}) 
            for section in config.sections()
        )
        #prefs['general']['import_markdown'] = config.getboolean('general', 'import_markdown')
        #print(self.pref_dict)

    def load_preferences(self) -> Workspace:
        """
            Run the readiness chain and load preferences from disk.

            The chain mirrors ``Directory.tla``: opening :attr:`pref_file` is the
            ``NextFile`` action; an :exc:`OSError` raised by ``open`` enters
            ``NextNoFile``; the subsequent :meth:`pathlib.Path.is_dir` check on
            :attr:`pref_subd` dispatches between ``NextNoFileHasDir`` and
            ``NextNoFileNoDir``.

            On success, :attr:`pref_dict` is populated by
            :func:`user.preferences.load`.

            Returns:
                :class:`Workspace`: ``self``, for method chaining.

            Raises:
                Workspace.Error: with :attr:`Prove.NO_FILE__HAS_SUBDIR` if the
                    subdirectory exists but the file does not; with
                    :attr:`Prove.NO_FILE__NO_SUBDIR` if the subdirectory is absent.
        """
        try:
            with open(self.pref_file, "r", encoding="utf-8") as f:
                self.__load_preferences__()          # NextFile
        except OSError as no_file:                   # NextNoFile
            if self.pref_subd.is_dir():              # NextNoFileHasDir
                raise Workspace.Error(Verdict.NO_FILE__HAS_SUBDIR, self.pref_file) from no_file
            else:                                    # NextNoFileNoDir
                raise Workspace.Error(Verdict.NO_FILE__NO_SUBDIR, self.pref_subd) from no_file
            #
        return self
    # END: load_preferences, class Workspace
# END

#w = Workspace()
#w.load_preferences()