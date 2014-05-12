require 'faye_publisher'

class ClientCommand < FayePublisher
  def bayeux_channel
    '/commands'
  end

  def self.exec(command)
    cc = new
    cc.publish( command: command )
  end
end
