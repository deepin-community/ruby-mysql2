CLEAN = Rake::FileList.new
load File.dirname(__FILE__) + "/../tasks/rspec.rake"

task :default => ["spec/configuration.yml", "spec/my.cnf"] do
  ruby = RbConfig::CONFIG['ruby_install_name']
  sh "./debian/start_mysqld_and_run.sh #{ruby} -S rspec"
end
