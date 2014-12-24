# CfnConverter

A tool converting "AWS CloudFormation Template" to another cloud orchestrator template

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cfn_converter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cfn_converter

## Usage

```bash
cfn2heat cloudformation_template_filename
```

This command is the same of below command:

```bash
cfnconv CfnConverter::Converters::OpenStackConverter cloudformation_template_filename
```

If you wrote your own converter class, you can execute your converter as below:

```bash
cfnconv YOUR_OWN_CONVERTER_CLASS cloudformation_template_filename
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/cfn_converter/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
