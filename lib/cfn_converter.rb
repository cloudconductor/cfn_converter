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
require 'active_support'
require 'active_support/core_ext'
require 'cfn_converter/version'
require 'cfn_converter/cli'
require 'cfn_converter/patches'
require 'cfn_converter/converters'

module CfnConverter
  def self.create_converter(converter)
    case converter
    when Symbol then create_converter_from_type(converter)
    when String then create_converter_from_class_name(converter)
    else fail "Unsupported type(#{converter.class})"
    end
  end

  private

  def self.create_converter_from_type(type)
    case type
    when :heat, :open_stack, :openstack then CfnConverter::Converters::OpenStackConverter.new
    else fail "Unsupported converter type(#{type})"
    end
  end

  def self.create_converter_from_class_name(class_name)
    class_name.classify.constantize.new
  end
end
