module RedisTestSetup

  def self.start_redis!(rails_root, env)
    dir_temp = File.expand_path(File.join(rails_root, 'tmp'))
    dir_conf = File.expand_path(File.join(rails_root, 'config'))
    cwd = Dir.getwd
    Dir.chdir(rails_root)
    self.cleanup(dir_temp, env)
    raise "unable to launch redis-server" unless system("redis-server #{dir_conf}/redis-#{env}.conf")
    Dir.chdir(cwd)
    Kernel.at_exit do
      if (pid = `cat #{dir_temp}/redis-#{env}.pid`.strip) =~ /^\d+$/
        self.cleanup(dir_temp, env)
        Process.kill("KILL", pid.to_i)
      end
    end
  end

  def self.cleanup(dir_temp, env)
    `rm -f #{dir_temp}/redis-#{env}-dump.rdb`
    `rm -f #{dir_temp}/redis-#{env}.pid`
  end
end
