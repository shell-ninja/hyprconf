### key-bindings.fish ###
#     ____      ____
#    / __/___  / __/
#   / /_/_  / / /_
#  / __/ / /_/ __/
# /_/   /___/_/ key-bindings.fish
#
# - $FZF_CTRL_T_COMMAND
# - $FZF_CTRL_T_OPTS
# - $FZF_CTRL_R_COMMAND
# - $FZF_CTRL_R_OPTS
# - $FZF_ALT_C_COMMAND
# - $FZF_ALT_C_OPTS

# Key bindings
# ------------
function fzf_key_bindings

  # The oldest supported fish version is 3.4.0. For this message being able to be
  # displayed on older versions, the command substitution syntax $() should not
  # be used anywhere in the script, otherwise the source command will fail.
  if string match -qr -- '^[12]\\.|^3\\.[0-3]' $version
    echo "fzf key bindings script requires fish version 3.4.0 or newer." >&2
    return 1
  else if not command -q fzf
    echo "fzf was not found in path." >&2
    return 1
  end

  function __fzf_defaults
    # $argv[1]: Prepend to FZF_DEFAULT_OPTS_FILE and FZF_DEFAULT_OPTS
    # $argv[2..]: Append to FZF_DEFAULT_OPTS_FILE and FZF_DEFAULT_OPTS
    test -n "$FZF_TMUX_HEIGHT"; or set -l FZF_TMUX_HEIGHT 40%
    string join ' ' -- \
      "--height $FZF_TMUX_HEIGHT --min-height=20+ --bind=ctrl-z:ignore" $argv[1] \
      (test -r "$FZF_DEFAULT_OPTS_FILE"; and string join -- ' ' <$FZF_DEFAULT_OPTS_FILE) \
      $FZF_DEFAULT_OPTS $argv[2..]
  end

  function __fzfcmd
    test -n "$FZF_TMUX_HEIGHT"; or set -l FZF_TMUX_HEIGHT 40%
    if test -n "$FZF_TMUX_OPTS"
      echo "fzf-tmux $FZF_TMUX_OPTS -- "
    else if test "$FZF_TMUX" = "1"
      echo "fzf-tmux -d$FZF_TMUX_HEIGHT -- "
    else
      echo "fzf"
    end
  end

  function __fzf_parse_commandline -d 'Parse the current command line token and return split of existing filepath, fzf query, and optional -option= prefix'
    set -l fzf_query ''
    set -l prefix ''
    set -l dir '.'

    set -l -- match_regex '(?<fzf_query>[\\s\\S]*?(?=\\n?$)$)'
    set -l -- prefix_regex '^-[^\\s=]+=|^-(?!-)\\S'

    # Don't use option prefix if " -- " is preceded.
    string match -qv -- '* -- *' (string sub -l (commandline -Cp) -- (commandline -p))
    and set -- match_regex "(?<prefix>$prefix_regex)?$match_regex"

    # Set $prefix and expanded $fzf_query with preserved trailing newlines.
    if string match -qr -- '^\\d\\d+|^[4-9]' $version
      # fish v4.0.0 and newer
      string match -q -r -- $match_regex (commandline --current-token --tokens-expanded | string collect -N)
    else
      string match -q -r -- $match_regex (commandline --current-token --tokenize | string collect -N)
      eval set -- fzf_query (string escape -n -- $fzf_query | string replace -r -a '^\\\\(?=~)|\\\\(?=\\$\\w)' '')
    end

    if test -n "$fzf_query"
      # Normalize path in $fzf_query, set $dir to the longest existing directory.
      if string match -qr -- '^\\d\\d+|^4|^3\\.[5-9]' $version
        # fish v3.5.0 and newer
        set -- fzf_query (path normalize -- $fzf_query)
        set -- dir $fzf_query
        while not path is -d $dir
          set -- dir (path dirname $dir)
        end
      else
        string match -q -r -- '(?<fzf_query>^[\\s\\S]*?(?=\\n?$)$)' \
          (string replace -r -a -- '(?<=/)/|(?<!^)/+(?!\\n)$' '' $fzf_query | string collect -N)
        set -- dir $fzf_query
        while not test -d "$dir"
          set -- dir (dirname -z -- "$dir" | string split0)
        end
      end

      if not string match -q -- '.' $dir; or string match -qr -- '^\\.(/|$)' $fzf_query
        # Strip $dir from $fzf_query - preserve trailing newlines.
        if string match -qr -- '^\\d\\d+|^[4-9]' $version
          # fish v4.0.0 and newer
          string match -q -r -- '^'(string escape --style=regex -- $dir)'/?(?<fzf_query>[\\s\\S]*)' $fzf_query
        else
          string match -q -r -- '^/?(?<fzf_query>[\\s\\S]*?(?=\\n?$)$)' \
            (string replace -- "$dir" '' $fzf_query | string collect -N)
        end
      end
    end

    string escape -n -- "$dir" "$fzf_query" "$prefix"
  end

  # Store current token in $dir as root for the 'find' command
  function fzf-file-widget -d "List files and folders"
    set -l commandline (__fzf_parse_commandline)
    set -lx dir $commandline[1]
    set -l fzf_query $commandline[2]
    set -l prefix $commandline[3]

    set -lx FZF_DEFAULT_OPTS (__fzf_defaults \
      "--reverse --walker=file,dir,follow,hidden --scheme=path" \
      "--multi $FZF_CTRL_T_OPTS --print0")

    set -lx FZF_DEFAULT_COMMAND "$FZF_CTRL_T_COMMAND"
    set -lx FZF_DEFAULT_OPTS_FILE

    set -l result (eval (__fzfcmd) --walker-root=$dir --query=$fzf_query | string split0)
    and commandline -rt -- (string join -- ' ' $prefix(string escape -n -- $result))' '

    commandline -f repaint
  end

  function fzf-history-widget -d "Show command history"
    set -l -- command_line (commandline)
    set -l -- current_line (commandline -L)
    set -l -- total_lines (count $command_line)
    set -l -- fzf_query (string escape -- $command_line[$current_line])

    set -lx -- FZF_DEFAULT_COMMAND "builtin history -z --show-time=(set_color $fish_color_comment 2>/dev/null; or set_color normal)\"%F %a %T%t%s%t\"(set_color normal)"

    # Enable syntax highlighting colors on fish v4.3.3 and newer
    if string match -qr -- '^\\d\\d+|^4\\.[4-9]|^4\\.3\\.[3-9]' $version
      set -a -- FZF_DEFAULT_COMMAND "--color=always"
    end

    set -lx -- FZF_DEFAULT_OPTS (__fzf_defaults '' \
      '--with-nth=2.. --nth=2..,.. --scheme=history --multi --no-multi-line' \
      '--no-wrap --wrap-sign="\t\t\t↳ " --preview-wrap-sign="↳ " --freeze-left=1' \
      '--bind="alt-enter:become(set -g fzf_temp {+sf3..}; string join0 -- (string split0 -- <$fzf_temp | fish_indent -i); unlink $fzf_temp &>/dev/null)"' \
      '--bind="alt-t:change-with-nth(1,3..|3..|2..)"' \
      "--bind='shift-delete:execute-silent(eval builtin history delete -Ce -- (string escape -n -- (string split0 -- <{+sf3..})))+reload($FZF_DEFAULT_COMMAND)'" \
      "--bind=ctrl-r:toggle-sort,alt-r:toggle-raw --highlight-line $FZF_CTRL_R_OPTS" \
      '--accept-nth=3.. --delimiter="\t" --tabstop=4 --ansi --read0 --print0 --with-shell='(status fish-path)\\ -c)

    # Add dynamic preview options if preview command isn't already set by user
    if string match -qvr -- '--preview[= ]' "$FZF_DEFAULT_OPTS"
      # Prepend the options to allow user overrides
      set -p -- FZF_DEFAULT_OPTS \
        '--bind="focus,multi,resize:bg-transform:if test \\"$FZF_COLUMNS\\" -gt 100 -a \\\\( \\"$FZF_SELECT_COUNT\\" -gt 0 -o \\\\( -z \\"$FZF_WRAP\\" -a (string join0 -- <{f3..} | string length) -gt (math $FZF_COLUMNS - (switch $FZF_WITH_NTH; case 2..; echo 13; case 1,3..; echo 25; case 3..; echo 1; end)) \\\\) -o (string split0 -- <{sf3..} | fish_indent | count) -gt 1 \\\\); echo show-preview; else; echo hide-preview; end"' \
        '--preview="test \\"$FZF_SELECT_COUNT\\" -gt 0; and string split0 -- <{+sf3..} | fish_indent (string match -q -- 3.\\\\* $version; or echo -- --only-indent) --ansi; and echo -n \\\\n; string collect -- \\\\#\\\\ {1} (string split0 -- <{sf3..}) | fish_indent --ansi"' \
        '--preview-window="right,50%,wrap-word,follow,info,hidden"'
    end

    set -lx FZF_DEFAULT_OPTS_FILE

    # Merge history from other sessions before searching
    test -z "$fish_private_mode"; and builtin history merge

    if set -l result (eval $FZF_DEFAULT_COMMAND \| (__fzfcmd) --query=$fzf_query | string split0)
      if test "$total_lines" -eq 1
        commandline -- $result
      else
        set -l a (math $current_line - 1)
        set -l b (math $current_line + 1)
        commandline -- $command_line[1..$a] $result
        commandline -a -- '' $command_line[$b..-1]
      end
    end

    commandline -f repaint
  end

  function fzf-cd-widget -d "Change directory"
    set -l commandline (__fzf_parse_commandline)
    set -lx dir $commandline[1]
    set -l fzf_query $commandline[2]
    set -l prefix $commandline[3]

    set -lx FZF_DEFAULT_OPTS (__fzf_defaults \
      "--reverse --walker=dir,follow,hidden --scheme=path" \
      "$FZF_ALT_C_OPTS --no-multi --print0")

    set -lx FZF_DEFAULT_OPTS_FILE
    set -lx FZF_DEFAULT_COMMAND "$FZF_ALT_C_COMMAND"

    if set -l result (eval (__fzfcmd) --query=$fzf_query --walker-root=$dir | string split0)
      cd -- $result
      commandline -rt -- $prefix
    end

    commandline -f repaint
  end

  if not set -q FZF_CTRL_R_COMMAND; or test -n "$FZF_CTRL_R_COMMAND"
    if test -n "$FZF_CTRL_R_COMMAND"
      echo "warning: FZF_CTRL_R_COMMAND is set to a custom command, but custom commands are not yet supported for CTRL-R" >&2
    end
    bind \cr fzf-history-widget
    bind -M insert \cr fzf-history-widget
  end

  if not set -q FZF_CTRL_T_COMMAND; or test -n "$FZF_CTRL_T_COMMAND"
    bind \ct fzf-file-widget
    bind -M insert \ct fzf-file-widget
  end

  if not set -q FZF_ALT_C_COMMAND; or test -n "$FZF_ALT_C_COMMAND"
    bind \ec fzf-cd-widget
    bind -M insert \ec fzf-cd-widget
  end

