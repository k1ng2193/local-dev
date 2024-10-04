return {
	"ldelossa/gh.nvim",
	dependencies = {
		{
			"ldelossa/litee.nvim",
			config = function()
				require("litee.lib").setup()
			end,
		},
	},
	config = function()
		require("litee.gh").setup()

		local wk = require("which-key")
		wk.add({
			{ "<leader>g", group = "Git" },
			{ "<leader>gh", group = "Github" },
			{ "<leader>ghc", group = "Commits" },
			{ "<leader>ghcc", "<cmd>GHCloseCommit<cr>", desc = "Close", mode = "n" },
			{ "<leader>ghce", "<cmd>GHExpandCommit<cr>", desc = "Expand", mode = "n" },
			{ "<leader>ghco", "<cmd>GHOpenToCommit<cr>", desc = "Open To", mode = "n" },
			{ "<leader>ghcp", "<cmd>GHPopOutCommit<cr>", desc = "Pop Out", mode = "n" },
			{ "<leader>ghcz", "<cmd>GHCollapseCommit<cr>", desc = "Collapse", mode = "n" },
			{ "<leader>ghi", group = "Issues" },
			{ "<leader>ghip", "<cmd>GHPreviewIssue<cr>", desc = "Preview", mode = "n" },
			{ "<leader>ghl", group = "Litee" },
			{ "<leader>ghlt", "<cmd>LTPanel<cr>", desc = "Toggle Panel", mode = "n" },
			{ "<leader>ghp", group = "Pull Request" },
			{ "<leader>ghpd", "<cmd>GHPRDetails<cr>", desc = "Details", mode = "n" },
			{ "<leader>ghpe", "<cmd>GHExpandPR<cr>", desc = "Expand", mode = "n" },
			{ "<leader>ghpo", "<cmd>GHOpenPR<cr>", desc = "Open", mode = "n" },
			{ "<leader>ghpp", "<cmd>GHPopOutPR<cr>", desc = "PopOut", mode = "n" },
			{ "<leader>ghpr", "<cmd>GHRefreshPR<cr>", desc = "Refresh", mode = "n" },
			{ "<leader>ghpt", "<cmd>GHOpenToPR<cr>", desc = "Open To", mode = "n" },
			{ "<leader>ghpx", "<cmd>GHClosePR<cr>", desc = "Close", mode = "n" },
			{ "<leader>ghpz", "<cmd>GHCollapsePR<cr>", desc = "Collapse", mode = "n" },
			{ "<leader>ghr", group = "Review" },
			{ "<leader>ghrb", "<cmd>GHStartReview<cr>", desc = "Begin", mode = "n" },
			{ "<leader>ghrc", "<cmd>GHCloseReview<cr>", desc = "Close", mode = "n" },
			{ "<leader>ghrd", "<cmd>GHDeleteReview<cr>", desc = "Delete", mode = "n" },
			{ "<leader>ghre", "<cmd>GHExpandReview<cr>", desc = "Expand", mode = "n" },
			{ "<leader>ghrs", "<cmd>GHSubmitReview<cr>", desc = "Submit", mode = "n" },
			{ "<leader>ghrz", "<cmd>GHCollapseReview<cr>", desc = "Collapse", mode = "n" },
			{ "<leader>ght", group = "Threads" },
			{ "<leader>ghtc", "<cmd>GHCreateThread<cr>", desc = "Create", mode = "n" },
			{ "<leader>ghtn", "<cmd>GHNextThread<cr>", desc = "Next", mode = "n" },
			{ "<leader>ghtt", "<cmd>GHToggleThread<cr>", desc = "Toggle", mode = "n" },
		})
	end,
}
