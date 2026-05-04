#---------------------------------------------------------------------------------------------#
# workspace.py                                                                                #
# Abstraction for the User's worksspace.                                                      #
#---------------------------------------------------------------------------------------------#
"""
    Workspace readiness check for MarkdownToLaTeX 1.0.0.

    Implements Directory.1.3.7.tla. The User's working directory DIR is
    *ready* iff:

    1. DIR is a directory,
    2. DIR/preferences is a directory,
    3. DIR/preferences/preferences.json is a regular file.
"""
from __future__ import annotations

import json
from enum import Enum
from pathlib import Path


class Workspace:
    """
        Stateful abstraction for the User's working directory.

        Args:
            path: the working directory. Defaults to :func:`pathlib.Path.cwd`.
    """

    class Check(Enum):
        """
            The three steps of the readiness chain.

            The value of each member is the corresponding TLA+ flag name.
        """
        IS_DIR               = "is_dir"
        HAS_PREFERENCES_DIR  = "has_preferences_dir"
        HAS_JSON_PREFERENCES = "has_JSON_preferences"

    class Error(Exception):
        """
            Raised when DIR fails the readiness chain.

            Attributes:
                step: the Workspace.Check at which the chain failed.
                path: the file-system path that was checked.
        """
        def __init__(self, step: Workspace.Check, path: Path) -> None:
            self.step = step
            self.path = path
            super().__init__(
                f"workspace not ready: {self.step.value} failed.\n"
                f"Could not find {self.path}"
            )

    def __init__(self, path: Path | None = None) -> None:
        self.path      = Path.cwd() if path is None else path
        self.pref_dir  = self.path / "preferences"
        self.pref_file = self.pref_dir / "preferences.json"
        self.pref_dict: dict = {}

    def load_preferences(self) -> Workspace:
        """
            Load preferences from disk into self.pref_dict.

            Raises:
                Workspace.Error: if any step of the readiness chain fails.
        """
        try:
            with open(self.pref_file, "r", encoding="utf-8") as f:
                self.pref_dict |= json.load(f)
        except OSError as e:
            if not self.path.is_dir():
                raise Workspace.Error(
                    Workspace.Check.IS_DIR, self.path) from e
            elif not self.pref_dir.is_dir():
                raise Workspace.Error(
                    Workspace.Check.HAS_PREFERENCES_DIR, self.pref_dir) from e
            elif not self.pref_file.is_file():
                raise Workspace.Error(
                    Workspace.Check.HAS_JSON_PREFERENCES, self.pref_file) from e
            else:
                # All three re-checks passed: the file came back during
                # the diagnostic. Re-raise the original error.
                raise
        return self
    #
# END
