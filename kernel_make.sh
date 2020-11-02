tar -zxvf linux-4.19.13.tar.gz -C linux419
cd linux419&&make all -j 16&&make modules_install&&make install
cd ..
tar -Jxvf linux-4.4.229.tar.xz -C linux44 
cd linux44&&make all -j 16&&make modules_install&&make install
cd ..
