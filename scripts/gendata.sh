#!/bin/bash
#
# Copyright 2019 PingCAP, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ProgName=$(basename $0)
pd=172.16.4.2:2379

check_cluster_online () {
    online=$(tiup ctl:v5.4.0 pd cluster -u http://$pd)
    echo "return online: $online"
    if [[ "$online" == "Failed to get the cluster information"* ]]
    then
        echo "pd $pd is not online, exit $ProgName."
        exit 1;
    else
        echo "pd $i is runing ..."
    fi
}

region_id=1
find_valid_regionid() {
    # find a random [1~1000] number to start
    i=$(( ( RANDOM % 1000 )  + 1 ))
    
    # find a valid region (<10000)
    while [ $i -ne 20000 ]
    do
            echo "check region ID $i existed"
            existed=$(tiup ctl:v5.4.0 pd region $i -u http://$pd)
            echo "existed region = ${existed}"
            if [ "$existed" != "null" ]
            then
                echo "split region ID $i"
                region_id=$i
                break;
            fi
            i=$(( ( RANDOM % 20000 )  + 1 ))
    done
}

# split 20 region picked randomly by find_valid_regionid
split_random() {
    for (( times=1; times<=5; times++ ))
    do 
        find_valid_regionid
        // split by approximate policy 
        tiup ctl:v5.4.0 pd operator add split-region $region_id --policy=approximate -u http://$pd
    done
}

sub_region(){
    echo "make region meta inconsistency"
    check_cluster_online
    #write some data into tidb
#    ./sql_gendata_s.sh
    
    #take snapshot of tikv1
    /home/ophone/ebs/ebs.sh snapshot tikv1 region
    #do split
    split_random
    sleep 30s
    #take snapshot of tikv2, tikv3 and pd
    for node in tikv2 tikv3 pd tidb; do
        /home/ophone/ebs/ebs.sh snapshot $node region
	sleep 30s
    done
}

sub_peer(){
    echo "make peer data inconsistency"
    #writing data into tidb
    ./sql_gendata_a.sh

    #take snapshot of tikv1
    /home/ophone/ebs/ebs.sh snapshot tikv1 peer
    sleep 1m # Waits 1 minutes.

    #take snapshot of tikv2, tikv3 and pd
    for node in tikv2 tikv3 pd tidb; do
        /home/ophone/ebs/ebs.sh snapshot $node peer
    done
}

sub_txn(){
    echo "make transaction data inconsistency"
    echo "create a big transaction"
    python3 gentxn_data.py &

    /home/ophone/ebs/ebs.sh snapshot tikv1 txn
    #take snapshot of tikv2, tikv3 and pd
    for node in tikv2 tikv3 pd tidb; do
        /home/ophone/ebs/ebs.sh snapshot $node txn
        sleep 30s 
    done
}

sub_inconsist() {
    scenario=$1

    case $scenario in
        "" | "-h" | "--help")
            sub_help
            ;;
        *)
            shift
            sub_${scenario} $@
            if [ $? = 127 ]; then
                echo "Error: '$scenario' is not a known command." >&2
                echo "       Run '$ProgName --help' for a list of known commands." >&2
                exit 1
            fi
            ;;
    esac
}
   # Display Help for this script
sub_help()
{
   echo ""
   echo "Usage: $0 inconsist [region|peer|txn]"

   echo "options:"
   echo "region     region meta inconsist by split/merge"
   echo "peer       peers in the same region has inconsist data"
   echo "txn        transaction data is inconsist"
   echo "-h         print help and exit."
   echo
}

start(){
    command=$1

    case $command in
        "" | "-h" | "--help")
            sub_help
            ;;
        *)
            shift
            sub_${command} $@
            if [ $? = 127 ]; then
                echo "Error: '$command' is not a known command." >&2
                echo "       Run '$ProgName --help' for a list of known commands." >&2
                exit 1
            fi
            ;;
    esac
}

start $@