end

# Run setup
fzf_key_bindings
### end: key-bindings.fish ###
### completion.fish ###
#     ____      ____
#    / __/___  / __/
#   / /_/_  / / /_
#  / __/ / /_/ __/
# /_/   /___/_/ completion.fish
#
# - $FZF_COMPLETION_OPTS
# - $FZF_EXPANSION_OPTS

# The oldest supported fish version is 3.4.0. For this message being able to be
# displayed on older versions, the command substitution syntax $() should not
# be used anywhere in the script, otherwise the source command will fail.
if string match -qr -- '^[12]\\.|^3\\.[0-3]' $version
  echo "fzf completion script requires fish version 3.4.0 or newer." >&2
  return 1
else if not command -q fzf
  echo "fzf was not found in path." >&2
  return 1
end

function fzf_complete -w fzf -d 'fzf command completion and wildcard expansion search'
  # Restore the default shift-tab behavior on tab completions
  if commandline --paging-mode
    commandline -f complete-and-search
    return
  end

  # Remove any trailing unescaped backslash from token and update command line
  set -l -- token (string replace -r -- '(?<!\\\\)(?:\\\\\\\\)*\\K\\\\$' '' (commandline -t | string collect) | string collect)
  commandline -rt -- $token

  # Remove any line breaks from token
  set -- token (string replace -ra -- '\\\\\\n' '' $token | string collect)

  # regex: Match token with unescaped/unquoted glob character
  set -l -- r_glob '^(?:[^\'"\\\\*]|\\\\[\\S\\s]|\'(?:\\\\[\\S\\s]|[^\'\\\\])*\'|"(?:\\\\[\\S\\s]|[^"\\\\])*")*\\*[\\S\\s]*$'

  # regex: Match any unbalanced quote character
  set -l -- r_quote '^(?>(?:\\\\[\\s\\S]|"(?:[^"\\\\]|\\\\[\\s\\S])*"|\'(?:[^\'\\\\]|\\\\[\\s\\S])*\'|[^\'"\\\\]+)*)\\K[\'"]'

  # The expansion pattern is the token with any open quote closed, or is empty.
  set -l -- glob_pattern (string match -r -- $r_glob $token | string collect)(string match -r -- $r_quote $token | string collect -a)

  set -l -- cl_tokenize_opt '--tokens-expanded'
  string match -q -- '3.*' $version
  and set -- cl_tokenize_opt '--tokenize'

  # Set command line tokens without any leading variable definitions or launcher
  # commands (including their options, but not any option arguments).
  set -l -- r_cmd '^(?:(?:builtin|command|doas|env|sudo|\\w+=\\S*|-\\S+)\\s+)*\\K[\\s\\S]+'
  set -l -- cmd (commandline $cl_tokenize_opt --input=(commandline -pc | string match -r $r_cmd))
  test -z "$token"
  and set -a -- cmd ''

  # Set fzf options
  test -z "$FZF_TMUX_HEIGHT"
  and set -l -- FZF_TMUX_HEIGHT 40%

  set -lax -- FZF_DEFAULT_OPTS \
    "--height=$FZF_TMUX_HEIGHT --min-height=20+ --bind=ctrl-z:ignore" \
    (test -r "$FZF_DEFAULT_OPTS_FILE"; and string join -- ' ' <$FZF_DEFAULT_OPTS_FILE) \
    $FZF_DEFAULT_OPTS '--bind=alt-r:toggle-raw --multi --wrap=word --reverse' \
    (if test -n "$glob_pattern"; string collect -- $FZF_EXPANSION_OPTS; else;
      string collect -- $FZF_COMPLETION_OPTS; end; string escape -n -- $argv) \
    --with-shell=(status fish-path)\\ -c

  set -lx FZF_DEFAULT_OPTS_FILE

  set -l -- fzf_cmd fzf
  test "$FZF_TMUX" = 1
  and set -- fzf_cmd fzf-tmux $FZF_TMUX_OPTS -d$FZF_TMUX_HEIGHT --

  set -l result

  # Get the completion list from stdin when it's not a tty
  if not isatty stdin
    set -l -- custom_post_func _fzf_post_complete_$cmd[1]
    functions -q $custom_post_func
    or set -- custom_post_func _fzf_complete_$cmd[1]_post

    if functions -q $custom_post_func
      $fzf_cmd | $custom_post_func $cmd | while read -l r; set -a -- result $r; end
    else if string match -q -- '*--print0*' "$FZF_DEFAULT_OPTS"
      $fzf_cmd | while read -lz r; set -a -- result $r; end
    else
      $fzf_cmd | while read -l r; set -a -- result $r; end
    end

  # Wildcard expansion
  else if test -n "$glob_pattern"
    # Set the command to be run by fzf, so there is a visual indicator and an
    # easy way to abort on long recursive searches.
    set -lx -- FZF_DEFAULT_COMMAND "for i in $glob_pattern;" \
      'test -d "$i"; and string match -qv -- "*/" $i; and set -- i $i/;' \
      'string join0 -- $i; end'

    set -- result (string escape -n -- ($fzf_cmd --read0 --print0 --scheme=path --no-multi-line | string split0))

  # Command completion
  else
    # Call custom function if defined
    set -l -- custom_func _fzf_complete_$cmd[1]
    if functions -q $custom_func; and not set -q __fzf_no_custom_complete
      set -lx __fzf_no_custom_complete
      $custom_func $cmd
      return
    end

    # Workaround for complete not having newlines in results
    if string match -qr -- '\\n' $token
      set -- token (string replace -ra -- '(?<!\\\\)(?:\\\\\\\\)*\\K\\\\\$' '\\\\\\\\\$' $token | string collect)
      set -- token (string unescape -- $token | string collect)
      set -- token (string replace -ra -- '\\n' '\\\\n' $token | string collect)
    end

    set -- list (complete -C --escape -- (string join -- ' ' (commandline -pc $cl_tokenize_opt) $token | string collect))
    if test -n "$list"
      # Get the initial tabstop value
      if set -l -- tabstop (string match -rga -- '--tabstop[= ](?:0*)([1-9]\\d+|[4-9])' "$FZF_DEFAULT_OPTS")[-1]
        set -- tabstop (math $tabstop - 4)
      else
        set -- tabstop 4
      end

      # Determine the tabstop length for description alignment
      set -l -- max_columns (math $COLUMNS - 40)
      for i in $list[1..500]
        set -l -- item (string split -f 1 -- \t $i)
        and set -l -- len (string length -V -- $item)
        and test "$len" -gt "$tabstop" -a "$len" -lt "$max_columns"
        and set -- tabstop $len
      end
      set -- tabstop (math $tabstop + 4)

      set -- result (string collect -- $list | $fzf_cmd --delimiter="\t" --tabstop=$tabstop --wrap-sign=\t"↳ " --accept-nth=1)
    end
  end

  # Update command line
  if test -n "$result"
    # No extra space after single selection that ends with path separator
    set -l -- tail ' '
    test (count $result) -eq 1
    and string match -q -- '*/' "$result"
    and set -- tail ''

    commandline -rt -- (string join -- ' ' $result)$tail
  end

  commandline -f repaint
end

function _fzf_complete
  set -l fzf_args
  for i in $argv
    string match -q -- '--' $i; and break
    set -a -- fzf_args $i
  end
  fzf_complete $fzf_args
end

# Bind to shift-tab
if string match -qr -- '^\\d\\d+|^[4-9]' $version
  bind shift-tab fzf_complete
  bind -M insert shift-tab fzf_complete
else
  bind -k btab fzf_complete
  bind -M insert -k btab fzf_complete
end
### end: completion.fish ###
