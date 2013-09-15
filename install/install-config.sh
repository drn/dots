echo "Hibernate mode set to desktop"
sudo pmset -a hibernatemode 0

echo "Clean up sleep image"
sudo rm /private/var/vm/sleepimage
