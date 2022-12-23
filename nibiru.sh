#!/bin/bash

#Define constants
NIBIRU_PORT=27
echo "export NODENAME=$NODENAME" >> $HOME/.bash_profile
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export NIBIRU_CHAIN_ID=nibiru-testnet-2" >> $HOME/.bash_profile
echo "export NIBIRU_PORT=${NIBIRU_PORT}" >> $HOME/.bash_profile
source $HOME/.bash_profile

#update system and instal packages
sudo apt update && sudo apt upgrade
sudo apt install curl build-essential git wget jq make gcc tmux chrony -y

if ! [ -x "$(command -v go)" ]; then
  ver="1.18.4"
  cd $HOME
  wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
  rm "go$ver.linux-amd64.tar.gz"
  echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
  source ~/.bash_profile
fi

#download and build binaries

cd $HOME && rm -rf nibiru
git clone https://github.com/NibiruChain/nibiru.git
cd nibiru
git checkout v0.16.2
make install

#settings

nibid init $NODENAME --chain-id=$NIBIRU_CHAIN_ID --home $HOME/.nibid

curl -s https://rpc.testnet-2.nibiru.fi/genesis | jq -r .result.genesis > $HOME/.nibid/config/genesis.json

sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${NIBIRU_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${NIBIRU_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${NIBIRU_PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${NIBIRU_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${NIBIRU_PORT}660\"%" $HOME/.nibid/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${NIBIRU_PORT}317\"%; s%^address = \":8080\"%address = \":${NIBIRU_PORT}080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${NIBIRU_PORT}090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${NIBIRU_PORT}091\"%; s%^address = \"0.0.0.0:8545\"%address = \"0.0.0.0:${NIBIRU_PORT}545\"%; s%^ws-address = \"0.0.0.0:8546\"%ws-address = \"0.0.0.0:${NIBIRU_PORT}546\"%" $HOME/.nibid/config/app.toml

sed -i 's|seeds =.*|seeds = "'$(curl -s https://networks.testnet.nibiru.fi/$NIBIRU_CHAIN_ID/seeds)'"|g' $HOME/.nibid/config/config.toml
sed -i 's/minimum-gas-prices =.*/minimum-gas-prices = "0.025unibi"/g' $HOME/.nibid/config/app.toml
sed -i 's|enable =.*|enable = true|g' $HOME/.nibid/config/config.toml
sed -i 's|rpc_servers =.*|rpc_servers = "'$(curl -s https://networks.testnet.nibiru.fi/$NIBIRU_CHAIN_ID/rpc_servers)'"|g' $HOME/.nibid/config/config.toml
sed -i 's|trust_height =.*|trust_height = "'$(curl -s https://networks.testnet.nibiru.fi/$NIBIRU_CHAIN_ID/trust_height)'"|g' $HOME/.nibid/config/config.toml
sed -i 's|trust_hash =.*|trust_hash = "'$(curl -s https://networks.testnet.nibiru.fi/$NIBIRU_CHAIN_ID/trust_hash)'"|g' $HOME/.nibid/config/config.toml

