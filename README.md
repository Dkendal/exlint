# Exlint

Elixir syntax checker.

## Why should I use this

`elixirc` executes all function calls in the top level scope. This means that all elixir files, not just `.exs` are treated as executables by the compiler.

This is an intentional design, and nessicary for the macro system to work.

Becaused of this compiling a file, like the example below, can have destructive operations on the filesystem.

```elixir
File.write("sup", "sup")

defmodule Foo do
end
```
_Compiling this file results in a file called `sup` being written to the current working directory.

A further discussion is available [here](https://elixirforum.com/t/why-does-the-compilation-of-modules-also-execute-code/6137)

[Previous syntax checking plugins for elixir](https://github.com/vim-syntastic/syntastic/issues/1141) were removed because of this behaviour.

`exlint` which reports syntax problems, without executing code in the top level block, however this can't guard against destructive operations in macros.

It works by removing everything from the ast in the top level that isn't a definition, import, or alias before compilitation.

You can intergrate it into vim and ale with something like the following:

```vim
function! ExlintCallback(buffer, lines)
  " Matches patterns line the following:
  "
  " lib/filename.ex:19:7: F: Pipe chain should start with a raw value.
  "
  " lib/battle_snake/game_server/server.ex:251:1:4: E: unexpected token: end

  let l:patterns = [
        \ '\v:(\d+):?(\d+)?:?(\d+)?: (.): (.+)$',
        \ ]

  let l:output = []

  for l:match in ale#util#GetMatches(a:lines, l:patterns)
    let l:type = l:match[4]
    let l:text = l:match[5]

    call add(l:output, {
          \   'bufnr': a:buffer,
          \   'lnum': l:match[1] + 0,
          \   'col': l:match[2] + 0,
          \   'end_col': l:match[3] + 0,
          \   'type': l:type,
          \   'text': l:text,
          \})
  endfor

  return l:output
endfunction

function! ExlintCommand(buffer)
  return "exlint %s"
endfunction

call ale#linter#Define('elixir', {
      \   'name': 'elixir',
      \   'executable': 'exlint',
      \   'command_callback': 'ExlintCommand',
      \   'callback': 'ExlintCallback',
      \})
```
