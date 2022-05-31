#!/bin/sh
#
# Copyright 2022 PingCAP, Inc.
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

# in IDC, backup only to hard kill the tikv process
# assumption: before call this function, tikv-server systemd auto-restart shall be disabled.

pd=10.244.7.158:2379


sub_snap() {
    pid_list=$(pgrep -f bin/tikv-server)
    echo "${pid_list}"
    for pid in ${pid_list}; do
        if [ ! -z ${pid} ]
        then
            echo "start to kill ${pid}"
            kill -9 ${pid}
        fi
    done
}

tikv1_run=/tidb-deploy/tikv-20160/scripts/run_tikv.sh
tikv2_run=/tidb-deploy/tikv-20161/scripts/run_tikv.sh
tikv3_run=/tidb-deploy/tikv-20162/scripts/run_tikv.sh


add_recovery_service() {
    # add stdout into log file for debug
    # TODO: sed -i 's/tikv_stderr\.log"/& 2>> "/tidb-deploy/tikv-20160/log/tikv_std\.log"' /tidb-deploy/tikv-20160/scripts/run_tikv.sh
    # add recovery service in tikv start script
    echo "add recovery service into tikv startup..."
    unset tikv1_in_recovery
    tikv1_in_recovery=$(grep '\--recovery-addr' /tidb-deploy/tikv-20160/scripts/run_tikv.sh)
    unset tikv2_in_recovery
    tikv2_in_recovery=$(grep '\--recovery-addr' /tidb-deploy/tikv-20161/scripts/run_tikv.sh)
    unset tikv3_in_recovery
    tikv3_in_recovery=$(grep '\--recovery-addr' /tidb-deploy/tikv-20162/scripts/run_tikv.sh)
    if [[ -z "${tikv1_in_recovery}" ]]
    then
        echo "add recovery serivice 10.244.7.158:3379 for tikv #1"
        sed -i '20 a  --recovery-addr "10.244.7.158:3379" \\' $tikv1_run
    fi
    if [[ -z "$tikv2_in_recovery" ]]
    then
        echo "add recovery serivice 10.244.7.158:3379 for tikv #2"
        sed -i '20 a --recovery-addr "10.244.7.158:3379" \\' $tikv2_run
    fi

    if [[ -z "$tikv3_in_recovery" ]]
    then
        echo "add recovery serivice 10.244.7.158:3379 for tikv #3"
        sed -i '20 a --recovery-addr "10.244.7.158:3379" \\' $tikv3_run
    fi
}

# add stdout log for debug purpose
add_stdout_log(){
    tikv1_log_exist=$(grep 'std.log"' $tikv1_run)
    if [ -z "$tikv1_log_exist" ]
    then
        echo "TiKV #1 stdout log does not existed, add it into --log-file"
        sed -i 's/stderr.log"/&  1>> "\/tidb-deploy\/tikv-20160\/log\/tikv_std.log"/' $tikv1_run
    fi

    tikv2_log_exist=$(grep 'std.log"' $tikv2_run)
    if [ -z "$tikv2_log_exist" ]
    then
        echo "TiKV #2 stdout log does not existed, add it into --log-file"
        sed -i 's/stderr.log"/&  1>> "\/tidb-deploy\/tikv-20161\/log\/tikv_std.log"/' $tikv2_run
    fi

    tikv3_log_exist=$(grep 'std.log"' $tikv3_run)
    if [ -z "$tikv3_log_exist" ]
    then
        echo "TiKV #3 stdout log does not existed, add it into --log-file"
        sed -i 's/stderr.log"/&  1>> "\/tidb-deploy\/tikv-20162\/log\/tikv_std.log"/' $tikv3_run
    fi
}


# copy the build binary to tikv deploy folder
# assumption: tikv-server or tidb cluster is stopped
build_bin=/code/tikv/target/release/tikv-server
deploy_tikv1=/tidb-deploy/tikv-20160
deploy_tikv2=/tidb-deploy/tikv-20161
deploy_tikv3=/tidb-deploy/tikv-20162

sub_copy() {
    echo "copy build binary ..."
    echo "cp $build_bin $deploy_tikv1/bin/"
    yes | cp $build_bin $deploy_tikv1"/bin/"
    echo "cp $build_bin $deploy_tikv2/bin/"
    yes | cp $build_bin $deploy_tikv2"/bin/"
    echo "cp $build_bin $deploy_tikv3/bin/"
    yes | cp $build_bin $deploy_tikv3"/bin/"

    echo "copy run tikv script ..."
    yes | cp  $tikv1_run".bak" $tikv1_run
    yes | cp  $tikv2_run".bak" $tikv2_run
    yes | cp  $tikv3_run".bak" $tikv3_run
    add_recovery_service
    add_stdout_log
}

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

config_pd () {
    check_cluster_online
    tiup ctl:v6.0.0 pd config set merge-schedule-limit 0 -u http://$pd
    tiup ctl:v6.0.0 pd config set region-schedule-limit 0 -u http://$pd
    tiup ctl:v6.0.0 pd config set replica-schedule-limit 0 -u http://$pd
}

sub_restore() {
    # add stdout into log file for debug
    # TODO: sed -i 's/tikv_stderr\.log"/& 2>> "/tidb-deploy/tikv-20160/log/tikv_std\.log"' /tidb-deploy/tikv-20160/scripts/run_tikv.sh
    # add recovery service in tikv start script
    config_pd
    echo "start block-level recovery service ..."
    tmux new-session -s 'blr' -d ./blr_restore.sh
}

db=$(mysql -h 10.244.7.158 -P 4000 -u root -e "show databases" | grep sbtest)
sub_prepare(){
    # 1. stop cluster
    # TODO: e.g: yes | tiup cluster stop ebs
    # 2. disable tikv systemd auto restart
    # TODO: e.g: sed -i xxx
    # 3. start cluster, TODO: cluster name may mutable as parameter
    echo "start tidb cluster ebs"
    tiup cluster start ebs
    # 4. create database
    #db=$(mysql -h 10.244.7.158 -P 4000 -u root -e "show databases" | grep sbtest)
    if [ -z "$db" ]
    then
        echo "sbtest database have to create for insert data"
        mysql -h 10.244.7.158 -P 4000 -u root -e "create database sbtest;"
    fi
    echo "sbtest database created already."
    # 5. sysbench to generate data in tidb cluster
    tmux new-session -s 'sysbench' -d ./sysbench.sh

}
   # Display Help for this script
sub_help()
{
   echo ""
   echo "Usage: $0 [copy|prepare|snap|restore|dsnap|clean]"

   echo "options:"
   echo "copy      replace cluster tikv-server by build binary"
   echo "prepare   prepare data for backup: sysbench to generate some data in tidb cluster"
   echo "snap      take snapshot for tidb cluster"
   echo "restore   restore snapshot into restore folder"
   echo "clean     remove the data from tidb cluster data and deploy folder."
   echo "-h        print help and exit."
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
