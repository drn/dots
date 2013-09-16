echo "Ensure no sleepimage files are generated"
sudo pmset -a hibernatemode 0
sudo rm /private/var/vm/sleepimage
sudo touch /private/var/vm/sleepimage
sudo chflags uchg /private/var/vm/sleepimage
