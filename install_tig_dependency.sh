sudo apt update && \
sudo apt install -y curl tmux git libssl-dev pkg-config && \
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
source $HOME/.cargo/env

sudo apt install build-essential

git clone https://github.com/tig-foundation/tig-monorepo.git

cd tig-monorepo
