#!/bin/bash
start=`date`
START=$(date +"%s")

## HWRF installation with parallel process.
# Download and install required library and data files for HWRF.
# Tested in Ubuntu 20.04.4 LTS & Ubuntu 22.04 LTS
# Built in 64-bit system
# Tested with current available libraries on 07/17/2022
# If newer libraries exist edit script paths for changes
# Estimated Run Time ~ 45 - 90 Minutes with 10mb/s downloadspeed.
# Special thanks to github user mkr39.

############################# Basic package managment ############################

sudo apt -y update
sudo apt -y upgrade

# download the key to system keyring; this and the following echo command are
# needed in order to install the Intel compilers
wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
| gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null

# add signed entry to apt sources and configure the APT client to use Intel repository:
echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list

# this update should get the Intel package info from the Intel repository
sudo apt -y update

# necessary binary packages (especially pkg-config and build-essential)
sudo apt -y install gcc gfortran g++ libtool automake autoconf make m4 default-jre default-jdk csh ksh python3 python3-dev python2 python2-dev mlocate curl cmake libcurl4-openssl-dev pkg-config build-essential

# install the Intel compilers
sudo apt -y install intel-basekit intel-hpckit
sudo apt -y update

# make sure some critical packages have been installed
which cmake pkg-config make gcc g++

# add the Intel compiler file paths to various environment variables
source /opt/intel/oneapi/setvars.sh

# some of the libraries we install below need one or more of these variables
export CC=icc
export CXX=icpc
export FC=ifort
export F77=ifort
export F90=ifort
export MPIFC=mpiifort
export MPIF77=mpiifort
export MPIF90=mpiifort
export MPICC=mpiicc
export MPICXX=mpiicpc

############################# CPU Core Management ####################################

export CPU_CORE=$(nproc)                                   # number of available cores on system
export CPU_6CORE="6"
export CPU_HALF=$(($CPU_CORE / 2))                         # half of availble cores on system
# Forces CPU cores to even number to avoid partial core export. ie 7 cores would be 3.5 cores.
export CPU_HALF_EVEN=$(( $CPU_HALF - ($CPU_HALF % 2) ))

# If statement for low core systems.  Forces computers to only use 1 core if there are 4 cores or less on the system.
if [ $CPU_CORE -le $CPU_6CORE ]
then
  export CPU_HALF_EVEN="2"
else
  export CPU_HALF_EVEN=$(( $CPU_HALF - ($CPU_HALF % 2) ))
fi

echo "##########################################"
echo "Number of cores being used $CPU_HALF_EVEN"
echo "##########################################"

############################## Directory Listing ############################
# makes necessary directories

export HOME=`cd;pwd`
export DIR=$HOME/HWRF/Libs
mkdir $HOME/HWRF
cd $HOME/HWRF
mkdir Downloads
mkdir Libs
mkdir Libs/grib2
mkdir Libs/NETCDF
mkdir Libs/LAPACK

############################## Downloading Libraries ############################
# these are all the libraries we're installing, including HWRF itself

cd Downloads
wget -c -4 https://github.com/madler/zlib/archive/refs/tags/v1.2.11.tar.gz
wget -c -4 https://github.com/HDFGroup/hdf5/archive/refs/tags/hdf5-1_12_2.tar.gz
wget -c -4 https://github.com/Unidata/netcdf-c/archive/refs/tags/v4.9.0.tar.gz
wget -c -4 https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.6.0.tar.gz
wget -c -4 https://github.com/pmodels/mpich/releases/download/v4.0.2/mpich-4.0.2.tar.gz
wget -c -4 https://download.sourceforge.net/libpng/libpng-1.6.37.tar.gz
wget -c -4 https://www.ece.uvic.ca/~frodo/jasper/software/jasper-1.900.1.zip
wget -c -4 https://parallel-netcdf.github.io/Release/pnetcdf-1.12.3.tar.gz
wget -c -4 https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v3.10.1.tar.gz

wget -c -4 https://dtcenter.org/sites/default/files/HWRF_v4.0a_hwrf-utilities.tar.gz
wget -c -4 https://dtcenter.org/sites/default/files/HWRF_v4.0a_pomtc.tar.gz
wget -c -4 https://dtcenter.org/sites/default/files/HWRF_v4.0a_ncep-coupler.tar.gz
wget -c -4 https://dtcenter.org/sites/default/files/HWRF_v4.0a_gfdl-vortextracker.tar.gz
wget -c -4 https://dtcenter.org/sites/default/files/HWRF_v4.0a_GSI.tar.gz
wget -c -4 https://dtcenter.org/sites/default/files/HWRF_v4.0a_UPP.tar.gz
wget -c -4 https://dtcenter.org/sites/default/files/HWRF_v4.0a_hwrfrun.tar.gz
wget -c -4 https://dtcenter.org/community-code/hurricane-wrf-hwrf/datasets#data-4

