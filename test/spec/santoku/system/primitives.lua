local test = require("santoku.test")

local err = require("santoku.error")
local assert = err.assert

local vdt = require("santoku.validate")
local isnumber = vdt.isnumber

local sys = require("santoku.system")

test("posix primitives", function ()

  test("get_num_cores returns a positive integer", function ()
    local n = sys.get_num_cores()
    assert(isnumber(n))
    assert(n >= 1)
  end)

  test("pid and ppid return integers", function ()
    assert(isnumber(sys.pid()))
    assert(isnumber(sys.ppid()))
  end)

  test("mutex runs a function under a lock", function ()
    if not sys.mutex then
      return
    end
    local lock = sys.mutex()
    local a, b = lock(function () return 1, 2 end)
    assert(a == 1)
    assert(b == 2)
  end)

end)
