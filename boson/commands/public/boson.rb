module BosonLib
  # @options :editor=>ENV['EDITOR'], :string=>:string, :file=>:string, :config=>:boolean,
  #  :library=>:string, :library_command=>:string
  # Edit a file or string, boson's main config file or a boson library file
  def edit(options={})
    options[:editor] ||= ENV['EDITOR']
    file = if options[:library]
      Boson::FileLibrary.library_file(options[:library], Boson.repo.dir)
    elsif options[:library_command]
      Boson::Index.read
      (lib = Boson::Index.find_library(options[:library_command])) &&
      Boson::FileLibrary.library_file(lib, Boson.repo.dir)
    elsif options[:config]
      config_dir + '/boson.yml'
    else
      options[:file] || begin
        require 'tempfile'
        Tempfile.new('edit_string').path
      end
    end
    return puts("File '#{file}' not found.") unless File.exists? file
    File.open(file,'w') {|f| f.write(options[:string]) } if options[:string]
    system(options[:editor], file)
    File.open(file) {|f| f.read } if File.exists?(file) && options[:string]
  end

  # @render_options :method=>'puts'
  # Show a library
  def show_library(lib)
    file = Boson.repos.map {|e| Boson::FileLibrary.library_file(lib, e.dir) }.
      find {|e| File.exists?(e) }
    file ? File.read(file) : "Library file doesn't exist"
  end

  # Uninstall a library
  def uninstall(lib)
    file = Boson::FileLibrary.library_file(lib, Boson.repo.dir)
    File.unlink file
    puts("Deleted '#{file}'.")
  end

  # List libraries that haven't been loaded yet
  def unloaded_libraries
    (Boson::Runner.all_libraries - Boson.libraries.map {|e| e.name }).sort
  end

  # Prints stats about boson's index
  def stats
    Boson::Index.read
    Boson::Index.indexes.each do |repo|
      option_cmds = repo.commands.select {|e| !e.options.to_s.empty? }
      render_option_cmds = repo.commands.select {|e| !e.render_options.to_s.empty? }
      puts "\n=== Repo at #{repo.repo.dir} ==="
      render [[:libraries, repo.libraries.size], [:commands, repo.commands.size],
        [:option_commands, option_cmds.size], [:render_option_commands, render_option_cmds.size], ]
    end
    nil
  end

  # @options :all=>:boolean, :verbose=>true, :reset=>:boolean
  # Updates/resets index of libraries and commands
  def index(options={})
    Boson::Index.indexes {|index|
      File.unlink(index.marshal_file) if options[:reset] && File.exists?(index.marshal_file)
      index.update(options)
    }
  end

  # Downloads a url and saves to a local boson directory
  def download(url)
    filename = determine_download_name(url)
    File.open(filename, 'w') { |f| f.write get(url) }
    filename
  end

  # Tells you what methods in current binding aren't boson commands.
  def undetected_methods(priv=false)
    public_undetected = metaclass.instance_methods - (Kernel.instance_methods + Object.instance_methods(false) + MyCore::Object::InstanceMethods.instance_methods +
      Boson.commands.map {|e| [e.name, e.alias] }.flatten.compact)
    public_undetected -= IRB::ExtendCommandBundle.instance_eval("@ALIASES").map {|e| e[0].to_s} if Object.const_defined?(:IRB)
    priv ? (public_undetected + metaclass.private_instance_methods - (Kernel.private_instance_methods + Object.private_instance_methods)) : public_undetected
  end

  private
  # Config directory of main Boson repo
  def config_dir
    Boson.repo.config_dir
  end

  def determine_download_name(url)
    FileUtils.mkdir_p(File.join(Boson.repo.dir,'downloads'))
    basename = strip_name_from_url(url) || url.sub(/^[a-z]+:\/\//,'').tr('/','-')
    filename = File.join(Boson.repo.dir, 'downloads', basename)
    filename += "-#{Time.now.strftime("%m_%d_%y_%H_%M_%S")}" if File.exists?(filename)
    filename
  end
end
