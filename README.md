## Name
Azure Firewall Automation for Azure Virtual Desktop

## Description
Tired of manually managing Azure Firewall rules for Azure Virtual Desktop? We are too! This project aims to automate the process of managing Azure Firewall rules for Azure Virtual Desktop.

## Pre-requisites
- The good folks at Microsoft created an ARM template to deploy Azure Firewall rules for Azure Virtual Desktop (who uses ARM?). Just kidding MSFT, we all love ARM
  - https://github.com/Azure/RDS-Templates/blob/master/AzureFirewallPolicyForAVD/FirewallPolicyForAVD-template.json
- ```fw_rules/parse_rules.py``` is a Python script that parses the ARM template and extracts the necessary information to create the Azure Firewall rules in Terraform. This script outputs two files with the .hcl formatted network and application rules

## Getting Started
1. Clone the repo
1. Modify the environment variables in the .env_template file and rename to .env
1. Add environment variables to gitlab CI/CD variables using ```scripts/ci/add_project_vars.py```
1. Run the ```parse_rules.py``` script to generate the network and application .hcl formatted files
1. Copy the network and application rules to ```terraform/main.tf```
1. Push this repo to your Gitlab repo to trigger a pipeline that will deploy the Azure Firewall and rules

## Roadmap
- [ ] use terraform templatefile to dynamically create firewall rules
- [ ] integrate a parent-child pipeline to deploy AVD workspace and hostpool after firewall is deployed
- [ ] trigger a another child pipeline to audit/pentest the firewall deployment
- [ ] add LAW to policy analytics
