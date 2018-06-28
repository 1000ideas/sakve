require 'rubygems'
require 'yaml'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

env_file = File.expand_path(File.join('..', '..', 'config', 'local_environment.yml'), __FILE__)
YAML.load(File.open(env_file)).each do |key, value|

    normalized_value = case value.to_s
        when "false"
        when "~"
          ""
        else
          value.to_s
        end

    if normalized_value != ""
        ENV[key.to_s] = normalized_value
    end

end if File.exists?(env_file)