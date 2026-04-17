local env = {
  name = "santoku-system",
  version = "0.0.62-1",
  variable_prefix = "TK_SYSTEM",
  license = "MIT",
  public = true,
  cflags = { "-pthread", "-I$(shell luarocks show santoku --rock-dir)/include/", },
  ldflags = { "-pthread", "$(shell uname -s | grep -q Linux && echo '-lrt')" },
  dependencies = {
    "lua == 5.1",
    "santoku >= 0.0.310-1",
  },
}

env.homepage = "https://github.com/birchpointswe/lua-" .. env.name
env.tarball = env.name .. "-" .. env.version .. ".tar.gz"
env.download = env.homepage .. "/releases/download/" .. env.version .. "/" .. env.tarball

return {
  env = env,
}
