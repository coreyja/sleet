module CliHelper
  def cli_executable_path
    "#{File.expand_path(File.dirname(__FILE__))}/../../exe/sleet"
  end
end
