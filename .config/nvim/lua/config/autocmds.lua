vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
	callback = function(event)
		local map = function(keys, func, desc)
			vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
		end

		map("K", vim.lsp.buf.hover, "Hover Window")
		map("gD", vim.lsp.buf.declaration, "Go To Declaration")
		map("<leader>v", "<CMD>vsplit | lua vim.lsp.buf.definition()<CR>", "Go To Definition in Vertical Split")
		map("gs", vim.lsp.buf.signature_help, "Signature Help")
		map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
		map("gl", vim.diagnostic.open_float, "Code Action")
		map("[d", function()
			vim.diagnostic.jump({ count = -1, float = true, wrap = true })
		end, "Go To Previous Diagnostic")
		map("]d", function()
			vim.diagnostic.jump({ count = 1, float = true, wrap = true })
		end, "Go To Next Diagnostic")
		map("<leader>rs", ":LspRestart<CR>", "Restart")

		-- opts.desc = "Go To Definition"
		-- keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

		-- opts.desc = "Go To Implementation"
		-- keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
		--
		-- opts.desc = "Go To Type Definition"
		-- keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)
		--
		-- opts.desc = "Go To References"
		-- keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)

		-- opts.desc = "Show Buffer Diagnostics"
		-- keymap.set("n", "bd", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

		local function client_supports_method(client, method, bufnr)
			if vim.fn.has("nvim-0.11") == 1 then
				return client:supports_method(method, bufnr)
			else
				return client:supports_method(method, { bufnr = bufnr })
			end
		end

		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if
			client
			and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
		then
			local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })

			-- When cursor stops moving: Highlights all instances of the symbol under the cursor
			-- When cursor moves: Clears the highlighting
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.clear_references,
			})

			-- When LSP detaches: Clears the highlighting
			vim.api.nvim_create_autocmd("LspDetach", {
				group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
				callback = function(eventTwo)
					vim.lsp.buf.clear_references()
					vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = eventTwo.buf })
				end,
			})
		end

		-- if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_completion, event.buf) then
		-- 	vim.opt.completeopt = { "menu", "menuone", "preview", "noinsert", "noselect", "fuzzy", "popup" }
		-- 	vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
		-- end
	end,
})
