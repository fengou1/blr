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

# define the device prefix / volume group
vg_dev=/dev/ebs_group/
lvs_d=$(find $vg_dev -maxdepth 1 -type f -not -path '*/\.*' | sort)
#define the root folder of cluster
root_dir=/ebs/
dirs=$(find $root_dir -maxdepth 1 -type d -not -path '*/\.*' | sort)

# define the logical volume
lv_pd=$vg_dev"pd"
lv_tidb=$vg_dev"tidb"
lv_tikv1=$vg_dev"tikv_1"
lv_tikv2=$vg_dev"tikv_2"
lv_tikv3=$vg_dev"tikv_3"
lv_promes=$vg_dev"prometheus"
lv_gra=$vg_dev"grafana"

#define the snapshot
lv_pd_snap=$vg_dev"pd_snap"
lv_tidb_snap=$vg_dev"tidb_snap"
lv_tikv1_snap=$vg_dev"tikv_1_snap"
lv_tikv2_snap=$vg_dev"tikv_2_snap"
lv_tikv3_snap=$vg_dev"tikv_3_snap"
lv_promes_snap=$vg_dev"promes_snap"
lv_gra_snap=$vg_dev"gra_snap"


# define the tidb cluster work directory
dir_pd=/ebs/pd/
dir_tidb=/ebs/tidb/
dir_tikv1=/ebs/tikv_1
dir_tikv2=/ebs/tikv_2
dir_tikv3=/ebs/tikv_3
dir_grafana=/ebs/grafana
dir_promes=/ebs/prometheus

# define the restore tidb cluster work directory
r_pd=/ebs/restore/pd/
r_tidb=/ebs/restore/tidb/
r_tikv1=/ebs/restore/tikv_1/
r_tikv2=/ebs/restore/tikv_2/
r_tikv3=/ebs/restore/tikv_3/
r_promes=/ebs/restore/prometheus/
r_gra=/ebs/restore/grafana/


#define cluster run_xxx.sh
run_pd=/ebs/pd/pd-deploy/scripts/run_pd.sh
run_tidb=/ebs/tidb/tidb-deploy/scripts/run_tidb.sh
run_tikv_1=/ebs/tikv_1/tikv/scripts/run_tikv.sh
run_tikv_2=/ebs/tikv_2/tikv/scripts/run_tikv.sh
run_tikv_3=/ebs/tikv_3/tikv/scripts/run_tikv.sh

# define src ip and dst ip
src_ip="172.16.4.2"
dst_ip="172.16.6.118"
if [ "$1" = "reip" ]; then
    sed -i "s/${src_ip}/${dst_ip}/g" $run_pd
    sed -i "s/${src_ip}/${dst_ip}/g" $run_tidb
    sed -i "s/${src_ip}/${dst_ip}/g" $run_tikv_1
    sed -i "s/${src_ip}/${dst_ip}/g" $run_tikv_2
    sed -i "s/${src_ip}/${dst_ip}/g" $run_tikv_3
fi

sub_mount(){
    mount $lv_pd $dir_pd
    mount $lv_tidb $dir_tidb
    mount $lv_tikv1 $dir_tikv1
    mount $lv_tikv2 $dir_tikv2
    mount $lv_tikv3 $dir_tikv3
    mount $lv_promes $dir_promes
    mount $lv_gra $dir_gra
}

sub_umount() {
    for entry in `ls $lvs_d`; do
        umount $entry
    done
}

