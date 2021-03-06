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
  module Converters
    describe Converter do
      before do
        @converter = Converter.new
      end

      describe '#patches' do
        it 'return empty array never call add_patch' do
          expect(@converter.patches).to eq([])
        end

        it 'return patches that are appended by #add_patch' do
          @converter.add_patch Patches::RemoveResource.new 'dummy_resource'
          @converter.add_patch Patches::RemoveProperty.new 'Dummy', 'Dummy'
          expect(@converter.patches.size).to eq(2)
          expect(@converter.patches.all? { |patch| patch.is_a? Patches::Patch }).to be_truthy
        end
      end

      describe '#convert' do
        it 'call Patch#ensure on added patches' do
          patch1 = Patches::RemoveResource.new 'dummy_resource'
          patch2 = Patches::RemoveProperty.new 'Dummy', 'Dummy'

          expect(patch1).to receive(:ensure).and_call_original
          expect(patch2).to receive(:ensure).and_call_original

          @converter.add_patch patch1
          @converter.add_patch patch2
          @converter.convert({}, {})
        end

        it 'call Patch#apply on added patches' do
          patch1 = Patches::RemoveResource.new 'dummy_resource'
          patch2 = Patches::RemoveProperty.new 'Dummy', 'Dummy'

          expect(patch1).to receive(:apply).and_return({})
          expect(patch2).to receive(:apply).and_return({})

          @converter.add_patch patch1
          @converter.add_patch patch2
          @converter.convert({}, {})
        end

        it 'doesn\'t call Patch#apply if Patch#need? return false' do
          class Patches::DummyPatch < Patches::Patch # rubocop:disable ClassAndModuleChildren
            def initialize
            end

            def need?(_template, _parameters)
              false
            end
          end

          patch1 = Patches::DummyPatch.new
          patch2 = Patches::RemoveProperty.new 'Dummy', 'Dummy'

          expect(patch1).not_to receive(:apply)
          expect(patch2).to receive(:apply)

          @converter.add_patch patch1
          @converter.add_patch patch2
          @converter.convert({}, {})
        end
      end

      describe '#convert_from_file' do
        before do
          allow(File).to receive_message_chain(:open, :read).and_return('{ "dummy_key": "dummy_value" }')
        end

        it 'call File open and read' do
          expect(File).to receive(:open).with('dummy_template.json')

          @converter.convert_from_file('dummy_template.json', {})
        end

        it 'call convert' do
          expect(@converter).to receive(:convert).with('{ "dummy_key": "dummy_value" }', parameter_key: 'parameter_value')

          @converter.convert_from_file('dummy_template.json', parameter_key: 'parameter_value')
        end
      end

      describe '#ensure_hash' do
        it 'doesn\'t affect argument if argument is already hash' do
          template = {}
          result = @converter.ensure_hash(template)

          expect(result).to be_is_a(Hash)
        end

        it 'convert template to hash if argument is string' do
          template = <<-EOS
            {
              "dummy": "dummy_value"
            }
          EOS

          result = @converter.ensure_hash(template)
          expect(result).to be_is_a(Hash)
          expect(result[:dummy]).to eq('dummy_value')
        end
      end

      describe '#sort' do
        def dummy_patch(name, dependencies = [])
          klass = Class.new(Patches::Patch) do
            def initialize
            end

            define_method :dependencies do
              dependencies
            end
          end

          Patches.class_eval do
            remove_const name if const_defined? name
          end

          Patches.const_set name, klass
          Patches.const_get(name)
        end

        it 'return patches when all patches are independent' do
          patch1 = dummy_patch('Patch1').new
          patch2 = dummy_patch('Patch2').new
          patch3 = dummy_patch('Patch3').new

          @converter.add_patch patch1
          @converter.add_patch patch2
          @converter.add_patch patch3

          sorted_patches = @converter.patches.sort
          expect(sorted_patches).to match_array([patch1, patch2, patch3])
        end

        it 'sort patches order by dependencies of each patch' do
          patch1 = dummy_patch('Patch1', [:Patch2]).new
          patch2 = dummy_patch('Patch2', [:Patch3]).new
          patch3 = dummy_patch('Patch3').new

          @converter.add_patch patch1
          @converter.add_patch patch2
          @converter.add_patch patch3

          sorted_patches = @converter.patches.sort
          expect(sorted_patches).to eq([patch3, patch2, patch1])
        end

        it 'raise error when patches has circular dependencies' do
          patch1 = dummy_patch('Patch1', [:Patch2]).new
          patch2 = dummy_patch('Patch2', [:Patch3]).new
          patch3 = dummy_patch('Patch3', [:Patch1]).new

          @converter.add_patch patch1
          @converter.add_patch patch2
          @converter.add_patch patch3

          expect { @converter.patches.sort }.to raise_error('Circular dependencies [Patch1, Patch2, Patch3]')
        end

        it 'sort patches order by complex dependencies of each patch' do
          patch1 = dummy_patch('Patch1', [:Patch2, :Patch3, :Patch5]).new
          patch2 = dummy_patch('Patch2', [:Patch3]).new
          patch3 = dummy_patch('Patch3', [:Patch4, :Patch5]).new
          patch4 = dummy_patch('Patch4', [:Patch5]).new
          patch5 = dummy_patch('Patch5').new

          @converter.add_patch patch1
          @converter.add_patch patch2
          @converter.add_patch patch3
          @converter.add_patch patch4
          @converter.add_patch patch5

          expect(@converter.patches).to eq([patch1, patch2, patch3, patch4, patch5])

          sorted_patches = @converter.patches.sort
          expect(sorted_patches).to eq([patch5, patch4, patch3, patch2, patch1])

          expect(@converter.patches).to eq([patch1, patch2, patch3, patch4, patch5])
        end

        it 'sort patches when patches has multiple same patches that is depended by other patch' do
          dummy_patch('Patch1')
          patch1a = Patches::Patch1.new
          patch2 = dummy_patch('Patch2', [:Patch1]).new
          patch1b = Patches::Patch1.new
          patch1c = Patches::Patch1.new

          @converter.add_patch patch1a
          @converter.add_patch patch2
          @converter.add_patch patch1b
          @converter.add_patch patch1c

          sorted_patches = @converter.patches.sort
          expect(sorted_patches).to eq([patch1a, patch1b, patch1c, patch2])
        end
      end
    end
  end
end
