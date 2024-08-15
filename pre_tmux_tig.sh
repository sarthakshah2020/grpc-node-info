sudo apt update && \
sudo apt install -y curl tmux git libssl-dev pkg-config && \
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
source $HOME/.cargo/env

sudo apt install build-essential

git clone https://github.com/tig-foundation/tig-monorepo.git

cd tig-monorepo

read -p "Enter ACCOUNT: " ACCOUNT
read -p "Enter API: " API
read -p "Enter the number of WORKERS: " WORKERS

echo "ACCOUNT="$ACCOUNT"" > .env
echo "API="$API"" >> .env
echo "WORKERS="$WORKERS"" >> .env
