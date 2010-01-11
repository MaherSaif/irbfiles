module RailsLib
  def self.append_features(mod)
    super if ENV['RAILS_ENV']
  end

  def self.after_included
    IRB_PROCS[:setup_personal] = method(:setup_personal) if Object.const_defined?(:IRB_PROCS)

    old_config = ::Hirb.config
    if ::Hirb::View.enabled?
      ::Hirb.disable
      ::Hirb.config_file = 'config/hirb.yml'
      ::Hirb.config(true)
    end
    ::Hirb.enable old_config
  end

  def self.setup_personal(*args)
    Alias.create :file=>"~/.alias/rails.yml"
    require 'console_update' #gem install cldwalker-console_update
    ConsoleUpdate.enable_named_scope
  end
end
