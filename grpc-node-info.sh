wget -O - https://raw.githubusercontent.com/lamat1111/quilibrium-node-auto-installer/master/installer-gRPC-calls | bash

cd ~/ceremonyclient/node && GOEXPERIMENT=arenas go run ./... -node-info
