#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='mastercorecoin.conf'
CONFIGFOLDER='/root/.mastercorecoincore'
COIN_DAEMON='mastercorecoind'
COIN_CLI='mastercorecoin-cli'
COIN_PATH='/usr/bin/'
#COIN_TGZ='https://cdmcoin.org/condominium_ubuntu.zip'
#COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
COIN_NAME='mastercorecoin'
#COIN_EXPLORER='http://chain.cdmcoin.org'
COIN_PORT=29871
RPC_PORT=29872
SET_NUM=6

BLUE="\033[0;34m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
PURPLE="\033[0;35m"
RED='\033[0;31m'
GREEN="\033[0;32m"
NC='\033[0m'
MAG='\e[1;35m'

#프라이빗키 생성 / 배열값 mn_Privkey[1 ~ 6]
function 1_masternode_Genprivkey() {
for (( i = 1; i <= $SET_NUM; i++)); do
  mn_Privkey[$i]="$($COIN_PATH$COIN_CLI masternode genkey)"
  echo "mn_Privkey[$i] : ${mn_Privkey[$i]}"
done
}

function 2_masternode_IPv6networkset(){

  NODEIP_tmp=$(curl -s6 icanhazip.com)
  ipv6_tmp=$(expr length "$NODEIP_tmp")

  if [[ ${ipv6_tmp} -eq 38 ]]; then         #문자열 디폴트값 38 체크
    check_ipv6_tmp=1
    NODEIP_tmp=$(curl -s6 icanhazip.com)    #ipv6 값
    NODEIPv6=${NODEIP_tmp:0:20}             #ipv6 값 앞에서부터 21자리 자름
    #echo "NODEIPv6 : ${NODEIPv6}"
    for (( i = 1; i <= $SET_NUM; i++)); do  #NODEIPv6에 포트셋팅  /etc/network/interfaces에서 쓰일 변수 생성
      mn_IPv6[$i]=${NODEIPv6}:$i            #mn_IPv6[1~6]에   IPv6:1 ~ 6 값 생성
      echo "mn_IPv6[$i] : ${mn_IPv6[$i]}"
    done

  else
    echo -e "${RED}$0 You have to rebuild ipv6${NC}"
    check_ipv6_tmp=0
  fi

}
#IPv6는 read로 전달하도록 해야할듯.

function 3_add_IPv6() {
#ipv6가 추가되어 있는지를 어떻게 알 수 있을까... 어떻게 추가할까...
#if [[ ~~~ != ~~~~ ]];

#11번 라인 삭제, Auto를 삭제함.
  if [[ ${check_ipv6_tmp} -eq 1 ]]; then
    #statements

  sed -i '11d' /etc/network/interfaces

#IPv6 추가하기. 맨끝에 변하는 자리 하나는 빼놓고 넣어주기.
  cat << EOF >> /etc/network/interfaces
iface ens3 inet6 static
address ${mn_IPv6[1]}
netmask 64
EOF

for (( i = 2; i <= $SET_NUM; i++)); do  #NODEIPv6에 포트셋팅  /etc/network/interfaces에서 쓰일 변수 생성
  cat << EOF >> /etc/network/interfaces
up /sbin/ip -6 addr add dev ens3 ${mn_IPv6[$i]}
EOF
done

 #파일끝
#일단은 네트워크는 추가해놓는게 좋을듯해서 추가함.

#네트워크 재부팅
systemctl restart networking.service
sleep 3

#추가했던 네트워크들이 확인되는지 체크하기
ip addr show ens3
sleep 3

grep -n ^ /etc/network/interfaces

else
  echo -e "${RED}$0 ================================${NC}"
  echo -e "${RED}$0 You have to rebuild ipv6 setting${NC}"
fi

}

