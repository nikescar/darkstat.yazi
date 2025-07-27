local M = {}

-- Helper to get all log files matching the pattern
local function get_log_files()
  local handle = io.popen("ls /var/log/darkstat/hl*.log 2>/dev/null")
  if not handle then return {} end
  local result = {}
  for file in handle:lines() do
    table.insert(result, file)
  end
  handle:close()
  return result
end

-- Helper to run a shell command and capture output
local function run_cmd(cmd)
  local handle = io.popen(cmd)
  if not handle then return "" end
  local result = handle:read("*a")
  handle:close()
  return result
end

-- Main entry point for the plugin
function M.preview()
  -- 1st column: list log files
  local log_files = get_log_files()
  if #log_files == 0 then
    print("No darkstat logs found.")
    return
  end

  print("=== [1] Log Files ===")
  for i, file in ipairs(log_files) do
    print(string.format("%d. %s", i, file))
  end

  io.write("\nSelect log file number: ")
  local sel = tonumber(io.read())
  local selected_file = log_files[sel]
  if not selected_file then
    print("Invalid selection.")
    return
  end

  -- 2nd column: IP lookup
  print("\n=== [2] IP Info ===")
  local ip_cmd = string.format("cat '%s' | awk -F'\\|' '{print $1}' | xargs cdn-lookup | sort", selected_file)
  local ip_info = run_cmd(ip_cmd)
  print(ip_info)

  io.write("\nEnter IP to inspect: ")
  local ip = io.read()
  if not ip or ip == "" then
    print("No IP entered.")
    return
  end

  -- 3rd column: Connection info
  print("\n=== [3] Connection Info ===")
  -- Find the latest vector log file (adjust pattern as needed)
  local vector_log = run_cmd("ls -t /var/log/vector/raw_connections_*.log 2>/dev/null | head -n1"):gsub("\n", "")
  if vector_log == "" then
    print("No vector log found.")
    return
  end
  local conn_cmd = string.format("cat '%s' | grep '%s' | awk '{ print $4 }' | uniq | tr '\\r' ' '", vector_log, ip)
  local conn_info = run_cmd(conn_cmd)
  print(conn_info)
end

return M