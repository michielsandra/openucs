# Open USRP Channel Sounder

This repository contains an implementation of a channel sounder based on the NI USRP X410. The code is still under development! 
Support for other USRPs will come.

## Dependencies

UHD v4.2.0.1 and all its dependencies


## Get started (X410 only so far)
We recommend to use a fresh Ubuntu 20.04 LTS installation.

1. Install UHD dependencies
```
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install autoconf automake build-essential ccache cmake cpufrequtils doxygen ethtool \
g++ git inetutils-tools libboost-all-dev libncurses5 libncurses5-dev libusb-1.0-0 libusb-1.0-0-dev \
libusb-dev python3-dev python3-mako python3-numpy python3-requests python3-scipy python3-setuptools \
python3-ruamel.yaml
```

2. Build UHD from souce and install
```
cd
git clone https://github.com/EttusResearch/uhd
cd uhd
git checkout v4.2.0.1
cd host
mkdir build
cd build
cmake ../
make -j$(nproc)
sudo make install
```

3. Clone this repository and build from source
```
cd
git clone https://github.com/michielsandra/openucs
cd openucs
mkdir build
cd build
cmake -DUHD_FPGA_DIR=../../uhd/fpga ../
make openucs
```

4. Set static IP on PC and USRP X410
Follow the guide in the [USRP Hardware Driver and USRP Manual](https://files.ettus.com/manual/page_usrp_x4xx.html).

5. Update filesystem
Download the mender file [here] (https://files.ettus.com/binaries/cache/x4xx/meta-ettus-v4.2.0.1-rc1/). 
Unzip and copy the file into the home directory of the X410 via SFTP.
Then use the following commands on the X410 via SSH:
```
mender install <usrp_x4xx_fs.mender>
reboot
```
After reboot, log back into the USRP. If everything seems okay, commit the new filesystem:
```
mender commit
```

6. Download bitfile.
Download the bitfile from [this] (https://lu.box.com/s/6g7uecb6cc5l842corv2gof9yfmjjk52) link.
Details on how to compile the bitfile yourself will come soon.

7. Load bitfile onto the USRP X410 
Navigate to the directory where you unpacked the bitfile.
```
uhd_image_loader --args type=x4xx,addr=<your usrp ip> --fpga-path usrp_x410_fpga_X4_400.bit
```

8. Example use
First generate some Tx signal.
```
cd
cd openucs/build
python3 ../scripts/tx.py
```
Launch the channel sounder
```
./apps/openucs --type x410 --sync external --freq 5.6e9 --rate 500e6 --rx_gain 45 --tx_gain 30 --addr 192.168.1.3 --nrx 1 --ntx 1 --meas_rate 10 --l 1024 --k 0 --m 1
```
In a separate terminal you can launch a Dash app to look at the channel response. (But launch it from the same directory)
```
cd
cd openucs/build
python3 ../scripts/plot.py
```

## Future work
- Support for X310, E320, E310
- Improved dashboard
- Switched channel sounding using GPIO
- Save data in HDF5 format
