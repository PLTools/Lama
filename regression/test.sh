<<<<<<< HEAD
make clean
make TOPFILE=test000
=======
make check
pushd expressions && make check && popd
pushd deep-expressions && make check && popd

>>>>>>> 30537ff6ba7f9d05ac3ef20249c10cfaa701f5a7
