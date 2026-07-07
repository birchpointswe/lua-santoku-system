# santoku-system

Process spawning and POSIX glue for Lua: fork a program (or a Lua function) across one or
more jobs, stream its stdout/stderr back as an iterator, and coordinate workers with shared
counters and locks. Built on `fork`/`pipe`/`poll`/`execvp`.

This README is a usage guide, not an API reference. **The tests are the spec**: each
section points at the test that exercises the full surface.

This library depends on base `santoku` (`array`/`error`/`string` and friends); see the
[santoku README](../lua-santoku/README.md). It does not re-explain that surface.

## Layout

| Module | Role | Anchor test |
|--------|------|-------------|
| `santoku.system` | entry point: merges `pread`/`sh`/`execute` with `posix` and `os` | `system.lua` |
| `santoku.system.pread` | spawn jobs, stream raw chunked `stdout`/`stderr`/`exit` events | `system.lua` |
| `santoku.system.sh` | `pread` wrapped to yield whole output lines | `system.lua` |
| `santoku.system.posix` | C bindings: `fork`/`pipe`/`read`/`wait`/`execp`/`sleep`/`atom`/`mutex`/... | `system.lua`, `system/parallel.lua` |
| `santoku.system.posix.poll` | C `poll(2)` wrapper over an fd to event table | (used by `pread`) |

`require("santoku.system")` returns everything from `posix` and `os` plus `pread`, `sh`,
and `execute`, so `sys.sleep`, `sys.fork`, `sys.get_num_cores`, and `os.getenv` are all on
the one table.

## Spawning and the options table

`pread` and `sh` take a single options table. The positional entries are the program and
its arguments; the named entries configure the run:

- `[1], [2], ...`: program path and argv (passed to `execvp`).
- `fn`: a Lua function `fn(job, opts)` to run in the child instead of a program. The child
  exits 0 on return, 1 on error.
- `jobs`: number of parallel children (default 1). Each child sees its index as `job`.
- `job_var`: env var name set to the job index in each child (e.g. `"JOB"`).
- `env`: table of environment variables to `setenv` in each child.
- `stdout`: capture stdout (default true). `stderr`: capture stderr (default false).
- `bufsize`: per-read byte budget (default `posix.BUFSIZ`).

## `pread`: raw event stream

`pread(opts)` returns an iterator. Each call yields an event tuple: `"stdout"`/`"stderr"`
with `(pid, data)` where `data` is a raw chunk (not line-aligned), or `"exit"` with
`(pid, reason, status)` where `reason` is `"exited"`/`"signaled"`/`"stopped"`. The iterator
ends (returns nil) once every child has been reaped.

```lua
local sys = require("santoku.system")

local it = sys.pread({
  "sh", "-c", "echo a; sleep 1; echo b >&2; exit 1",
  bufsize = 500,
  stderr = true,
})

for ev, pid, a, b in it do
  -- { "stdout", pid, "a\n" }, { "stderr", pid, "b\n" }, { "exit", pid, "exited", 1 }
end
```

## `sh`: line-buffered output

`sh(opts)` wraps `pread` and yields whole output lines as plain strings, buffering partial
chunks across reads and splitting on newlines. It raises if any child exits non-zero.

```lua
local sys = require("santoku.system")

for line in sys.sh({ "sh", "-c", "echo a; echo b; exit 0" }) do
  -- "a", then "b"
end
```

`execute(opts)` is `sh` in execute mode; it prints each line and returns.

## Parallel jobs  ·  `test/spec/santoku/system/parallel.lua`

Set `jobs > 1` to fork that many workers. With a program, `job_var` lets each child branch
on its index; with `fn`, the worker is a Lua closure. Output from all children interleaves
through the one iterator.

```lua
local sys = require("santoku.system")

-- map a function over 4 workers; collect their line output
for line in sys.sh({
  jobs = 4,
  fn = function (job) print(job) end,
}) do
  -- "1".."4" in completion order
end
```

To share state across workers, `posix.atom(initial[, throttle])` returns a callable backed
by POSIX shared memory and a semaphore: each call atomically returns the old value and adds
its argument (default 1), so workers can pull from a shared queue. `posix.mutex()` returns a
callable that runs a function under a semaphore. Both are platform-gated
(`#ifndef __ANDROID__`); guard with `if sys.atom then ... end`, as `parallel.lua` does.

```lua
local sys = require("santoku.system")
if sys.atom then
  local next_i = sys.atom(1)
  -- inside each worker: local i = next_i()  -- 1, 2, 3, ... across all jobs
end
```

## POSIX bindings

`santoku.system.posix` exposes the calls the spawners are built from, plus standalone
utilities: `fork`, `pipe`, `close`, `read(fd, size)`, `execp(prog, argv)`,
`wait(pid)`, `setenv(k, v)`, `sleep(seconds)` (fractional), `pid()`, `ppid([pid])`,
`get_num_cores()`, `time()`, and the `BUFSIZ` constant. Errors raise with the underlying
`errno`. `santoku.system.posix.poll` is the `poll(2)` wrapper used internally to multiplex
child pipes.

## Building / testing

This repo uses the `toku` build harness. Tests live in `test/spec/santoku/`. The C
extensions (`posix`, `posix.poll`) are built by the harness, so run the suite through `toku`
to compile the natives and put them on the path.

## License

Copyright 2025 Birch Point SWE

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
