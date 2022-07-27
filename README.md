#### Openresty API Gateway ####
How To Setup And Host Openresty API Gateway To protect your web applications

#### Openresty Development Getting Start ####
Openresty Installation on Ubuntu 22

### If nginx is already installed and running, try disabling and stopping it before installing openresty like below:

`sudo systemctl disable nginx` 
`sudo systemctl stop nginx`

Docker private registry acts as a centralized store of custom images that you created for your application. We can easily push images to this private remote Docker registry and pull images from there whenever we needed.

This article demonstrates how to setup a basic Openresty API Gateway, and then later we will see how to configure API Gateway using JWT tokens for centralised auth for entire stack of applications, etc.

Let’s create directories to keep the things organized and execute below commands step by step:

Add our APT repository to your Ubuntu system so as to easily install our packages and receive updates in the future.To add the repository, just run the following commands:

#### 1. command to create folder  ####

Step 1: we should install some prerequisites needed by adding GPG public keys
sudo apt-get -y install --no-install-recommends wget gnupg  ca-certificates

#### 2. docker-compose.yml ####

<img width="488" alt="2 1" src="https://user-images.githubusercontent.com/83863431/181220750-d6a0ed59-01ee-4e89-804f-75a94209d218.png">

#### 3. : import openresty GPG key
wget -O - https://openresty.org/package/pubkey.gpg | sudo gpg  --
dearmor -o /usr/share/keyrings/openresty.gpg

#### 4. : then add the openresty official APT repository.
echo "deb [arch=$(dpkg --print-architecture) 
signed-by=/usr/share/keyrings/openresty.gpg] 
http://openresty.org/package/ubuntu $(lsb_release -sc) main"  | sudo 
tee /etc/apt/sources.list.d/openresty.list > /dev/null

#### 5. : update the APT index:
sudo apt-get update

#### 6. : install  openresty :
sudo apt-get -y install openresty
This package also recommends the openresty-opm and openresty-
restydoc packages so the latter two will also automatically get installed by 
default. If that is not what you want, you can disable the automatic installation 
of recommended packages like this:
sudo apt-get -y install --no-install-recommends openresty