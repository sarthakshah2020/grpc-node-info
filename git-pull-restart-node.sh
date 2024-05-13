tmux kill-session -t quil

cd ceremonyclient/node

git pull

cd ceremonyclient/node 
tmux new-session -s quil

GOEXPERIMENT=arenas go run ./...