############################# ZLib ############################

cd $HOME/HWRF/Downloads
tar -xvzf v1.2.11.tar.gz
cd zlib-1.2.11/

CC=$MPICC FC=$MPIFC CXX=$MPICXX F90=$MPIF90 F77=$MPIF77 CFLAGS=-fPIC ./configure --prefix=$DIR/grib2
make -j $CPU_HALF_EVEN |& tee zlib.make.log
# make check |& tee zlib.makecheck.log
make -j $CPU_HALF_EVEN install |& tee zlib.makeinstall.log

############################# LibPNG ############################

cd $HOME/HWRF/Downloads

# other libraries below need these variables to be set
export LDFLAGS=-L$DIR/grib2/lib
export CPPFLAGS=-I$DIR/grib2/include

tar -xvzf libpng-1.6.37.tar.gz
cd libpng-1.6.37/

CC=$MPICC FC=$MPIFC CXX=$MPICXX F90=$MPIF90 F77=$MPIF77 CFLAGS=-fPIC ./configure --prefix=$DIR/grib2

make -j $CPU_HALF_EVEN |& tee libpng.make.log
#make -j $CPU_HALF_EVEN check |& tee libpng.makecheck.log
make -j $CPU_HALF_EVEN install |& tee libpng.makeinstall.log

############################# JasPer ############################

cd $HOME/HWRF/Downloads
unzip jasper-1.900.1.zip
cd jasper-1.900.1/

CC=$MPICC FC=$MPIFC CXX=$MPICXX F90=$MPIF90 F77=$MPIF77 CFLAGS=-fPIC ./configure --prefix=$DIR/grib2

make -j $CPU_HALF_EVEN |& tee jasper.make.log
#make -j $CPU_HALF_EVEN check |& tee jasper.makecheck.log
make -j $CPU_HALF_EVEN install |& tee jasper.makeinstall.log

# other libraries below need these variables to be set
export JASPERLIB=$DIR/grib2/lib
export JASPERINC=$DIR/grib2/include

############################# HDF5 library for NetCDF4 & parallel functionality ############################

cd $HOME/HWRF/Downloads
tar -xvzf hdf5-1_12_2.tar.gz
cd hdf5-hdf5-1_12_2

CC=$MPICC FC=$MPIFC CXX=$MPICXX F90=$MPIF90 F77=$MPIF77 CFLAGS=-fPIC ./configure --prefix=$DIR/grib2 --with-zlib=$DIR/grib2 --enable-hl --enable-fortran --enable-parallel

make -j $CPU_HALF_EVEN |& tee hdf5.make.log
#make VERBOSE=1 -j $CPU_HALF_EVEN check |& tee hdf5.makecheck.log
make -j $CPU_HALF_EVEN install |& tee hdf5.makeinstall.log

# other libraries below need these variables to be set
export HDF5=$DIR/grib2
export LD_LIBRARY_PATH=$DIR/grib2/lib:$LD_LIBRARY_PATH
export PATH=$HDF5/bin:$PATH

############################# Install Parallel-NetCDF ##############################

cd $HOME/HWRF/Downloads
tar -xvzf pnetcdf-1.12.3.tar.gz
cd pnetcdf-1.12.3

CC=$MPICC FC=$MPIFC CXX=$MPICXX F90=$MPIF90 F77=$MPIF77 CFLAGS=-fPIC ./configure --prefix=$DIR/grib2

make -j $CPU_HALF_EVEN |& tee pnetcdf.make.log
#make check |& tee pnetcdf.makecheck.log
#make ptests |& tee ptests.log
make -j $CPU_HALF_EVEN install |& tee pnetcdf.makeinstall.log

# other libraries below need these variables to be set
export PNETCDF=$DIR/grib2
export LD_LIBRARY_PATH=$PNETCDF/lib:$LD_LIBRARY_PATH
export PATH=$PNETCDF/bin:$PATH

############################## Install NETCDF-C Library ############################

cd $HOME/HWRF/Downloads
tar -xzvf v4.9.0.tar.gz
cd netcdf-c-4.9.0/

