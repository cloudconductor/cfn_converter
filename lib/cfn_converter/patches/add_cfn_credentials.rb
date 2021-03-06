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
module CfnConverter
  module Patches
    class AddCFNCredentials < Patch
      include PatchUtils

      def initialize
      end

      def dependencies
        [:AddIAMAccessKey]
      end

      def need?(template, _parameters)
        return false unless template[:Resources]
        !template[:Resources].select(&type?('AWS::AutoScaling::LaunchConfiguration')).empty?
      end

      def ensure(template, _parameters)
        template[:Resources] ||= {}
        template[:Resources].select(&type?('AWS::AutoScaling::LaunchConfiguration')).keys.each do |key|
          template[:Resources][key] ||= {}
          template[:Resources][key][:Metadata] ||= {}
          template[:Resources][key][:Metadata]['AWS::CloudFormation::Init'] ||= {}
          template[:Resources][key][:Metadata]['AWS::CloudFormation::Init'][:config] ||= {}
        end
        template
      end

      def apply(template, _parameters)
        files = JSON.parse <<-'EOS'
          {
            "files" : {
              "/etc/cfn/cfn-credentials" : {
                "content" : { "Fn::Join" : ["", [
                  "AWSAccessKeyId=", { "Ref" : "IAMKey" }, "\n",
                  "AWSSecretKey=", {"Fn::GetAtt": ["IAMKey", "SecretAccessKey"]}, "\n"
                ]]},
                "mode"    : "000400",
                "owner"   : "root",
                "group"   : "root"
              }
            }
          }
        EOS

        template = template.deep_dup
        template[:Resources].select(&type?('AWS::AutoScaling::LaunchConfiguration')).keys.each do |key|
          template[:Resources][key][:Metadata]['AWS::CloudFormation::Init'][:config].update files
        end

        template
      end
    end
  end
end
