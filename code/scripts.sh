### (p)ackage{cargo silimar commands}

# actively rebuild project on src/ code change, run the crate, use testfile as input to program
alias prun='cargo-watch -w src/ -x "run -- src/testfile"'
