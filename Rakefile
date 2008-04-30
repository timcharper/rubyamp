require 'rubygems'
require 'rake'
require 'rake/testtask'

APP_NAME='RubyAMP.tmbundle'
APP_ROOT=File.dirname(__FILE__)

RUBY_APP='ruby'

desc "TMBundle Test Task"
task :default => [ :test ]
Rake::TestTask.new { |t|
  t.libs << "test"
  t.pattern = 'Support/test/test_*.rb'
  t.verbose = true
  t.warning = false
}
Dir['Support/tasks/**/*.rake'].each { |file| load file }
