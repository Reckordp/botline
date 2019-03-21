ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
ENV['LINE_CHANNEL_SECRET'] = '66a18397b274e6c8ef5c6bf9ef5c3c69'
ENV['LINE_CHANNEL_TOKEN'] = 'vuuCzI8d5uwPulk0gyHFWg0q+gXDGVcdXj+HMky+MX/JLWtL6CXxwmzxL0WvPspgeHKUmmrNr3DLdAAkwjkvi3qNRQzT5BgkuOezj73GWbhJfKIOsV1bKKU+HvVDu/DkZq2vi6FtZAaQiPMW4Pvr2gdB04t89/1O/w1cDnyilFU='

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
