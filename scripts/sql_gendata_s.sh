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

#generate 500 tables and 2 millions records, rough time consume 20 minuts
set -eu
cd ../tool/workloads
./bin/go-ycsb load mysql -P workloads/betting -p recordcount=2000000 -p mysql.host=172.16.4.2 -p mysql.user=root -p mysql.port=44000  --threads 200 -p dbnameprefix=ebs_ -p databaseproportions=1.0 -p unitnameprefix=unit1_ -p unitscount=100 -p tablecount=500 -p loadbatchsize=500
cd ../../ebs/

echo "SQL DML DONE"