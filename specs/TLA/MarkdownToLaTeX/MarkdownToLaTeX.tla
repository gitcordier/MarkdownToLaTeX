----------------------------- MODULE MarkdownToLaTeX ------------------------------------------------
EXTENDS Sequences

CONSTANTS
    KEYS,
    LUALATEX,
    LUALATEX_CORE,
    LUALATEX_OPTIONS

VARIABLE 
    user_workspace
    (*user_preferences_check_state, 
    user_preferences_keys*)

  
(*var_preference == <<
    user_preferences_keys, 
    user_preferences_check_state
  >>*)

(*vars == <<user_workspace>> \o var_preference*)


Workspace == INSTANCE Directory WITH 
    directory <- user_workspace

(*WorkspacePreferences == INSTANCE Preferences WITH 
    state            <- user_preferences_check_state,
    preferences_keys <- user_preferences_keys*)


InitMarkdownToLaTeX == 
    /\ Workspace!InitDirectory
    (*/\ WorkspacePreferences!InitPreferences*)


NextMarkdownToLaTeXnextDirectory == 
    /\ Workspace!NextDirectory
    (*/\ WorkspacePreferences!InitPreferences*)
    (*/\ UNCHANGED var_preference*)

(*NextMarkdownToLaTeXnextPreferences ==
    /\ WorkspacePreferences!NextPreferences
    /\ Workspace!NextNoDeadlockOK
    /\ UNCHANGED user_workspace*)



NextMarkdownToLaTeX == 
    \/ NextMarkdownToLaTeXnextDirectory
    (*\/ NextMarkdownToLaTeXnextPreferences*)
    
Init == InitMarkdownToLaTeX
Next == NextMarkdownToLaTeX


Spec == Init /\ [Next]_user_workspace (*! not vars*)


===============================================================================================
\* Modification History
\* Last modified Sun May 10 15:27:14 CEST 2026 by gcordier
\* Created Tue May 31 21:41:17 CEST 2022 by gcordier


