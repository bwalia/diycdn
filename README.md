# Setup a POP in AWS

### Note default instance size is `t2.nano` for openresty but if you are using Varnish to cache content then it is advised to use memory optimised instances start with `z1d.large`

`export AWS_ACCESS_KEY_ID=OBBTAIN AWS ACCESS KEY ID WITH APPROPRIATE ACCESS`
`export AWS_SECRET_ACCESS_KEY=OBBTAIN AWS SECRET ACCESS KEY WITH APPROPRIATE ACCESS`
`export AWS_DEFAULT_REGION=eu-west-2`

### Or

`AWS_ACCESS_KEY_ID=OBBTAIN AWS ACCESS KEY ID WITH APPROPRIATE ACCESS`
`AWS_SECRET_ACCESS_KEY=OBBTAIN AWS SECRET ACCESS KEY WITH APPROPRIATE ACCESS`
`AWS_DEFAULT_REGION=eu-west-2`

### To create a POP
`./pop_manager.sh "your_ssh_private_key_to_access_ec2s" "create" "user ssh rsa pub key to ssh into machines" "DiyCDN cloud cert is not set" "DiyCDN cloud cert is not set" "DiyCDN cloud key is not set"`

`Example params above ./pop_manager.sh ~/.ssh/id_rsa create ~/.ssh/id_rsa.pub "tls_cert_dummy" "tls_cert_key_dummy"`

replace `your_ssh_private_key_to_access_ec2s` with $(cat path to private key) following the example below:

`Other parameters of interests`

```
type of instance in AWS example t2.nano
no of instances per region for the POP 1 by default per region. If you pass 2 means total instance in POP would be 4

```

```./pop_manager.sh "$(cat ~/.ssh/id_rsa)"" "create" "DiyCDN cloud cert is not set" "DiyCDN cloud cert is not set" "DiyCDN cloud key is not set"```

### To destroy the POP
`./pop_manager.sh "your_ssh_private_key_to_access_ec2s" "destroy"`



#### This script use terraform to create openresty nginx pair for DiyCDN.cloud on AWS

#### Configuration options

