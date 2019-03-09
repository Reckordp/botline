ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
ENV['LINE_CHANNEL_SECRET'] = '66a18397b274e6c8ef5c6bf9ef5c3c69'
ENV['LINE_CHANNEL_TOKEN'] = 'TPYbSlZ2c4yXEuSDnAapbPJsxuvimMF8C8i4q+W6YoIYKJGmqcSiRPrpDzVmyDNVeHKUmmrNr3DLdAAkwjkvi3qNRQzT5BgkuOezj73GWbgSTwsD1FHZRUqmCq+p8xJGCZ2zFqXgWWXxiRYWcF02iwdB04t89/1O/w1cDnyilFU='


require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
