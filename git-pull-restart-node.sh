tmux kill-session -t quil

cd ceremonyclient/node

git pull

tmux new-session -s quil

GOEXPERIMENT=arenas go run ./...
