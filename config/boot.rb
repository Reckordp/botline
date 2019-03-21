ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
ENV['LINE_CHANNEL_SECRET'] = '38e6f9d072e1cdd0fa2f52bf06afacec'
ENV['LINE_CHANNEL_TOKEN'] = 'Kx2G/JhhjWxWbU1oOxdiZ/RAQu4Hlk8tuUvjyuF4WORrqsSWtfnFjHZPZSmkOuevdyanNjKx4MDVSDXTEjdD8+/AKq93RdcsZs+Dw3HcZyQRJjbqDexma0V4B1dJmj/J3ot+brUsw+3YzHnPnxfc0QdB04t89/1O/w1cDnyilFU='

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
