# lhpo
Lightweight HyperParameter Optimizer for Amazon Web Services

##### Setup the system (Ubuntu):
- setup executables (outside of NFS)
- setup lhpo (clone and install dependencies) outsite of NFS
- setup NFS and tmpfs into /etc/fstab
- configure aws to retrives other nodes
```
sudo apt-get install awscli
aws configure
```
- configure ssh to access other nodes
```
ssh-keygen -t rsa -f ~/.ssh/id_rsa_clust
cat ~/.ssh/id_rsa_clust.pub >> ~/.ssh/authorized_keys
rm ~/.ssh/id_rsa_clust.pub
```
- add aws lhpo to your bashrc
```
echo '. SOME_PATH/lhpo/aws/grid.config' >> ~/.bashrc
```
- configure grid.config, especially where is located NFS (by default is it /nfs)

Your system is ready to be deployed on your nodes.

#### Launch
Prepare an experiment into NFS and call parsing_rules.bash

In one node, launch :
- grid.balancer to distribute works
- grid.cleaner
- grid.booker is not provided (must by done with AWS GUI)

Check https://github.com/matthieu637/lhpo/ for more details on those scripts.
