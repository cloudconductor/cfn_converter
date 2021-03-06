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
    describe AddIAMUser do
      before do
        @patch = AddIAMUser.new

        @template = JSON.parse <<-EOS
          {
            "Resources": {
              "Sample": {
                "Type": "AWS::EC2::RouteTable",
                "Properties": {
                  "VpcId": { "Ref": "VPC" }
                }
              },
              "LaunchConfig": {
                "Type": "AWS::AutoScaling::LaunchConfiguration",
                "Metadata" : {
                  "Comment": "Launch instance from AMI",
                  "AWS::CloudFormation::Init": {
                    "config": {
                    }
                  }
                }
              }
            }
          }
        EOS

        @template = @template.with_indifferent_access
      end

      it 'extend Patch class' do
        expect(AddIAMUser.superclass).to eq(Patch)
      end

      describe '#need?' do
        it 'return false when template hasn\'t Resources hash' do
          expect(@patch.need?({}, {})).to be_falsey
        end

        it 'return false when template hasn\'t LaunchConfiguration Resource' do
          @template[:Resources].except!(:LaunchConfig)
          expect(@patch.need?(@template, {})).to be_falsey
        end

        it 'return true when template has LaunchConfiguration Resource' do
          expect(@patch.need?(@template, {})).to be_truthy
        end
      end

      describe '#apply' do
        before do
          @patch = AddIAMUser.new
        end

        it 'add AWS::EC2::IAMUser resource' do
          expect(@template[:Resources].size).to eq(2)
          expect(@template[:Resources][:IAMUser]).to be_nil
          result = @patch.apply @template, {}
          expect(result[:Resources].size).to eq(3)
          expect(result[:Resources][:IAMUser]).not_to be_nil
        end

        it 'doesn\'t affect to other resources' do
          original = @template[:Resources][:Sample].deep_dup

          expect(@template[:Resources][:Sample]).to eq(original)
          result = @patch.apply @template, {}
          expect(result[:Resources][:Sample]).to eq(original)
        end

        it 'doesn\'t affect to source template' do
          original_template = @template.deep_dup

          expect(original_template).to eq(@template)
          @patch.apply @template, {}
          expect(original_template).to eq(@template)
        end
      end
    end
  end
end