function edit_macc_addnode() {            #addnode 할때 다른 명령어 같이 실행되니깐 addnode 기능만 따로~
#복사전... 이 부분 POPC는 달라져야 함...################

##고정값 추가 및 addnode
##아직 정지안했음.

for (( i = 1; i <= $SET_NUM; i++)); do

sed -i '16,$d' $CONFIGFOLDER$i/$CONFIG_FILE           #addnode 초기화
                                                    #$CONFIGFOLDER/$CONFIG_FILE 15line부터 끝까지 삭제
cat << EOF >> $CONFIGFOLDER$i/$CONFIG_FILE
addnode=45.32.36.18
addnode=202.182.101.162
addnode=149.28.31.156
addnode=45.63.121.56
addnode=149.28.19.210
addnode=107.191.53.220
addnode=45.77.183.241
addnode=45.76.52.233
addnode=198.13.37.49
addnode=45.77.29.239
addnode=128.199.171.192
addnode=45.77.21.70
addnode=198.13.38.119
addnode=45.32.39.247
addnode=95.179.154.9
addnode=157.230.123.11
addnode=104.248.141.211
addnode=178.128.54.41
addnode=204.48.26.40
addnode=207.154.201.240
addnode=159.89.151.147
addnode=167.99.206.80
addnode=138.68.103.119
addnode=134.209.225.16
addnode=159.65.139.78
addnode=68.183.64.70
addnode=104.248.157.119:34652
addnode=104.248.39.113:29871
addnode=112.162.233.135:50514
addnode=113.10.36.11:60418
addnode=128.199.155.59:55256
addnode=128.199.167.13:29871
addnode=128.199.171.192:37988
addnode=128.199.175.9:42000
addnode=128.199.251.99:47266
addnode=134.209.108.46:60394
addnode=134.209.108.51:49510
addnode=134.209.225.16:58492
addnode=134.209.233.131:52286
addnode=134.209.240.245:51216
addnode=134.209.246.108:42116
EOF
done


sleep 2
echo -e "${RED}addnode work is done${NC}"


}

function 4_macc_node_setting(){

if [[ ${check_ipv6_tmp} -eq 1 ]]; then

$COIN_PATH$COIN_CLI stop   #cli stop

sed -i '3d'  $CONFIGFOLDER/$CONFIG_FILE
sed -i '11alogtimestamps=1\nmaxconnections=256\nport=29871' $CONFIGFOLDER/$CONFIG_FILE

for (( i = 1; i <= $SET_NUM; i++)); do
  cp -r -p .mastercorecoincore/ .mastercorecoincore$i
  sleep 1
done

for (( i = 1; i <= $SET_NUM; i++)); do
  sed -i "1s/rpcuser=/rpcuser=$i/"  $CONFIGFOLDER$i/$CONFIG_FILE
  sed -i "2s/rpcpassword=/rpcpassword=$i/"  $CONFIGFOLDER$i/$CONFIG_FILE
  sed -i "2arpcport=29872$i"  $CONFIGFOLDER$i/$CONFIG_FILE
  sed -i "5s/listen=1/listen=0/"  $CONFIGFOLDER$i/$CONFIG_FILE
  sed -i "8cbind=${mn_IPv6[$i]}"  $CONFIGFOLDER$i/$CONFIG_FILE
  sed -i "9cexternalip=[${mn_IPv6[$i]}]:29871"  $CONFIGFOLDER$i/$CONFIG_FILE
  #젠키 같다 붙이기.
  sed -i "12cmasternodeprivkey=${mn_Privkey[$i]}" $CONFIGFOLDER$i/$CONFIG_FILE

done
  echo "successfull macc node setting"
else

  echo -e "${RED}$0 ================================${NC}"
  echo -e "${RED}$0 cannot execute macc_node_setting ${NC}"
#statements
fi
 #grep -n ^ /root/.mastercorecoincore1/mastercorecoin.conf
}

function 5_macc_node_starting(){

if [[ ${check_ipv6_tmp} -eq 1 ]]; then

/usr/bin/mastercorecoind -datadir=/root/.mastercorecoincore/ -conf=/root/.mastercorecoincore/mastercorecoin.conf
/usr/bin/mastercorecoind -datadir=/root/.mastercorecoincore1/ -conf=/root/.mastercorecoincore/mastercorecoin.conf
/usr/bin/mastercorecoind -datadir=/root/.mastercorecoincore2/ -conf=/root/.mastercorecoincore/mastercorecoin.conf
/usr/bin/mastercorecoind -datadir=/root/.mastercorecoincore3/ -conf=/root/.mastercorecoincore/mastercorecoin.conf
/usr/bin/mastercorecoind -datadir=/root/.mastercorecoincore4/ -conf=/root/.mastercorecoincore/mastercorecoin.conf
/usr/bin/mastercorecoind -datadir=/root/.mastercorecoincore5/ -conf=/root/.mastercorecoincore/mastercorecoin.conf
/usr/bin/mastercorecoind -datadir=/root/.mastercorecoincore6/ -conf=/root/.mastercorecoincore/mastercorecoin.conf
#for (( i = 1; i <= $SET_NUM; i++)); do

#/usr/bin/mastercorecoind -datadir=/root/.mastercorecoincore$i/ -conf=/root/.mastercorecoincore/mastercorecoin.conf

#done

else

  echo -e "${RED}$0 ================================${NC}"
  echo -e "${RED}$0 cannot execute macc_node_starting ${NC}"
#statements
fi

}


1_masternode_Genprivkey
2_masternode_IPv6networkset
3_add_IPv6
4_macc_node_setting
edit_macc_addnode
5_macc_node_starting
