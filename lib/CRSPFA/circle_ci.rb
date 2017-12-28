require 'singleton'

class CRSPFA::CircleCi
  include Singleton

  def token
    @_token ||= File.read("#{Dir.home}/.circleci.token")
  end
end
