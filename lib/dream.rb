
module Dream

  require_relative "dream/version"
  require_relative "dream/errors"

  autoload :Shell,      "berkshelf/shell"

  class << self
    # @return [Berkshelf::Shell]
    def ui
      @ui ||= Berkshelf::Shell.new
    end
  end
end

require_relative "dream/cli"