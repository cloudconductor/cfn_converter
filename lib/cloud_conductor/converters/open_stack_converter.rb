# -*- coding: utf-8 -*-
# Copyright 2014 TIS Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
module CloudConductor
  module Converters
    class OpenStackConverter < Converter
      # rubocop:disable MethodLength
      def initialize
        super

        # Remove unimplemented properties
        remove_auto_scaling_group_properties
        remove_launch_configuration_properties
        remove_instance_properties
        remove_network_interface_properties
        remove_vpc_properties
        remove_vpc_gateway_attachment_properties
        remove_load_balancer_properties
        remove_access_key_properties

        add_patch Patches::RemoveRoute.new
        add_patch Patches::RemoveMultipleSubnet.new
        add_patch Patches::AddIAMUser.new
        add_patch Patches::AddIAMAccessKey.new
        add_patch Patches::AddCFNCredentials.new
      end

      # Remove unimplemented properties from AutoScalingGroup
      def remove_auto_scaling_group_properties
        properties = []
        properties << :HealthCheckGracePeriod
        properties << :HealthCheckType
        add_patch Patches::RemoveProperty.new 'AWS::AutoScaling::AutoScalingGroup', properties
      end

      # Remove unimplemented properties from LaunchConfiguration
      def remove_launch_configuration_properties
        properties = []
        properties << :BlockDeviceMappings
        properties << :KernelId
        properties << :RamDiskId
        add_patch Patches::RemoveProperty.new 'AWS::AutoScaling::LaunchConfiguration', properties
      end

      # Remove unimplemented properties from Instance
      def remove_instance_properties
        properties = []
        properties << :DisableApiTermination
        properties << :KernelId
        properties << :Monitoring
        properties << :PlacementGroupName
        properties << :PrivateIpAddress
        properties << :RamDiskId
        properties << :SourceDestCheck
        properties << :Tenancy
        add_patch Patches::RemoveProperty.new 'AWS::EC2::Instance', properties
      end

      # Remove unimplemented properties from NetworkInterface
      def remove_network_interface_properties
        properties = []
        properties << :SourceDestCheck
        add_patch Patches::RemoveProperty.new 'AWS::EC2::NetworkInterface', properties
      end

      # Remove unimplemented properties from VPC
      def remove_vpc_properties
        properties = []
        properties << :InstanceTenancy
        add_patch Patches::RemoveProperty.new 'AWS::EC2::VPC', properties
      end

      # Remove unimplemented properties from VPCGatewayAttachment
      def remove_vpc_gateway_attachment_properties
        properties = []
        properties << :VpnGatewayId
        add_patch Patches::RemoveProperty.new 'AWS::EC2::VPCGatewayAttachment', properties
      end

      # Remove unimplemented properties from LoadBalancer
      def remove_load_balancer_properties
        properties = []
        properties << :AppCookieStickinessPolicy
        properties << :LBCookieStickinessPolicy
        properties << :SecurityGroups
        properties << :Subnets
        add_patch Patches::RemoveProperty.new 'AWS::ElasticLoadBalancing::LoadBalancer', properties
      end

      # Remove unimplemented properties from AccessKey
      def remove_access_key_properties
        properties = []
        properties << :Serial
        properties << :Status
        add_patch Patches::RemoveProperty.new 'AWS::IAM::AccessKey', properties
      end
    end
  end
end
