<p align="center">
  <img src="https://santoku.dev/logo-santoku-system.png" height="64" alt="santoku-system">
</p>

# santoku-system

Process spawning and POSIX glue. Fork a program, or a Lua function, across one or more
jobs and stream its output back as an iterator. Exit status arrives as part of the stream
rather than as a separate call. Built on `fork`, `pipe`, `poll` and `execvp`.

## Install

```sh
luarocks install santoku-system
```

## Example

```lua
local sys = require("santoku.system")

for line in sys.sh({ "git", "log", "--oneline", "-5" }) do
  print(line)
end
```

## Documentation

Runnable examples and the full API: [santoku.dev](https://santoku.dev/#santoku-system).

For agents and LLM tooling: [llms.txt](https://santoku.dev/llms.txt) for the index,
[llms-full.txt](https://santoku.dev/llms-full.txt) for every documented example.

## Tests

The tests are the spec. For the exhaustive surface, read them:
[`test/spec/santoku/system.lua`](test/spec/santoku/system.lua).

## License

MIT, see [LICENSE](LICENSE).

## More examples

```lua
local test = require("santoku.test")

local err = require("santoku.error")
local assert = err.assert

local tbl = require("santoku.table")
local teq = tbl.equals

local arr = require("santoku.array")
local imap = arr.imap
local apack = arr.pack

local sys = require("santoku.system")

test("read a command's output line by line", function ()
  local lines = sys.sh({ "sh", "-c", "echo a; echo b" })
  assert(teq({ { "a" }, { "b" } }, imap(apack, lines)))
end)

test("set environment variables for the child process", function ()
  local out = sys.pread({
    "sh", "-c", "echo $GREETING",
    env = { GREETING = "hello" }, bufsize = 500
  })
  assert(teq({
    { "stdout", "hello\n" },
    { "exit", "exited", 0 },
  }, imap(function (kind, _, ...)
    return { kind, ... }
  end, out)))
end)

test("the exit status is reported as part of the stream", function ()
  assert(teq({
    { "exit", "exited", 7 },
  }, imap(function (kind, _, ...)
    return { kind, ... }
  end, sys.pread({ "sh", "-c", "exit 7", stdout = false }))))
end)
```
