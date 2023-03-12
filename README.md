# yb-manual-deployment

This repo contains: 
* terraform configuration for spinning up ec2 instances
* shell script for installing necessary packages, creating Yugabyte configuration files, creating systemd unit configuration for both `yb-tserver` and `yb-master`
* shell script for starting prometheus


## Steps to re-recreate deployment 

1. Navigate to `./terraform` directory and run `terraform apply`. Ensure you have downloaded your private key into this directory beforehand.

Run the following for all three nodes to deploy YB-Master and YB-TServer:

2. `wget https://raw.githubusercontent.com/hiimivantang/yb-manual-deployment/master/bootstrap.sh`

3. `chmod +x bootstrap.sh`

4. `sudo ./bootstrap.sh <master addresses and their respective ports delimited by comma>`

Then run the following on one of the nodes to deploy Prometheus:

5. `wget https://raw.githubusercontent.com/hiimivantang/yb-manual-deployment/master/start_prometheus.sh`

6. Update targets in `start.prometheus.sh` to point to your three nodes.

7. `chmod +x start_prometheus.sh`

8. `./start_prometheus.sh`
