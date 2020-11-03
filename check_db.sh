yrfs-ctl --listtargets --nodetype=meta --state --longnodes; yrfs-ctl --listmirrorgroups --nodetype=meta
for i in $(seq 1 4)
do
    echo node$i
    echo -n 'db: '
    ssh node$i "yrfs-ctl --rocksdb --op=list --db=/data/mds/event.db/ | grep -E '{.*}' | wc -l"
    echo -n 'local: '
    ssh node$i "find /data/mds/replica/dentries/ -name '#fSiDs#' ! -path '/data/mds/replica/dentries/23/40/mdisposal/*' | xargs -r ls -l | grep '^-' | wc -l"
    echo
done
