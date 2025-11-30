vim.api.nvim_create_user_command("CleanAndRestartLsp", function()
  local current = vim.api.nvim_get_current_buf()

  -- Delete all buffers EXCEPT current
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  vim.defer_fn(function()
    vim.cmd("LspRestart")
  end, 200)
end, {})

vim.api.nvim_create_user_command("Tunnel", function()
  vim.ui.input({
    prompt = "EC2 User: ",
    default = "ec2-user@18.191.127.59",
  }, function(host)
    if not host or host == "" then
      vim.notify("EC2 ID/IP Address required", vim.log.levels.ERROR)
      return
    end

    vim.ui.input({
      prompt = "RDS Host: ",
      default = "referendum-prod-db.crmi4muqo6ag.us-east-2.rds.amazonaws.com",
    }, function(rds)
      if rds == nil or rds == "" then
        vim.notify("RDS host required", vim.log.levels.ERROR)
        return
      end

      vim.ui.input({
        prompt = "Source Port: ",
        default = "5432",
      }, function(src_port)
        if src_port == nil or src_port == "" then
          vim.notify("Source port required", vim.log.levels.ERROR)
          return
        end

        vim.ui.input({
          prompt = "Local Port: ",
          default = "9090",
        }, function(local_port)
          if local_port == nil or local_port == "" then
            vim.notify("Port required", vim.log.levels.ERROR)
            return
          end

          local existing = vim.fn.system("lsof -ti :" .. local_port):gsub("%s+", "")
          if existing ~= "" then
            vim.notify("⚠️  Port " .. local_port .. " already in use (PID: " .. existing .. ")", vim.log.levels.WARN)
            return
          end

          local pem_files = vim.fn.glob(vim.fn.expand("~/.ssh") .. "/*.pem", false, true)

          if #pem_files == 0 then
            vim.notify("No .pem files found in ~/.ssh", vim.log.levels.WARN)
            return
          end

          vim.ui.select(pem_files, {
            prompt = "Select SSH Key: ",
            format_item = function(item)
              return vim.fn.fnamemodify(item, ":t")
            end,
          }, function(key)
            if key == nil or key == "" then
              vim.notify("SSH key required", vim.log.levels.ERROR)
              return
            end

            vim.notify("🚀 Starting tunnel on port " .. local_port .. "...")

            local tunnel = local_port .. ":" .. rds .. ":" .. src_port
            vim.fn.jobstart({ "ssh", "-i", key, "-f", "-N", "-L", tunnel, host }, {
              on_exit = function(_, exit_code)
                if exit_code == 0 then
                  vim.defer_fn(function()
                    local pid = vim.fn.system("lsof -ti :" .. local_port):gsub("%s+", "")

                    if pid ~= "" then
                      vim.notify("✅ Tunnel established on localhost:" .. local_port .. " (PID: " .. pid .. ")")
                    else
                      vim.notify("⚠️  Tunnel command succeeded but not detected", vim.log.levels.WARN)
                    end
                  end, 500)
                else
                  vim.notify("❌ Failed to establish tunnel (exit code: " .. exit_code .. ")", vim.log.levels.ERROR)
                end
              end,

              on_stderr = function(_, data)
                if data and #data > 0 then
                  local error_msg = table.concat(data, "\n"):gsub("^%s*(.-)%s*$", "%1")
                  if error_msg ~= "" then
                    vim.notify("SSH Error: " .. error_msg, vim.log.levels.ERROR)
                  end
                end
              end,
            })
          end)
        end)
      end)
    end)
  end)
end, {})

vim.api.nvim_create_user_command("TunnelStop", function()
  vim.ui.input({
    prompt = "Port: ",
    default = "9090",
  }, function(port)
    if not port or port == "" then
      vim.notify("Port required", vim.log.levels.ERROR)
      return
    end

    vim.notify("🔍 Looking for SSH tunnel on port " .. port .. "...")

    vim.fn.jobstart("lsof -ti :" .. port, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        local pid = data[1]

        if not pid or pid == "" then
          vim.notify("❌ No tunnel found on port " .. port, vim.log.levels.WARN)
          return
        end

        vim.notify("🛑 Stopping tunnel (PID: " .. pid .. ")...")

        -- Kill gracefully
        vim.fn.jobstart("kill " .. pid, {
          on_exit = function()
            -- Wait 1 second then check
            vim.defer_fn(function()
              -- Check if still running
              vim.fn.jobstart("lsof -i :" .. port, {
                on_exit = function(_, exit_code)
                  if exit_code ~= 0 then
                    -- Not found (tunnel closed)
                    vim.notify("✅ Tunnel closed")
                  else
                    -- Still running, force kill
                    vim.notify("⚠️  Force killing...")
                    vim.fn.jobstart("kill -9 " .. pid, {
                      on_exit = function()
                        vim.notify("✅ Tunnel force closed")
                      end,
                    })
                  end
                end,
              })
            end, 1000)
          end,
        })
      end,
    })
  end)
end, {})

vim.api.nvim_create_user_command("TunnelStatus", function()
  vim.notify("🔍 Active SSH Tunnels:")

  local tunnels = vim.fn.systemlist("ps aux | grep 'ssh.*-L' | grep -v grep")

  if #tunnels == 0 then
    print("  No SSH tunnels found")
  else
    for _, line in ipairs(tunnels) do
      print("  " .. line)
    end
  end
end, {})
