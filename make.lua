-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2023 Birch Point SWE
local rock = require("santoku.make.rock")

local env = {
  name = "santoku-system",
  version = "2.1.1-1",
  variable_prefix = "TK_SYSTEM",
  license = "MIT",
  copyright = "Birch Point SWE",
  vendored = {
    {
      name = "luaposix poll.c",
      path = { "res/vendor/luaposix/poll.c" },
      copyright = "(C) 2006-2023 luaposix authors",
      license = "MIT",
      note = "From https://github.com/luaposix/luaposix, inlined into santoku.system.posix.poll.",
    },
  },
  public = true,
  cflags = { "-pthread", rock.include("santoku"), },
  ldflags = { "-pthread", "$(shell uname -s | grep -q Linux && echo '-lrt')" },
  dependencies = {
    "lua == 5.1",
    "santoku >= 2.0.0, < 3.0.0",
  },
  test = {
    dependencies = {
      "santoku-fs >= 2.0.0, < 3.0.0",
    },
  },
}

env.homepage = "https://github.com/birchpointswe/lua-" .. env.name
env.tarball = env.name .. "-" .. env.version .. ".tar.gz"
env.download = env.homepage .. "/releases/download/" .. env.version .. "/" .. env.tarball

return {
  env = env,
}
