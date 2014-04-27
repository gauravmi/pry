class Pry
  class Command::ReloadCode < Pry::ClassCommand
    match 'reload-code'
    group 'Misc'
    description 'Reload the source file that contains the specified code object.'

    banner <<-'BANNER'
      Reload the source file that contains the specified code object.

      e.g reload-code MyClass#my_method    #=> reload a method
          reload-code MyClass              #=> reload a class
          reload-code my-command           #=> reload a pry command
          reload-code self                 #=> reload the 'current' object
          reload-code                      #=> identical to reload-code self
    BANNER

    def process
      if !args.empty?
        reload_object(args.join(" "))
      elsif Class === target.eval("self")
        reload_object("self")
      else
        reload_current_file
      end
    end

    private

    def current_file
      File.expand_path target.eval("__FILE__")
    end

    def reload_current_file
      if !File.exists?(current_file)
        raise CommandError, "Current file: #{current_file} cannot be found on disk!"
      end

      load current_file
      output.puts "The current file: #{current_file} was reloaded!"
    end

    def reload_object(identifier)
      code_object = Pry::CodeObject.lookup(identifier, _pry_)
      check_for_reloadability(code_object, identifier)
      load code_object.source_file
      output.puts "#{identifier} was reloaded!"
    end

    def check_for_reloadability(code_object, identifier)
      if !code_object || !code_object.source_file
        raise CommandError, "Cannot locate #{identifier}!"
      elsif !File.exists?(code_object.source_file)
        raise CommandError,
          "Cannot reload #{identifier} as it has no associated file on disk. " \
          "File found was: #{code_object.source_file}"
      end
    end
  end

  Pry::Commands.add_command(Pry::Command::ReloadCode)
  Pry::Commands.alias_command 'reload-method', 'reload-code'
end
