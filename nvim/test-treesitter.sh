#!/bin/bash
# Test treesitter installation
echo "Opening nvim to install parsers..."
echo "This will take about 30 seconds."
echo "When nvim opens, press :qa and Enter to exit."
nvim +'TSUpdate' ~/.config/README.md
