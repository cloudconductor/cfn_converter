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
    describe Converter do
      before do
        @converter = Converter.new
      end

      describe '#patches' do
        it 'return empty array never call add_patch' do
          expect(@converter.patches).to eq([])
        end

        it 'return patches that are appended by #add_patch' do
          @converter.add_patch Patches::RemoveRoute.new
          @converter.add_patch Patches::RemoveProperty.new 'Dummy', 'Dummy'
          expect(@converter.patches.size).to eq(2)
          expect(@converter.patches.all? { |patch| patch.is_a? Patches::Patch }).to be_truthy
        end
      end

      describe '#convert' do
        it 'call Patch#ensure on added patches' do
          patch1 = Patches::RemoveRoute.new
          patch2 = Patches::RemoveProperty.new 'Dummy', 'Dummy'

          patch1.should_receive(:ensure).and_call_original
          patch2.should_receive(:ensure).and_call_original

          @converter.add_patch patch1
          @converter.add_patch patch2
          @converter.convert({}, {})
        end

        it 'call Patch#apply on added patches' do
          patch1 = Patches::RemoveRoute.new
          patch2 = Patches::RemoveProperty.new 'Dummy', 'Dummy'

          patch1.should_receive(:apply).and_return({})
          patch2.should_receive(:apply).and_return({})

          @converter.add_patch patch1
          @converter.add_patch patch2
          @converter.convert({}, {})
        end

        it 'doesn\'t call Patch#apply if Patch#need? return false' do
          # rubocop:disable ClassAndModuleChildren
          class Patches::DummyPatch < Patches::Patch
            def initialize
            end

            def need?(_template, _parameters)
              false
            end
          end

          patch1 = Patches::DummyPatch.new
          patch2 = Patches::RemoveProperty.new 'Dummy', 'Dummy'

          patch1.should_not_receive(:apply)
          patch2.should_receive(:apply)

          @converter.add_patch patch1
          @converter.add_patch patch2
          @converter.convert({}, {})
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
          Patches.const_get(name).new
        end

        it 'return patches when all patches are independent' do
          patch1 = dummy_patch 'Patch1'
          patch2 = dummy_patch 'Patch2'
          patch3 = dummy_patch 'Patch3'

          @converter.add_patch patch1
          @converter.add_patch patch2
          @converter.add_patch patch3

          sorted_patches = @converter.patches.sort
          expect(sorted_patches).to match_array([patch1, patch2, patch3])
        end

        it 'sort patches order by dependencies of each patch' do
          patch1 = dummy_patch 'Patch1', [:Patch2]
          patch2 = dummy_patch 'Patch2', [:Patch3]
          patch3 = dummy_patch 'Patch3'

          @converter.add_patch patch1
          @converter.add_patch patch2
          @converter.add_patch patch3

          sorted_patches = @converter.patches.sort
          expect(sorted_patches).to match_array([patch3, patch2, patch1])
        end

        it 'raise error when patches has circular dependencies' do
          patch1 = dummy_patch 'Patch1', [:Patch2]
          patch2 = dummy_patch 'Patch2', [:Patch3]
          patch3 = dummy_patch 'Patch3', [:Patch1]

          @converter.add_patch patch1
          @converter.add_patch patch2
          @converter.add_patch patch3

          expect { @converter.patches.sort }.to raise_error('Circular dependencies [Patch1, Patch2, Patch3]')
        end

        it 'sort patches order by complex dependencies of each patch' do
          patch1 = dummy_patch 'Patch1', [:Patch2, :Patch3, :Patch5]
          patch2 = dummy_patch 'Patch2', [:Patch3]
          patch3 = dummy_patch 'Patch3', [:Patch4, :Patch5]
          patch4 = dummy_patch 'Patch4', [:Patch5]
          patch5 = dummy_patch 'Patch5'

          @converter.add_patch patch1
          @converter.add_patch patch2
          @converter.add_patch patch3
          @converter.add_patch patch4
          @converter.add_patch patch5

          expect(@converter.patches).to eq([patch1, patch2, patch3, patch4, patch5])
          sorted_patches = @converter.patches.sort
          expect(sorted_patches).to match_array([patch5, patch4, patch3, patch2, patch1])
          expect(@converter.patches).to eq([patch1, patch2, patch3, patch4, patch5])
        end
      end
    end
  end
end
