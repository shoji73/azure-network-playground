# azure network playground

This repository stores Azure Bicep files that create an environment for checking the log output of Azure's network-based services.
The connection monitor is used to make HTTP accesses run periodically, making it easier to check network logs.
Diagnostic settings is also done in bicep, and logs are aggregated in a single Log Analytics workspace created in bicep.

## Resources to be deployed

![architecture](/docs/images/architecture.svg)

- Hub-Spoke network topology
- Network Security Group
- Azure Firewall
- Azure Application Gateway (and private endpoint)
- Azure Load Balancer (and private endpoint)
- VPN Gateway and connection
- Network Watcher (Connection Monitor)
- Virtual Machine

The [httpbin container](https://hub.docker.com/r/kennethreitz/httpbin) is installed in the Spoke01 VM and runs as a web app server.

![connectionMonitor](/docs/images/connectionMonitor.svg)
spoke02 vnet and remote vnet VMs are making monitoring HTTP calls with connection monitor agent.
The monitoring destinations are private endpoints(LB and AppGW), LB, AppGW and VMs directly.

## How to deploy

git clone this repository

It is recommended to create a new resource group and deploy within it.
```
az group create -n <resource group name> -l <location>
```

Deploy the bicep file
```
az deployment group create -f ./deploy.bicep -g <resource group name>
```
You will be asked for vm admin username and password, enter them.