sub_snapshot() {
    target=$1
    purpose=$2
    case $target in
        "tikv1")
            lvcreate --size 300GB --snapshot --name tikv_1_snap_$purpose $lv_tikv1
            ;;
        "tikv2")
            lvcreate --size 300GB --snapshot --name tikv_2_snap_$purpose $lv_tikv2
            ;;
        "tikv3")
            lvcreate --size 300GB --snapshot --name tikv_3_snap_$purpose $lv_tikv3
            ;;       
        "tidb")
            lvcreate --size 100GB --snapshot --name tidb_snap_$purpose $lv_tidb
            ;;
        "pd")
            lvcreate --size 100GB --snapshot --name pd_snap_$purpose $lv_pd
            ;;
        *)
            lvcreate --size 100GB --snapshot --name tidb_snap_$purpose $lv_tidb
            lvcreate --size 300GB --snapshot --name tikv_1_snap_$purpose $lv_tikv1
            sleep 30s
            lvcreate --size 300GB --snapshot --name tikv_2_snap_$purpose $lv_tikv2
            sleep 30s
            lvcreate --size 300GB --snapshot --name tikv_3_snap_$purpose $lv_tikv3 
            sleep 30s
            lvcreate --size 100GB --snapshot --name pd_snap_$purpose $lv_pd
            lvcreate --size 100GB --snapshot --name promes_snap_$purpose $lv_promes
            lvcreate --size 100GB --snapshot --name gra_snap_$purpose $lv_gra
            ;;
    esac 
}

sub_restore() {
    purpose=$1

    mount ${lv_pd_snap}_${purpose} $r_pd
    mount ${lv_tidb_snap}_${purpose} $r_tidb
    mount ${lv_tikv1_snap}_${purpose} $r_tikv1
    mount ${lv_tikv2_snap}_${purpose} $r_tikv2
    mount ${lv_tikv3_snap}_${purpose} $r_tikv3
    mount ${lv_promes_snap}_${purpose} $r_promes
    mount ${lv_gra_snap}_${purpose} $r_gra
}

sub_copy () {
    echo "copy tikv1"
    scp -r /ebs/restore/tikv_1/* root@172.16.6.118:/home/restore/tikv_1/

    echo "copy tikv2"
    scp -r /ebs/restore/tikv_3/* root@172.16.6.118:/home/restore/tikv_3/

    echo "copy tikv3"
    scp -r /ebs/restore/tikv_2/* root@172.16.6.118:/home/restore/tikv_2/

    echo "copy tidb"
    scp -r /ebs/restore/tidb/* root@172.16.6.118:/home/restore/tidb/

    echo "copy pd"
    scp -r /ebs/restore/pd/* root@172.16.6.118:/home/restore/pd/

    echo "copy grafana"
    scp -r /ebs/restore/grafana/* root@172.16.6.118:/home/restore//grafana/

    echo "copy prometheus"
    scp -r /ebs/restore/prometheus/* root@172.16.6.118:/home/restore/prometheus/
}
sub_dsnap() {
    for r_node in $r_pd $r_tidb $r_tikv1 $r_tikv2 $r_tikv3 $r_promes $r_gra; do
        echo "umount restore lv: $r_node"
        umount $r_node
    done
    for type in region peer txn; do 
        for snapshot in "${lv_pd_snap}_${type}" "${lv_tidb_snap}_${type}" "${lv_tikv1_snap}_${type}" "${lv_tikv2_snap}_${type}" "${lv_tikv3_snap}_${type}" "${lv_promes_snap}_${type}" "${lv_gra_snap}_${type}"; do
            echo "remove snapshot $snapshot"
            #lv_name=$(echo $snapshot | sed -e "s/\/dev\///g")
            yes | lvremove $snapshot
            #expect "Do you really want to remove active logical volume $lv_name? [y/n]: \r"
            #send "y\r"
        done
    done
}

# clean the downstream cluster folder
sub_clean() {
    rm -rf /ebs/pd/*
    rm -rf /ebs/tikv_3/*
    rm -rf /ebs/tikv_2/*
    rm -rf /ebs/tikv_1/*
    rm -rf /ebs/tidb/*
    rm -rf /ebs/grafana/*
    rm -rf /ebs/prometheus/*
    echo "all cluster data and deploy folders are clean"
}
   # Display Help for this script
sub_help()
{
   echo ""
   echo "Usage: $0 [mount|umount|snapshot|restore|dsnap|clean]"

   echo "options:"
   echo "mount     mount logical volume into tidb cluster data and deploy folder"
   echo "umount    umount logical volume from tidb cluster data and deploy folder"
   echo "snapshot  take snapshot for tidb cluster"
   echo "restore   restore snapshot into restore folder"
   echo "dsnap     unmount the snapshot and delete the snapshot"
   echo "clean     remove the data from tidb cluster data and deploy folder."
   echo "copy      copy to another machine."
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