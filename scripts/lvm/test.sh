#!/bin/bash
#copyright 2019 PingCAP, Inc.
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

set -eu
# define the device prefix / volume group
vg_dev=/dev/ebs_group/
# define the logical volume
lv_pd=$vg_dev"pd"
lv_tidb=$vg_dev"tidb"
lv_tikv1=$vg_dev"tikv_1"
lv_tikv2=$vg_dev"tikv_2"
lv_tikv3=$vg_dev"tikv_3"

echo $lv_pd
echo $lv_tidb
echo $lv_tikv1
echo $lv_tikv2
echo $lv_tikv3