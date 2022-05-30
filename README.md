# blr = block-level recovery

Purpose
this repo contain a series of scripts which help test and develope the block-level recovery

TiDB takes advantage of storage system which support snapshot, to do the backup and restore. while we need a env to simulate EBS in local/idc.

this project will help to simulate a snapshot function on block-level.

Structure:
aws: scripts for TiDB Cluster on EBS-based snapshot backup and restore.
idc: scripts for TiDB backup and restore by simulating the snapshot in local idc
lvm: scritps for TiDB using LVM snapshot functionality, it require the system has free LVM volume group.

