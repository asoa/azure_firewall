#!/usr/bin/env python3 

import json
import requests
from dotenv import load_dotenv
import os

class Rules:
  def __init__(self, **kwargs):
    # class variables
    self.kwargs = {k:v for k,v in kwargs.items()}
    self.url = self.kwargs.get('url')
    self.rules = []
    self.network_rules = []
    self.application_rules = []

    # method calls
    if self.kwargs.get('download'):
      print("Downloading rules...")
      self.download_rules()
    self.parse_rules()
    self.format_network_rules()
    self.format_application_rules()
    self.write_output()

  def download_rules(self):
    response = requests.get(self.url)
    with open('fw_rules/rules.json', 'w') as f:
      f.write(response.text)

  def parse_rules(self):
    rules = []
    with open('fw_rules/rules.json') as f:
      data = json.load(f)
      avd_core_network_rules = data['resources'][1]['properties']['ruleCollections'][0]['rules']
      avd_optional_network_rules = data['resources'][2]['properties']['ruleCollections'][0]['rules']
      avd_optional_application_rules = data['resources'][2]['properties']['ruleCollections'][1]['rules']

      self.rules.append(avd_core_network_rules)
      self.rules.append(avd_optional_network_rules)
      self.rules.append(avd_optional_application_rules)
      # print(avd_core_network_rules)
      # print(avd_optional_network_rules)
      # print(avd_optional_application_rules)

  def format_network_rules(self):
    print("Formatting network rules...")
    rule_format = """
      rule {{
        name                  = "{}"
        protocols             = ["{}"]
        source_addresses      = ["{}"]
        destination_addresses = ["{}"]
        destination_ports     = ["{}"]
        destination_fqdns     = ["{}"]
        }}
    """
    # print(self.rules)
    network_rules = [x for x in self.rules if x[0]['ruleType'] == 'NetworkRule']
    # print(network_rules)
    for rule in network_rules[0]:
      name = rule['name']
      protocols = rule['ipProtocols'][0]
      source_addresses = os.getenv('AVD_HOSTPOOL_SUBNET')
      destination_addresses = self.change_single_quotes(rule['destinationAddresses'])
      destination_ports = rule['destinationPorts'][0]
      destination_fqdns = self.change_single_quotes(rule['destinationFqdns'])
      self.network_rules.append(rule_format.format(name, protocols, source_addresses, destination_addresses, destination_ports, destination_fqdns))
      # print(rule_format.format(name, protocols, source_addresses, destination_addresses, destination_ports))
      
  def format_application_rules(self):
    print("Formatting application rules...")
    rule_format = """
      rule {{
        name                  = "{}"
        protocols             {{
          type = "{}"
          port = {}
        }}
        source_addresses      = ["{}"]
        destination_fqdns     = ["{}"]
        }}
    """
    application_rules = [x for x in self.rules if x[0]['ruleType'] == 'ApplicationRule']
    print(application_rules)
    for rule in application_rules[0]:
      name = rule['name']
      protocol_type = rule['protocols'][0]['protocolType']
      port = rule['protocols'][0]['port']
      source_addresses = os.getenv('AVD_HOSTPOOL_SUBNET')
      destination_fqdns = self.change_single_quotes(rule['targetFqdns'])
      self.application_rules.append(rule_format.format(name, protocol_type, port, source_addresses, destination_fqdns))
      # print(rule_format.format(name, protocol_type, port, source_addresses, destination_fqdns))

  def change_single_quotes(self, string):
    if len(string) == 0:
      return ""
    return string[0]
  
  def write_output(self):
    print("Writing output...")
    with open('fw_rules/network_rules.txt', 'w') as f:
      [f.write(x) for x in self.network_rules if x != None]

    with open('fw_rules/application_rules.txt', 'w') as f:
      [f.write(x) for x in self.application_rules if x != None]

if __name__ == '__main__':
  url = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/AzureFirewallPolicyForAVD/FirewallPolicyForAVD-template.json"
  rules = Rules(url=url, download=False)