# these variables need to be set for the NetCDF-C install to work
export CPPFLAGS=-I$DIR/grib2/include
export LDFLAGS=-L$DIR/grib2/lib
export LIBS="-lhdf5_hl -lhdf5 -lz -lcurl -lpnetcdf -lm -ldl"

CC=$MPICC FC=$MPIFC CXX=$MPICXX F90=$MPIF90 F77=$MPIF77 CFLAGS=-fPIC ./configure --prefix=$DIR/NETCDF --disable-dap --enable-netcdf-4 --enable-netcdf4 --enable-pnetcdf --enable-parallel-tests |& tee netcdf.configure.log
make -j $CPU_HALF_EVEN |& tee netcdf.make.log
#make check |& tee netcdf.makecheck.log
make -j $CPU_HALF_EVEN install |& tee netcdf.makeinstall.log

# other libraries below need these variables to be set
export PATH=$DIR/NETCDF/bin:$PATH
export NETCDF=$DIR/NETCDF

############################## NetCDF-Fortran library ############################

cd $HOME/HWRF/Downloads
tar -xvzf v4.6.0.tar.gz
cd netcdf-fortran-4.6.0/

# these variables need to be set for the NetCDF-Fortran install to work
export LD_LIBRARY_PATH=$DIR/NETCDF/lib:$LD_LIBRARY_PATH
export CPPFLAGS="-I$DIR/NETCDF/include -I$DIR/grib2/include"
export LDFLAGS="-L$DIR/NETCDF/lib -L$DIR/grib2/lib"
export LIBS="-lnetcdf -lpnetcdf -lm -lcurl -lhdf5_hl -lhdf5 -lz -ldl"

CC=$MPICC FC=$MPIFC CXX=$MPICXX F90=$MPIF90 F77=$MPIF77 CFLAGS=-fPIC ./configure --prefix=$DIR/NETCDF --enable-netcdf-4 --enable-netcdf4 --enable-parallel-tests --enable-hdf5

make -j $CPU_HALF_EVEN |& tee netcdf-f.make.log
#make check |& tee netcdf-f.makecheck.log
make -j $CPU_HALF_EVEN install |& tee netcdf-f.makeinstall.log

############################ WRF 4.3.3 #################################
## WRF v4.3.3
## NMM core version 3.2
## Downloaded from git tagged release
# ifort/icc
# option 15, distributed memory (dmpar)
# large file support enable with WRFIO_NCD_LARGE_FILE_SUPPORT=1
########################################################################

cd $HOME/HWRF/Downloads
wget -c -4 https://github.com/wrf-model/WRF/archive/refs/tags/v4.3.3.tar.gz -O WRF-4.3.3.tar.gz
mkdir $HOME/HWRF/WRF
tar -xvzf WRF-4.3.3.tar.gz -C $HOME/HWRF/WRF
cd $HOME/HWRF/WRF/WRF-4.3.3

./clean -a

# these variables need to be set for the WRF install to work
export HWRF=1
export WRF_NMM_CORE=1
export WRF_NMM_NEST=1
export JASPERLIB=$DIR/grib2/lib
export JASPERINC=$DIR/grib2/include
export PNETCDF_QUILT=1
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
export NETCDF_classic=

# Removing user input for configure.  Choosing correct option for configure with Intel compilers
sed -i '420s/<STDIN>/15/g' $HOME/HWRF/WRF/WRF-4.3.3/arch/Config.pl

CC=$MPICC FC=$MPIFC CXX=$MPICXX F90=$MPIF90 F77=$MPIF77 ./configure # option 15

# Need to remove mpich/GNU config calls to Intel config calls
sed -i '170s|mpif90 -f90=$(SFC)|mpiifort|g' $HOME/HWRF/WRF/WRF-4.3.3/configure.wrf
sed -i '171s|mpicc -cc=$(SCC)|mpiicc|g' $HOME/HWRF/WRF/WRF-4.3.3/configure.wrf

./compile -j $CPU_HALF_EVEN nmm_real |& tee wrf.nmm.log

export WRF_DIR=$HOME/HWRF/WRF/WRF-4.3.3

