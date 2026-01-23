cd ../testing

source ./setup.sh

echo "Destroying VM's using Terraform"
terraform apply -auto-approve -destroy

echo "Cleaning hosts.ini file"
echo "" > hosts.ini
echo "" > distributed_hosts.ini