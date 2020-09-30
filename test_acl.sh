df -h
for i in ro rw;do
   for j in `seq 2 5`;do
      echo -e "`date`#  /mnt/$i/rw_$j ##"
      echo -n `uuidgen` |tee -a /mnt/$i/rw_$j
   done
done