# IF statement to check that all files were created.
cd $HOME/HWRF/WRF/WRF-4.3.3/main
n=$(ls ./*.exe | wc -l)
if (($n == 2))
 then
 echo "All expected files created."
 read -t 5 -p "Finished installing WRF. I am going to wait for 5 seconds only ..."
else
 echo "Missing one or more expected files. Exiting the script."
  read -p "Please contact script authors for assistance, press 'Enter' to exit script." return
fi

############################ WPS 4.3.1 #####################################
## Downloaded from git tagged releases
# Option 19 for gfortran and distributed memory
########################################################################
cd $HOME/HWRF/Downloads
wget -c -4 https://github.com/wrf-model/WPS/archive/refs/tags/v4.3.1.tar.gz -O WPS-4.3.1.tar.gz
tar -xvzf WPS-4.3.1.tar.gz -C $HOME/HWRF/WRF
cd $HOME/HWRF/WRF/WPS-4.3.1

./clean -a

# Removing user input for configure.  Choosing correct option for configure with Intel compilers
sed -i '141s/<STDIN>/19/g' $HOME/HWRF/WRF/WPS-4.3.1/arch/Config.pl

./configure -D #Option 19 for Intel and distributed memory

sed -i '65s|mpif90|mpiifort|g' $HOME/HWRF/WRF/WPS-4.3.1/configure.wps
sed -i '66s|mpicc|mpiicc|g' $HOME/HWRF/WRF/WPS-4.3.1/configure.wps

./compile |& tee compile_wps.log

# IF statement to check that all files were created.
 cd $HOME/HWRF/WRF/WPS-4.3.1
 n=$(ls ./*.exe | wc -l)
 if (($n == 3))
  then
  echo "All expected files created."
  read -t 5 -p "Finished installing WPS. I am going to wait for 5 seconds only ..."
 else
  echo "Missing one or more expected files. Exiting the script."
  read -p "Please contact script authors for assistance, press 'Enter' to exit script."  return
 fi

################### LAPACK ###########################

cd $HOME/HWRF/Downloads
tar -xvzf v3.10.1.tar.gz
cd lapack-3.10.1
cp make.inc.example make.inc

# changing some variables and flags for the cmake build process
sed -i '9s/ gcc/ icc /g' make.inc
sed -i '20s/ gfortran/ ifort /g' make.inc
sed -i '21s/ -O2 -frecursive/  -O2/g' make.inc
sed -i '23s/ -O0 -frecursive/  -O0/g' make.inc
sed -i '40s/#TIMER = EXT_ETIME/TIMER = EXT_ETIME/g' make.inc
sed -i '46s/TIMER = INT_ETIME/#TIMER = INT_ETIME/g' make.inc

mkdir build && cd build

# this library uses cmake instead of make to build itself
cmake -DCMAKE_INSTALL_LIBDIR=$HOME/HWRF/Libs/LAPACK ..
cmake --build . -j $CPU_HALF_EVEN --target install

# other libraries below need these variables to be set
export LAPACK_DIR=$HOME/HWRF/Libs/LAPACK
export LD_LIBRARY_PATH=$LAPACK_DIR:$LD_LIBRARY_PATH

######################################## HWRF-Utilities ##################################

cd $HOME/HWRF/Downloads
tar -xvzf HWRF_v4.0a_hwrf-utilities.tar.gz -C $HOME/HWRF
cd $HOME/HWRF
mv $HOME/HWRF/hwrf-utilities $HOME/HWRF/HWRF_UTILITIES
cd $HOME/HWRF/HWRF_UTILITIES

###### SED statements required due to syntax error in original configure script ####
sed -i '130c\ if [ -z "$MKLROOT" ] && [ ! -z "$MKL" ] ; then' $HOME/HWRF/HWRF_UTILITIES/configure
sed -i '132c\ elif [ ! -z "$MKLROOT" ] && [ -z "$MKL" ] ; then' $HOME/HWRF/HWRF_UTILITIES/configure
sed -i '136c\ if [ ! -z "$JASPERINC" ] && [ ! -z "$JASPERLIB" ] ; then' $HOME/HWRF/HWRF_UTILITIES/configure
sed -i '139c\     if [ ! -z "$PNG_LDFLAGS" ] ; then' $HOME/HWRF/HWRF_UTILITIES/configure
sed -i '144c\    if [ ! -z "$Z_INC" ] ; then' $HOME/HWRF/HWRF_UTILITIES/configure
sed -i '147c\     if [ ! -z "$PNG_CFLAGS" ] ; then' $HOME/HWRF/HWRF_UTILITIES/configure
sed -i '151c\ if [ ! -z "$PNETCDF" ] ; then' $HOME/HWRF/HWRF_UTILITIES/configure

# these variables need to be set for the HWRF-Utilities install to work
export MKL=$MKLROOT
export NETCDF=$HOME/HWRF/Libs/NETCDF
export WRF_DIR=$HOME/HWRF/WRF/WRF-4.3.3
export JASPERLIB=$DIR/grib2/lib
export JASPERINC=$DIR/grib2/include
export LAPACK_PATH=$LAPACK_DIR


# Removing user input for configure.  Choosing correct option for configure with Intel compilers
sed -i '155s/<STDIN>/7/g' $HOME/HWRF/HWRF_UTILITIES/arch/Config.pl

./configure #option 7

# sed commands to change to Intel compiler format
sed -i '30s/-openmp/-qopenmp/g' $HOME/HWRF/HWRF_UTILITIES/configure.hwrf
sed -i '47s/ mpif90 -f90=ifort/ mpiifort/g' $HOME/HWRF/HWRF_UTILITIES/configure.hwrf
sed -i '48s/mpif90 -free -f90=ifort/mpiifort -free/g' $HOME/HWRF/HWRF_UTILITIES/configure.hwrf
sed -i '49s/mpicc -cc=icc/mpiicc/g' $HOME/HWRF/HWRF_UTILITIES/configure.hwrf

./compile 2>&1 | tee hwrfutilities.build.log

# IF statement to check that all files were created.
 cd $HOME/HWRF/HWRF_UTILITIES/exec
 n=$(ls ./*.exe | wc -l)
 cd $HOME/HWRF/HWRF_UTILITIES/libs
 m=$(ls ./*.a | wc -l)
 if (($n == 79)) && (($m == 28))
   then
  echo "All expected files created."
  read -t 5 -p "Finished installing HWRF-UTILITIES. I am going to wait for 5 seconds only ..."
 else
  echo "Missing one or more expected files. Exiting the script."
  read -p "Please contact script authors for assistance, press 'Enter' to exit script."
  return
 fi

##################################  MPIPOM-TC  ##############################

cd $HOME/HWRF/Downloads
tar -xvzf HWRF_v4.0a_pomtc.tar.gz -C $HOME/HWRF
cd $HOME/HWRF
mv $HOME/HWRF/pomtc $HOME/HWRF/MPIPOM-TC
cd $HOME/HWRF/MPIPOM-TC

# these variables need to be set for the MPIPOM-TC install to work
export JASPER=$HOME/HWRF/Libs/grib2/
export LIB_JASPER_PATH=$HOME/HWRF/Libs/grib2/lib
export LIB_PNG_PATH=$HOME/HWRF/Libs/grib2/lib
export LIB_Z_PATH=$HOME/HWRF/Libs/grib2/
export LIB_W3_PATH=$HOME/HWRF/HWRF_UTILITIES/libs/
export LIB_SP_PATH=$HOME/HWRF/HWRF_UTILITIES/libs/
export LIB_SFCIO_PATH=$HOME/HWRF/HWRF_UTILITIES/libs/
export LIB_BACIO_PATH=$HOME/HWRF/HWRF_UTILITIES/libs/
export LIB_NEMSIO_PATH=$HOME/HWRF/HWRF_UTILITIES/libs/
export LIB_G2_PATH=$HOME/HWRF/HWRF_UTILITIES/libs/
export LIB_BLAS_PATH=$HOME/HWRF/HWRF_UTILITIES/libs/
export PNETCDF=$DIR/grib2

###### SED statements required due to syntax error in original configure script ####
sed -i 's/\[\[/\[/g' $HOME/HWRF/MPIPOM-TC/configure
sed -i 's/\]\]/\]/g' $HOME/HWRF/MPIPOM-TC/configure
sed -i 's/==/=/g' $HOME/HWRF/MPIPOM-TC/configure
sed -i '272c\    if [ -s $ldir/libjasper.a ] || [ -s $ldir/libjasper.so ] ; then' $HOME/HWRF/MPIPOM-TC/configure
sed -i '288c\    if [ -s $ldir/libpng.a ] || [ -s $ldir/libpng.so ] ; then' $HOME/HWRF/MPIPOM-TC/configure
sed -i '304c\    if [ -s $ldir/libz.a ] || [ -s $ldir/libz.so ] ; then' $HOME/HWRF/MPIPOM-TC/configure

# Removing user input for configure.  Choosing correct option for configure with Intel compilers
sed -i '101s/<STDIN>/3/g' $HOME/HWRF/MPIPOM-TC/arch/Config.pl

/bin/bash ./configure  #option 3

# sed commands to change to intel compiler format
sed -i '32s/ -openmp/ -qopenmp/g' $HOME/HWRF/MPIPOM-TC/configure.pom
sed -i '41s/ mpif90 -f90=$(SFC)/ mpiifort/g' $HOME/HWRF/MPIPOM-TC/configure.pom
sed -i '42s/ mpif90 -f90=$(SFC) -free / mpiifort -free/g' $HOME/HWRF/MPIPOM-TC/configure.pom

./compile |& tee ocean.log

# IF statement to check that all files were created.
cd $HOME/HWRF/MPIPOM-TC/ocean_exec
n=$(ls ./*.exe | wc -l)
m=$(ls ./*.xc | wc -l)
 if (($n == 9)) && (($m == 12))
   then
  echo "All expected files created."
  read -t 5 -p "Finished installing MPIPOM-TC. I am going to wait for 5 seconds only ..."
 else
  echo "Missing one or more expected files. Exiting the script."
  read -p "Please contact script authors for assistance, press 'Enter' to exit script."  return
 fi

################################## GFDL Vortex Tracker ##############################

cd $HOME/HWRF/Downloads
tar -xvzf HWRF_v4.0a_gfdl-vortextracker.tar.gz -C $HOME/HWRF
cd $HOME/HWRF
mv $HOME/HWRF/gfdl-vortextracker $HOME/HWRF/GFDL_VORTEX_TRACKER
cd $HOME/HWRF/GFDL_VORTEX_TRACKER

# these variables need to be set for the GFDL Vortex Tracker install to work
export LIB_JASPER_PATH=$HOME/HWRF/Libs/grib2/lib
export LIB_PNG_PATH=$HOME/HWRF/Libs/grib2/lib
export LIB_Z_PATH=$HOME/HWRF/Libs/grib2/
export LIB_W3_PATH=$HOME/HWRF/HWRF_UTILITIES/libs/
export LIB_BACIO_PATH=$HOME/HWRF/HWRF_UTILITIES/libs/
export LIB_G2_PATH=$HOME/HWRF/HWRF_UTILITIES/libs/

sed -i 's/\[\[/\[/g' $HOME/HWRF/GFDL_VORTEX_TRACKER/configure
sed -i 's/\]\]/\]/g' $HOME/HWRF/GFDL_VORTEX_TRACKER/configure
sed -i 's/==/=/g' $HOME/HWRF/GFDL_VORTEX_TRACKER/configure

# Removing user input for configure.  Choosing correct option for configure with Intel compilers
sed -i '154s/<STDIN>/2/g' $HOME/HWRF/GFDL_VORTEX_TRACKER/arch/Config.pl

./configure  #option 2

# sed commands to change to Intel compiler format
sed -i '38s/ mpif90 -fc=$(SFC)/ mpiifort/g' $HOME/HWRF/GFDL_VORTEX_TRACKER/configure.trk
sed -i '39s/ mpif90 -fc=$(SFC) -free/ mpiifort -free/g' $HOME/HWRF/GFDL_VORTEX_TRACKER/configure.trk
sed -i '40s/ mpicc/ mpiicc/g' $HOME/HWRF/GFDL_VORTEX_TRACKER/configure.trk

./compile 2>&1 | tee tracker.log

# IF statement to check that all files were created.
 cd $HOME/HWRF/GFDL_VORTEX_TRACKER/trk_exec
 n=$(ls ./*.exe | wc -l)
 if (($n == 3))
   then
  echo "All expected files created."
  read -t 5 -p "Finished installing GFDL_VORTEX_TRACKER. I am going to wait for 5 seconds only ..."
 else
  echo "Missing one or more expected files. Exiting the script."
  read -p "Please contact script authors for assistance, press 'Enter' to exit script."  return
 fi



################################## NCEP Coupler ##############################

cd $HOME/HWRF/Downloads
tar -xvzf HWRF_v4.0a_ncep-coupler.tar.gz -C $HOME/HWRF
cd $HOME/HWRF
mv $HOME/HWRF/ncep-coupler $HOME/HWRF/NCEP_COUPLER
cd $HOME/HWRF/NCEP_COUPLER

# Removing user input for configure.  Choosing correct option for configure with intel compilers
sed -i '84s/<STDIN>/3/g' $HOME/HWRF/NCEP_COUPLER/arch/Config.pl

./configure  #option 3

# sed commands to change to intel compiler format
sed -i '26s/ mpif90 -fc=$(SFC)/ mpiifort/g' $HOME/HWRF/NCEP_COUPLER/configure.cpl
sed -i '27s/ mpif90 -fc=$(SFC) -free/ mpiifort -free/g' $HOME/HWRF/NCEP_COUPLER/configure.cpl

./compile 2>&1 | tee coupler.log

# IF statement to check that all files were created.
 cd $HOME/HWRF/NCEP_COUPLER/cpl_exec
 n=$(ls ./*.exe | wc -l)
 if (($n == 1))
   then
  echo "All expected files created."
  read -t 5 -p "Finished installing NCEP_COUPLER. I am going to wait for 5 seconds only ..."
 else
  echo "Missing one or more expected files. Exiting the script."
  read -p "Please contact script authors for assistance, press 'Enter' to exit script."  return
 fi

################################## Unified Post Processor (UPP) ##############################

cd $HOME/HWRF/Downloads
tar -xvzf HWRF_v4.0a_UPP.tar.gz -C $HOME/HWRF
cd $HOME/HWRF/UPP

# these variables need to be set for the UPP install to work
export HWRF=1
export WRF_DIR=$HOME/HWRF/WRF/WRF-4.3.3
export JASPERLIB=$DIR/grib2/lib
export JASPERINC=$DIR/grib2/include

# Removing user input for configure.  Choosing correct option for configure with intel compilers
sed -i '197s/<STDIN>/4/g' $HOME/HWRF/UPP/arch/Config.pl

./configure  #compile opiton 4

# sed commands to change to intel compiler format
sed -i '26s/ mpif90 -fc=$(SFC)/ mpiifort/g' $HOME/HWRF/NCEP_COUPLER/configure.cpl
sed -i '27s/ mpif90 -fc=$(SFC) -free/ mpiifort -free/g' $HOME/HWRF/NCEP_COUPLER/configure.cpl

# sed commands to change to intel compiler format
sed -i '27s/ mpif90 -f90=$(SFC)/ mpiifort/g' $HOME/HWRF/UPP/configure.upp
sed -i '28s/ mpif90 -f90=$(SFC) -free/ mpiifort -free/g' $HOME/HWRF/UPP/configure.upp
sed -i '29s/ mpicc/ mpiicc/g' $HOME/HWRF/UPP/configure.upp

./compile 2>&1 | tee build.log

# IF statement to check that all files were created.
 cd $HOME/HWRF/UPP/bin
 n=$(ls ./*.exe | wc -l)
 cd $HOME/HWRF/UPP/lib
 m=$(ls ./*.a | wc -l)
 if (($n == 6)) && (($m == 13))
   then
  echo "All expected files created."
  read -t 5 -p "Finished installing UPP. I am going to wait for 5 seconds only ..."
 else
  echo "Missing one or more expected files. Exiting the script."
  read -p "Please contact script authors for assistance, press 'Enter' to exit script."  return
 fi

############################### HWRF RUN ######################################
# This section unpacks the runtime files for HWRF
# The HWRF User Guide and other documentation are downloaded as well;
# see chapter 3 of the User Guide for details on running HWRF.
###############################################################################

cd $HOME/HWRF/Downloads
tar -xvzf HWRF_v4.0a_hwrfrun.tar.gz -C $HOME/HWRF
cd $HOME/HWRF
mv $HOME/HWRF/hwrfrun $HOME/HWRF/HWRF_RUN
cd $HOME/HWRF/HWRF_RUN

#HWRF v4.0a Users Guide
wget -c -4 https://dtcenter.org/sites/default/files/community-code/hwrf/docs/users_guide/HWRF-UG-2018.pdf
#HWRF Scientific Documentation - November 2018
wget -c -4 https://dtcenter.org/sites/default/files/community-code/hwrf/docs/scientific_documents/HWRFv4.0a_ScientificDoc.pdf
#WRF-NMM V4 User's Guide
wget -c -4 https://dtcenter.org/sites/default/files/community-code/hwrf/docs/scientific_documents/WRF-NMM_2018.pdf

######################## Static geographic gata incl/ optional files ####################
# http://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html
# These files are LARGE so if you only need certain ones, comment the others off with #
# All of these files downloaded and untarred come out to roughly 250GB
# https://www2.mmm.ucar.edu/wrf/users/download/get_sources_wps_geog.html
#################################################################################

cd $HOME/HWRF/Downloads
mkdir $HOME/HWRF/GEOG
mkdir $HOME/HWRF/GEOG/WPS_GEOG

# Mandatory WRF Preprocessing System (WPS) Geographical Input Data Mandatory Fields

wget -c -4 https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_high_res_mandatory.tar.gz
tar -xvzf geog_high_res_mandatory.tar.gz -C $HOME/HWRF/GEOG/

wget -c -4 https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_low_res_mandatory.tar.gz
tar -xvzf geog_low_res_mandatory.tar.gz -C $HOME/HWRF/GEOG/
mv $HOME/HWRF/GEOG/WPS_GEOG_LOW_RES/ $HOME/HWRF/GEOG/WPS_GEOG


# WPS Geographical Input Data - Mandatory for Specific Applications

wget -c -4 https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_thompson28_chem.tar.gz
tar -xvzf geog_thompson28_chem.tar.gz -C $HOME/HWRF/GEOG/WPS_GEOG

wget -c -4 https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_noahmp.tar.gz
tar -xvzf geog_noahmp.tar.gz -C $HOME/HWRF/GEOG/WPS_GEOG

wget -c  -4 https://www2.mmm.ucar.edu/wrf/src/wps_files/irrigation.tar.gz
tar -xvzf irrigation.tar.gz -C $HOME/HWRF/GEOG/WPS_GEOG

wget -c -4 https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_px.tar.gz
tar -xvzf geog_px.tar.gz -C $HOME/HWRF/GEOG/WPS_GEOG

wget -c -4 https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_urban.tar.gz
tar -xvzf geog_urban.tar.gz -C $HOME/HWRF/GEOG/WPS_GEOG

wget -c -4 https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_ssib.tar.gz
tar -xvzf geog_ssib.tar.gz -C $HOME/HWRF/GEOG/WPS_GEOG

wget -c -4 https://www2.mmm.ucar.edu/wrf/src/wps_files/lake_depth.tar.bz2
tar -xvf lake_depth.tar.bz2 -C $HOME/HWRF/GEOG/WPS_GEOG

wget -c -4 https://www2.mmm.ucar.edu/wrf/src/wps_files/topobath_30s.tar.bz2
tar -xvf topobath_30s.tar.bz2 -C $HOME/HWRF/GEOG/WPS_GEOG

wget -c -4 https://www2.mmm.ucar.edu/wrf/src/wps_files/gsl_gwd.tar.bz2
tar -xvf gsl_gwd.tar.gz -C $HOME/HWRF/GEOG/WPS_GEOG


# Optional WPS Geographical Input Data

wget -c -4 https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_older_than_2000.tar.gz
tar -xvzf geog_older_than_2000.tar.gz -C $HOME/HWRF/GEOG/WPS_GEOG

wget -c -4 https://www2.mmm.ucar.edu/wrf/src/wps_files/modis_landuse_20class_15s_with_lakes.tar.gz
tar -xvzf modis_landuse_20class_15s_with_lakes.tar.gz -C $HOME/HWRF/GEOG/WPS_GEOG

wget -c -4 https://www2.mmm.ucar.edu/wrf/src/wps_files/geog_alt_lsm.tar.gz
tar -xvzf geog_alt_lsm.tar.gz -C $HOME/HWRF/GEOG/WPS_GEOG

wget -c -4 https://www2.mmm.ucar.edu/wrf/src/wps_files/nlcd2006_ll_9s.tar.bz2
tar -xvf nlcd2006_ll_9s.tar.bz2 -C $HOME/HWRF/GEOG/WPS_GEOG

wget -c -4 https://www2.mmm.ucar.edu/wrf/src/wps_files/updated_Iceland_LU.tar.gz
tar -xvf updated_Iceland_LU.tar.gz -C $HOME/HWRF/GEOG/WPS_GEOG

wget -c -4 https://www2.mmm.ucar.edu/wrf/src/wps_files/modis_landuse_20class_15s.tar.bz2
tar -xvf modis_landuse_20class_15s.tar.bz2 -C $HOME/HWRF/GEOG/WPS_GEOG

########################## Export PATH and LD_LIBRARY_PATH ################################

cd $HOME

# append these two variables to the user's .bashrc file in their home directory,
# as they're needed when running HWRF
echo "export PATH=$DIR/bin:$PATH" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=$DIR/lib:$LD_LIBRARY_PATH" >> ~/.bashrc

##################################### Bash script finished ##############################

end=`date`
END=$(date +"%s")
DIFF=$(($END-$START))
echo "Install Start Time: ${start}"
echo "Install End Time: ${end}"
echo "Install Duration: $(($DIFF / 3600 )) hours $((($DIFF % 3600) / 60)) minutes $(($DIFF % 60)) seconds"
echo "Congratulations! You've successfully installed all required files to run the Hurricane Weather Research Forecast (HWRF) Model verison 4.0a."
echo "Thank you for using this script."
