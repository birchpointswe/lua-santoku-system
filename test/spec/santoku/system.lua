local test = require("santoku.test")
local serialize = require("santoku.serialize") -- luacheck: ignore

local err = require("santoku.error")
local assert = err.assert

local tbl = require("santoku.table")
local teq = tbl.equals

local arr = require("santoku.array")
local imap = arr.imap
local apack = arr.pack

local sys = require("santoku.system")

test("pread", function ()

  test("should provide a chunked iterator for a forked processes stout and stderr", function ()

    local it = sys.pread({
      "sh", "-c", "echo a; sleep 1; echo b >&2; exit 1",
      bufsize = 500,
      stderr = true,
    })

    assert(teq({
      { "stdout", "a\n" },
      { "stderr", "b\n" },
      { "exit", "exited", 1 },
    }, imap(function (t, _, ...)
      return { t, ... }
    end, it)))

  end)

end)

test("sh", function ()

  test("should provide a line-buffered iterator for a forked processes stout", function ()

    local it = sys.sh({ "sh", "-c", "echo a; echo b; exit 0" })

    assert(teq({
      { "a" },
      { "b" },
    }, imap(apack, it)))

  end)

  test("should work with longer outputs", function ()

    local it = sys.sh({ "sh", "-c", "echo the quick brown fox; echo jumped over the lazy dog; exit 0" })

    assert(teq({
      { "the quick brown fox" },
      { "jumped over the lazy dog" },
    }, imap(apack, it)))

  end)

  test("keeps blank lines in the middle and at the end", function ()
    local it = sys.sh({ "sh", "-c", "printf 'a\\n\\n\\nb\\n\\n'" })
    assert(teq({ { "a" }, { "" }, { "" }, { "b" }, { "" } }, imap(apack, it)))
  end)

  test("a final newline ends the last line without adding an empty one", function ()
    assert(teq({ { "x" } }, imap(apack, sys.sh({ "sh", "-c", "printf 'x\\n'" }))))
    assert(teq({ { "x" } }, imap(apack, sys.sh({ "sh", "-c", "printf 'x'" }))))
  end)

  test("keeps a blank line split across reads", function ()
    local it = sys.sh({ "sh", "-c", "printf 'a\\n'; sleep 0.2; printf '\\nb\\n'" })
    assert(teq({ { "a" }, { "" }, { "b" } }, imap(apack, it)))
  end)

  test("skip_blank drops blank lines", function ()
    local it = sys.sh({ "sh", "-c", "printf 'a\\n\\n\\nb\\n\\n'", skip_blank = true })
    assert(teq({ { "a" }, { "b" } }, imap(apack, it)))
  end)

  test("jobs mode keeps each child's blank lines", function ()
    local it = sys.sh({ jobs = 2, "sh", "-c", "printf 'a\\n\\nb\\n'" })
    local r = arr.sort(imap(function (l) return l end, it))
    assert(teq({ "", "", "a", "a", "b", "b" }, r))
  end)

  test("should support multi-processing", function ()

    local it = sys.pread({
      jobs = 4, job_var = "JOB",
      "sh", "-c", "echo $JOB"
    })

    local r = arr.sort(imap(function (t, _, ...)
      return { t, ... }
    end, it), function (a, b)
      return a[2] < b[2]
    end)

    assert(teq({
      { "stdout", "1\n" },
      { "stdout", "2\n" },
      { "stdout", "3\n" },
      { "stdout", "4\n" },
      { "exit", "exited", 0 },
      { "exit", "exited", 0 },
      { "exit", "exited", 0 },
      { "exit", "exited", 0 }
    }, r))

  end)

  test("should support multi-processing with line chunking", function ()

    local it = sys.sh({
      jobs = 4,
      "sh", "-c", "echo 1"
    })

    local r = arr.sort(imap(apack, it), function (a, b)
      return a[1] > b[1]
    end)

    assert(teq({
      { "1" },
      { "1" },
      { "1" },
      { "1" },
    }, r))

  end)

  test("should suppport multi-processing without exec", function ()

    local it = sys.sh({
      jobs = 4, fn = function (job)
        print(job)
      end
    })

    local r = arr.sort(imap(apack, it), function (a, b)
      return a[1] < b[1]
    end)

    assert(teq({
      { "1" },
      { "2" },
      { "3" },
      { "4" },
    }, r))

  end)

end)

test("should setenv", function ()

  local it = sys.pread({
    "sh", "-c", "echo $HELLO",
    env = { HELLO = "Hello, World!" }, bufsize = 500
  })

  assert(teq({
    { "stdout", "Hello, World!\n" },
    { "exit", "exited", 0 },
  }, imap(function (t, _, ...)
    return { t, ... }
  end, it)))

end)

test("file not found", function ()
  assert(teq({
    {
      "stderr",
      "Error in exec for: __not_a_program__: No such file or directory: 2\n"
    },
    {
      "exit",
      "exited",
      1
    }
  }, imap(function (t, _, ...)
    return { t, ... }
  end, sys.pread({ "__not_a_program__", stderr = true }))))
end)

test("stream closing before its sibling", function ()
  assert(teq({
    { "stderr", "tail\n" },
    { "exit", "exited", 3 },
  }, imap(function (t, _, ...)
    return { t, ... }
  end, sys.pread({
    "sh", "-c", "exec 1>&-; sleep 0.5; echo tail >&2; exit 3",
    bufsize = 500, stderr = true,
  }))))
end)

test("descriptors released to the caller", function ()

  local a, b = sys.pipe()
  sys.close(a)
  sys.close(b)

  local it = sys.pread({ "sh", "-c", "echo x; echo y >&2", stderr = true })
  while it() do end

  local c, d = sys.pipe()
  sys.close(c)
  sys.close(d)

  assert(c == a)
  assert(d == b)

end)

test("exit reported without any watched stream", function ()
  assert(teq({
    { "exit", "exited", 7 },
  }, imap(function (t, _, ...)
    return { t, ... }
  end, sys.pread({ "sh", "-c", "exit 7", stdout = false }))))
end)

test("sleep", function ()
  sys.sleep(0.25)
end)
