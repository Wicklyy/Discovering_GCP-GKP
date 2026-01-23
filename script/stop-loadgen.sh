echo "Moving to testing folder"
cd ../testing

source ./setup.sh

echo "stoping ansible loadgen script"
ansible all -i hosts.ini -m shell -a "sudo docker stop loadgen"
