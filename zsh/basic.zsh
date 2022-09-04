# Set default shell editor
export EDITOR='nvim'

# Pager config
export PAGER="less"
export LESS="-R"

# Disable need to escape ^ characters
setopt NO_NOMATCH

# Override default WORDCHARS to exclude /
export WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# Set the default PostgreSQL host
export PGHOST=localhost

# Disable r zsh builtin
disable r
