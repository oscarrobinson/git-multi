#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'git/meta'
require 'slop'

options = Slop.parse do |o|
  o.on '-V', '--version', 'print the version of git-meta' do
    Git::Meta::Commands.version
  end
end

# That's all, Folks
