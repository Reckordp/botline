ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
ENV['LINE_CHANNEL_SECRET'] = '38e6f9d072e1cdd0fa2f52bf06afacec'
ENV['LINE_CHANNEL_TOKEN'] = 'vuuCzI8d5uwPulk0gyHFWg0q+gXDGVcdXj+HMky+MX/JLWtL6CXxwmzxL0WvPspgeHKUmmrNr3DLdAAkwjkvi3qNRQzT5BgkuOezj73GWbhJfKIOsV1bKKU+HvVDu/DkZq2vi6FtZAaQiPMW4Pvr2gdB04t89/1O/w1cDnyilFU='

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
