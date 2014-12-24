describe CfnConverter do
  describe '.create_converter' do
    it 'call createConverterFromType if argument class is Symbol' do
      expect(CfnConverter).to receive(:create_converter_from_type)

      CfnConverter.create_converter(:dummy)
    end

    it 'call createConverterFromClassName if argument class is String' do
      expect(CfnConverter).to receive(:create_converter_from_class_name)

      CfnConverter.create_converter('dummy')
    end

    it 'fail if argument class is unsupported' do
      expect { CfnConverter.create_converter(1234) }.to raise_error(RuntimeError, 'Unsupported type(Fixnum)')
    end
  end

  describe '.create_converter_from_type' do
    it 'return OpenStackConverter instance if argument type equal :heat' do
      expect(CfnConverter.create_converter_from_type(:heat)).to be_is_a(CfnConverter::Converters::OpenStackConverter)
    end

    it 'return OpenStackConverter instance if argument type equal :open_stack' do
      expect(CfnConverter.create_converter_from_type(:open_stack)).to be_is_a(CfnConverter::Converters::OpenStackConverter)
    end

    it 'return OpenStackConverter instance if argument type equal :openstack' do
      expect(CfnConverter.create_converter_from_type(:openstack)).to be_is_a(CfnConverter::Converters::OpenStackConverter)
    end

    it 'fail if argument type is unsupported' do
      expect { CfnConverter.create_converter_from_type(:dummy) }.to raise_error(RuntimeError, 'Unsupported converter type(dummy)')
    end
  end

  describe '.create_converter_from_class_name' do
    it 'return instantiate an argument' do
      instance = CfnConverter.create_converter_from_class_name('CfnConverter::Converters::OpenStackConverter')
      expect(instance).to be_is_a(CfnConverter::Converters::OpenStackConverter)
    end

    it 'fail if fail to instantiate' do
      expect { CfnConverter.create_converter_from_class_name('dummy') }.to raise_error(NameError)
    end
  end
end
