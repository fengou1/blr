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

# backup tikv-server and run script
sub_backup() {
    echo "backup tikv-server and script in tikv deploy folder ..."
    cp /tidb-deploy/tikv-20160/scripts/run_tikv.sh /tidb-deploy/tikv-20160/scripts/run_tikv.sh.bak
    cp /tidb-deploy/tikv-20161/scripts/run_tikv.sh /tidb-deploy/tikv-20161/scripts/run_tikv.sh.bak
    cp /tidb-deploy/tikv-20162/scripts/run_tikv.sh /tidb-deploy/tikv-20162/scripts/run_tikv.sh.bak
    cp /tidb-deploy/tikv-20160/bin/tikv-server /tidb-deploy/tikv-20160/bin/tikv-server.bak
    cp /tidb-deploy/tikv-20161/bin/tikv-server /tidb-deploy/tikv-20161/bin/tikv-server.bak
    cp /tidb-deploy/tikv-20162/bin/tikv-server /tidb-deploy/tikv-20162/bin/tikv-server.bak
}

# recovery env with backup tikv-server and run scripts
sub_restore() {
    echo "recovery the tikv run script ..."
    yes | cp /tidb-deploy/tikv-20160/scripts/run_tikv.sh.bak /tidb-deploy/tikv-20160/scripts/run_tikv.sh
    yes | cp /tidb-deploy/tikv-20161/scripts/run_tikv.sh.bak /tidb-deploy/tikv-20161/scripts/run_tikv.sh
    yes | cp /tidb-deploy/tikv-20162/scripts/run_tikv.sh.bak /tidb-deploy/tikv-20162/scripts/run_tikv.sh

    echo "recovery the tikv run binary ..."
    yes | cp /tidb-deploy/tikv-20160/bin/tikv-server.bak /tidb-deploy/tikv-20160/bin/tikv-server
    yes | cp /tidb-deploy/tikv-20161/bin/tikv-server.bak /tidb-deploy/tikv-20161/bin/tikv-server
    yes | cp /tidb-deploy/tikv-20162/bin/tikv-server.bak /tidb-deploy/tikv-20162/bin/tikv-server
}

sub_help()
{
   echo ""
   echo "Usage: $0 [backup|restore|help"

   echo "options:"
   echo "backup    backup the tikv-server and run script"
   echo "restore   restore the tikv-server and run script"
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
