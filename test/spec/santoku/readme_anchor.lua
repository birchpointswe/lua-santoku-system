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
