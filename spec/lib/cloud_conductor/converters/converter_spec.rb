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
          @converter.add_patch Patches::RemoveMultipleSubnet.new
          expect(@converter.patches.size).to eq(2)
          expect(@converter.patches.all? { |patch| patch.is_a? Patches::Patch }).to be_true
        end
      end
    end
  end
end
