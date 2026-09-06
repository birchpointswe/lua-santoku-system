<p align="center">
  <img src="https://santoku.dev/logo-santoku-system.png" height="64" alt="santoku-system">
</p>

# santoku-system

Process spawning and POSIX glue. Fork a program, or a Lua function, across one or more
jobs and stream its output back as an iterator. Exit status arrives as part of the stream
rather than as a separate call. Built on `fork`, `pipe`, `poll` and `execvp`.

## Documentation

Runnable examples and the full API: [santoku.dev](https://santoku.dev/#santoku-system).

For agents and LLM tooling: [llms.txt](https://santoku.dev/llms.txt) for the index,
[llms-full.txt](https://santoku.dev/llms-full.txt) for every documented example.

## License

MIT, see [LICENSE](LICENSE).

