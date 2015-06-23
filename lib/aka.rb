require "aka/version"
require 'net/scp'
require 'open-uri'
require 'colorize'
require "safe_yaml/load"
require 'thor'

module Aka
  class Base < Thor
    check_unknown_options!
    package_name "aka"
    default_task :list
    map "dl" => "download",
        "g" => "generate",
        "d" => "destroy",
        "f" => "find",
        "up" => "upload",
        "u" => "usage",
        "l" => "list",
        "e" => "edit",
        "c" => "clean"


    #
    # Demo testing
    #
    desc 'demo', 'To test out Thor'
    def show()
      puts "Demo success"
    end


    #
    # DOWNLOAD
    # aka download --to ~/Desktop/ --login admin@162.243.249.154:22000 --from /home/admin/hello  desc "download [path]", "download a dot file"
    desc "download", "download dotfile from server"
    method_options :from => :string
    method_options :to => :string
    method_options :login => :string
    def download
      if options.from and options.to and options.login
        success = true
        arr = split(options.login)
        pw = get_password()
        begin
          result = Net::SCP.download!(arr[1], #remote
          arr.first,#username
          options.from, #remote_path
          options.to, #local_path
          :ssh => {:password => pw,
                   :port => arr[2]})
        rescue Exception => e
           puts "\n#{e}"
           success = false
        end
        puts "\nDone." if success
      else
        puts "Some options are missing."
        puts "--login: #{options.login}"
        puts "--to: #{options.to}"
        puts "--from: #{options.from}"
        puts "aka dl --login some_login_string --to some_local_path_string --from some_remote_path_string"
      end
    end

    #
    # UPLOAD
    #
    #aka upload --from ~/Desktop/TwitterAPI.rb --login admin@162.243.249.154:22000  --to /home/admin
    desc "upload", "upload a dot file"
    method_options :from => :string
    method_options :to => :string
    method_options :login => :string
    def upload
      if options.from and options.to and options.login
        password = get_password()

        if File.exists?(options.from)
          success = true
          begin
            arr = split(options.login)
            result = Net::SCP.upload!(arr[1], #remote
            arr.first, #username
            options.from, #local_path
            options.to, #remote_path
            :ssh => {:port => arr[2],
                     :password => password})
          rescue Exception => e
            puts "\n#{e}"
            success = false
          end

          puts "\nDone." if success
        else
          puts "Cannot find #{options.from}"
        end
      else
        puts "Some options are missing:"
        puts "--of -> #{options.of}"
        puts "--to -> #{options.to}"
        puts "--from -> #{options.from}"
        puts "aka up --of some_string --to some_string --from some_string"
      end
    end

    #
    # GENERATE
    #
    desc "generate", "generate an alias (short alias: g)"
    method_options :last => :boolean
    def generate args
      result = false
      if options.last?
        result = add(add_last_command(parseARGS(args))) if args
      else
        result = add(parseARGS(args)) if args
        if options.proj? and result == true
          FileUtils.touch("#{Dir.pwd}/.aka")
          add_to_proj(args)
        end
      end
      reload_dot_file if result == true and !options.noreload
    end

    #
    # DESTROY
    #
    desc "destroy", "destroy an alias (short alias: d)"
    method_options :force => :boolean
    def destroy(*args)
      args.each_with_index do |value, index|
        result = remove(value)
        unalias_the(value) if !options.nounalias and result == true
        reload_dot_file if result == true and !options.noreload
      end
    end

    #
    # SETUP
    #
    desc "setup", "setup aka"
    method_options :force => :boolean
    def setup
      setup_aka
    end

    #
    # FIND
    #
    desc "find", "find an alias (short alias: f)"
    method_options :force => :boolean
    def find *args
      args.each_with_index do |value, index|
        show_alias(value)
      end
    end

    #
    # EDIT
    #
    desc "edit", "edit an alias(short alias: e)"
    method_options :force => :boolean
    def edit args
      if args
        values = args.split("=")
        if values.size > 1
          truth, _alias = show_alias(args)
          if truth == true
            if options.name
              remove(_alias) #remove that alias
              edit_alias(values[1], _alias) #edit that alias
              reload_dot_file() if !options.noreload
            else
              remove(_alias) #remove that alias
              edit_this(values[1], _alias) #edit that alias
              reload_dot_file() if !options.noreload
            end
          else
            puts "Alias '#{args}' cannot be found".red
          end
        else
          truth, _alias, command = show_alias(args)
          if truth == true
            if options.name
              input = ask "Enter a new alias for command '#{command}'?\n"
              if yes? "Please confirm the new alias? (y/N)"
                remove(_alias) #remove that alias
                edit_alias(input, _alias) #edit that alias
                reload_dot_file() if !options.noreload
              end
            else
              input = ask "Enter a new command for alias '#{args}'?\n"
              if yes? "Please confirm the new command? (y/N)"
                remove(_alias) #remove that alias
                edit_this(input, _alias) #edit that alias
                reload_dot_file() if !options.noreload
              end
            end
          else
            puts "Alias '#{args}' cannot be found".red
          end
        end

      end #if args
    end

    #
    # LIST OUT
    #
    desc "list", "list alias (short alias: l)"
    method_options :force => :boolean
    def list(args=nil)
      if args != nil
        # showlast(args.to_i)
      else
        # value = readYML("#{Dir.home}/.aka/.config")["list"]
        # showlast(value.to_i) #this is unsafe
      end

      #total of #{} exports #functions
      puts "A total of #{count()} aliases,#{count_export} exports and #{count_function} functions from #{readYML("#{Dir.home}/.aka/.config")["dotfile"]}"
      reload_dot_file
    end

    #
    # USAGE
    #
    desc "usage [number]", "show commands usage based on history"
    # method_options :least, :type => :boolean, :aliases => '-l', :desc => 'show the least used commands'
    # method_options :clear, :type => :boolean, :aliases => '-c', :desc => 'clear the dot history file'
    def usage(args=nil)
      if args
        if options.least
          showUsage(args.to_i, true) if args
        else
          showUsage(args.to_i) if args
        end
      else
        if options.least
          value = readYML("#{Dir.home}/.aka/.config")["usage"]
          showlast(value.to_i, true) #this is unsafe
        else
          value = readYML("#{Dir.home}/.aka/.config")["usage"]
          showlast(value.to_i) #this is unsafe
        end
      end

      if options[:clear]
        puts "clear the dot history file"
      end
    end

    #
    # INSTALL
    #
    desc "install [name]", "install aka"
    method_options :force => :boolean
    def install
      if File.exist? "#{Dir.pwd}/aka"
        if File.exist? "/usr/local/bin/aka"
          if  yes? "aka exists. Do you want to replace it? (yN)"
            FileUtils.rm("/usr/local/bin/aka")
            system("ln -s #{Dir.pwd}/aka /usr/local/bin/aka")
            puts "aka replaced."
          end
        else
          result = system("ln -s #{Dir.pwd}/aka /usr/local/bin/aka")
          puts "aka installed."
        end
      else
        puts "Cannot find aka.".red
      end
    end

    #
    # INIT
    #
    desc "init", "setup aka"
    method_options :dotfile => :string
    method_options :history => :string
    method_options :home => :string
    method_options :install => :string
    method_options :profile => :string
    method_options :list => :numeric
    method_options :usage => :numeric
    method_options :remote => :string
    method_options :config => :boolean
    method_options :zshrc => :boolean
    method_options :bashrc => :boolean
    method_options :bash => :boolean

    def init
      if options.count < 1
        setup
      else
        setZSHRC if options[:zshrc]
        setBASHRC if options[:bashrc]
        setBASH if options[:bash]

        showConfig if options[:config]
        setPath(options[:dotfile],"dotfile") if options[:dotfile]
        setPath(options[:history],"history") if options[:history]
        setPath(options[:home],"home") if options[:home]
        setPath(options[:install],"install") if options[:install]
        setPath(options[:profile],"profile") if options[:profile]
        setPath(options[:list],"list") if options[:list]
        setPath(options[:usage],"usage") if options[:usage]
        setPath(options[:remote],"remote") if options[:remote]
      end
    end

    #
    # CLEAN
    #
    desc "clean", "perform cleanup"
    def clean
      cleanup
    end

    #
    # PRIVATE METHODS
    #

    private

    # set path
    def setPath(path, value)
      data = readYML("#{Dir.home}/.aka/.config")
      if data.has_key?(value) == true
        old_path = data[value]
        data[value] = path
        writeYML("#{Dir.home}/.aka/.config", data)
        puts "#{value} -> #{path}"
      else
        puts "error: --#{value} does not exist in #{Dir.home}/.aka/.config "
      end
    end

    # reload
    def reload
      system "source #{readYML("#{Dir.home}/.aka/.config")["dotfile"]}"
    end

    # read YML
    def readYML path
      if File.exists? path
        return YAML.load_file(path)
      else
        puts "#{Dir.home}/.aka/.config does not exist. You need to create one, type `touch ~/.aka/.config` and copy https://github.com/ytbryan/aka/blob/master/.config".red
      end
    end

    # write YML
    def writeYML path, theyml
      File.open(path, 'w') {|f| f.write theyml.to_yaml } #Store
    end

    # write_with
    def write_with array
      str = checkConfigFile(readYML("#{Dir.home}/.aka/.config")["dotfile"])

      File.open(str, 'w') { |file|
        array.each do |line|
          file.write(line)
        end
      }
    end

    # write_with_newline
    def write_with_newline array
      str = checkConfigFile(readYML("#{Dir.home}/.aka/.config")["dotfile"])

      File.open(str, 'w') { |file|
        array.each do |line|
          file.write(line + "\n")
        end
      }
    end

    # write
    def write str, path
      File.open(path, 'w') { |file| file.write(str) }
    end

    # append
    def append str, path
      File.open(path, 'a') { |file| file.write(str) }
    end

    #append_with_newline
    def append_with_newline str, path
      File.open(path, 'a') { |file| file.write(str + "\n") }
    end

    # reload_dot_file
    def reload_dot_file
      if isOhMyZsh == true
        system("exec zsh")
      else
        system("kill -SIGUSR1 #{Process.ppid}")
      end
    end

    # history write
    def historywrite
      if isOhMyZsh == true
        system("exec zsh")
      else
        system "kill -SIGUSR2 #{Process.ppid}"
      end
    end

    # unalias
    def unalias_the value
      if isOhMyZsh == true
        system("exec zsh")
      else
        system "echo '#{value}' > ~/sigusr1-args;"
        system "kill -SIGUSR2 #{Process.ppid}"
      end
    end

    #split domain user
    def split_domain_user fulldomain
      username = fulldomain.split("@").first
      domain = fulldomain.split("@")[1]
      return [username, domain]
    end

    # split
    def split fulldomain
      username = fulldomain.split("@").first
      domain = fulldomain.split("@")[1].split(":").first
      port = fulldomain.split("@")[1].split(":")[1]
      return [username, domain, port]
    end

    # add
    def add input
      if input and show_alias(input).first == false and not_empty_alias(input) == false
        array = input.split("=")
        full_command = "alias #{array.first}='#{array[1]}'".gsub("\n","") #remove new line in command
        print_out_command = "aka g #{array.first}='#{array[1]}'"

        str = checkConfigFile(readYML("#{Dir.home}/.aka/.config")["dotfile"])

        File.open(str, 'a') { |file| file.write("\n" +full_command) }
        puts "#{print_out_command} is added to #{readYML("#{Dir.home}/.aka/.config")["dotfile"]}"
        return true
      else
        puts "The alias is already present."
        return false
      end
    end

    # not empty alias
    def not_empty_alias input
      array = input.split("=")
      return true if array.count < 2
      return array[1].strip == ""
    end

    # show alias
    def show_alias argument
      str = checkConfigFile(readYML("#{Dir.home}/.aka/.config")["dotfile"])

      if content = File.open(str).read
        content.gsub!(/\r\n?/, "\n")
        content_array = content.split("\n")
        content_array.each_with_index { |line, index|
          value = line.split(" ")
          if value.length > 1 and value.first == "alias"
            answer = value[1].split("=")
            if found?(answer.first, argument.split("=").first, line) == true
              return [true, answer.first, answer[1]]
            end
          end
        }
      else
        puts "#{@pwd} cannot be found.".red
        return [false, nil, nil]
      end
      return [false, nil, nil]

    end

    # remove
    def remove input

      str = checkConfigFile(readYML("#{Dir.home}/.aka/.config")["dotfile"])

      if content=File.open(str).read
        content.gsub!(/\r\n?/, "\n")
        content_array= content.split("\n")
        content_array.each_with_index { |line, index|
          value = line.split(" ")
          if value.length > 1 and value.first == "alias"
            answer = value[1].split("=")
            if answer.first == input
              content_array.delete_at(index) and write_with_newline(content_array)
              print_out_command = "aka g #{input}=#{line.split("=")[1]}"
              puts "removed: #{print_out_command} is removed from #{str}".red
              return true
            end
          end
        }

        puts "#{input} cannot be found.".red
      else
        puts "#{@pwd} cannot be found.".red
        return false
      end
    end

    # history
    def history

      str = checkConfigFile(readYML("#{Dir.home}/.aka/.config")["history"])

      if content = File.open(str).read
        puts ".bash_history is available"
        count=0
        content.gsub!(/\r\n?/, "\n")
        content_array = content.split("\n")
        content_array.each_with_index { |line, index|
          array = line.split(" ")
          if array.first == "alias"
            count += 1
          end
          puts "#{index+1} #{line}"
        }
        puts "There are #{count} lines of history."
      else
        puts ".bash_history is not available".red
      end
    end

    # check version
    def version
      puts ""
      puts "aka #{program(:version)} - #{program(:last_update)}"
      puts "#{program(:author)} - #{program(:contact)}"
      puts "https://github.com/ytbryan/aka"
    end

    # check found
    def found? answer, argument, line
      if answer == argument
        # puts line.red + " - aka add #{argument}"
        # puts line.red
        puts "found: aka g #{argument}=#{line.split('=')[1]}".red
        return true
      else
        return false
      end
    end

    # edit_this
    def edit_this newcommand, this_alias
      puts "new: aka g #{this_alias}='#{newcommand}'"
      return append("alias " + this_alias + "='" + newcommand + "'", readYML("#{Dir.home}/.aka/.config")["dotfile"] )
    end

    # edit alias
    def edit_alias newalias, thiscommand
      puts "new: aka g #{this_alias}='#{newcommand}'"
      return append("alias " + newalias + "='" + thiscommand + "'", readYML("#{Dir.home}/.aka/.config")["dotfile"] )
    end

    # count function
    def count_function
      function_count = 0
      str = checkConfigFile(readYML("#{Dir.home}/.aka/.config")["dotfile"])
      if content=File.open(str).read
        content.gsub!(/\r\n?/, "\n")
        content_array= content.split("\n")
        content_array.each_with_index { |line, index|
          value = line.split(" ")
          if value.length > 1 and value.first == "function"
            answer = value[1].split("=")
            function_count += 1
          end
        }
        return function_count
      end
    end

    #count export
    def count_export
      export_count = 0
      str = checkConfigFile(readYML("#{Dir.home}/.aka/.config")["dotfile"])
      if content=File.open(str).read
        content.gsub!(/\r\n?/, "\n")
        content_array= content.split("\n")
        content_array.each_with_index { |line, index|
          value = line.split(" ")
          if value.length > 1 and value.first == "export"
            answer = value[1].split("=")
            export_count += 1
          end
        }
        return export_count
      end

    end

    # count
    def count
      alias_count = 0

      str = checkConfigFile(readYML("#{Dir.home}/.aka/.config")["dotfile"])

      if content=File.open(str).read
        content.gsub!(/\r\n?/, "\n")
        content_array= content.split("\n")
        content_array.each_with_index { |line, index|
          value = line.split(" ")
          if value.length > 1 and value.first == "alias"
            answer = value[1].split("=")
            alias_count += 1
          end
        }
        return alias_count
      end
    end

    # setup_aka
    def setup_aka
        append_with_newline("export HISTSIZE=10000","/etc/profile")
        trap = "sigusr2() { unalias $1;}
  sigusr1() { source #{readYML("#{Dir.home}/.aka/.config")["dotfile"]}; history -a; echo 'reloaded dot file'; }
  trap sigusr1 SIGUSR1
  trap 'sigusr2 $(cat ~/sigusr1-args)' SIGUSR2\n".pretty
        append(trap, readYML("#{Dir.home}/.aka/.config")['profile'])
      puts "Done. Please restart this shell.".red
    end

    # write to location
    def write_to_location location, address
      if aka_directory_exists?
        write(location, address)
      else
        puts ".aka not found.".red
      end
    end

    # read location
    def read location
      answer = dot_location_exists?(location)
      if answer == true and content = File.open(location).read
        return content
      end
      return ""
    end

    # dot location exist
    def dot_location_exists? address
      return File.exist? address
    end

    # aka directory exist ?
    def aka_directory_exists?
      return File.directory?("#{Dir.home}/.aka")
    end

    # check config file
    def checkConfigFile str
      path =  "#{Dir.home}/.bash_profile"
      if str == ""
        puts "Error: Type `aka init --dotfile #{path}` to set the path to your dotfile. \nReplace .bash_profile with .bashrc or .zshrc if you are not using bash.".red
        exit()
      end

      if !File.exists?(str)
        puts "Error: Type `aka init --dotfile #{path}` to set the path of your dotfile. \nReplace .bash_profile with .bashrc or .zshrc if you are not using bash.".red
        exit()
      end

      return str
    end

    # show last
    def showlast howmany=10
      str = checkConfigFile(readYML("#{Dir.home}/.aka/.config")["dotfile"])

      if content = File.open(str).read
        content.gsub!(/\r\n?/, "\n")
        content_array = content.split("\n")
        #why not just call the last five lines? Because i can't be sure that they are aliases
        total_aliases = []
        content_array.each_with_index { |line, index|
          value = line.split(" ")
          if value.length > 1 and value.first == "alias"
            total_aliases.push(line)
          end
        }
        puts ""
        if total_aliases.count > howmany
          total_aliases.last(howmany).each_with_index do |line, index|
            splitted= line.split('=')
            puts "#{total_aliases.count - howmany + index+1}. aka g " + splitted[0].split(" ")[1] + "=" + splitted[1].red
            # puts "#{total_aliases.count - howmany + index+1}. " + splitted[0] + "=" + splitted[1].red
          end
        else
          total_aliases.last(howmany).each_with_index do |line, index|
            splitted= line.split('=')
            # puts "#{index+1}. " + splitted[0] + "=" + splitted[1].red
            puts "#{index+1}. aka g " + splitted[0].split(" ")[1] + "=" + splitted[1].red
          end
        end
        puts ""
      end
    end

    # show usage
    def showUsage howmany=10, least=false

      str = checkConfigFile(readYML("#{Dir.home}/.aka/.config")["history"])

      value = reload_dot_file()
      #get all aliases
      if content = File.open(str).read
        content.gsub!(/\r\n?/, "\n")
        content_array = content.split("\n")
        total_aliases = []
        content_array.each_with_index { |line, index|
          value = line.split(" ")
          total_aliases.push(value.first)
        }
        count_aliases(total_aliases, howmany, least)
      end
    end

    # count aliases
    def count_aliases array, howmany, least=false
      name_array,count_array = [], []
      #find the unique value
      array.each_with_index { |value, index|
        if name_array.include?(value) == false
          name_array.push(value)
        end
      }
      #count the value
      name_array.each { |unique_value|
        count = 0
        array.each { |value|
          if (unique_value == value)
            count+=1
          end
        }
        count_array.push(count)
      }

      sorted_count_array, sorted_name_array = sort(count_array, name_array)

      #display the least used aliases
      if least == true
        if sorted_count_array.count == sorted_name_array.count
          puts ""
          sorted_name_array.last(howmany).each_with_index { |value, index|
            percent = ((sorted_count_array[sorted_name_array.last(howmany).size + index]).round(2)/array.size.round(2))*100
            str = "#{sorted_name_array.size-sorted_name_array.last(howmany).size+index+1}. #{value}"
            puts "#{str} #{showSpace(str)} #{showBar(percent)}"
          }
          puts ""
        else
          puts "Something went wrong: count_array.count = #{sorted_count_array.count}\n
          name_array.count = #{sorted_name_array.count}. Please check your .bash_history.".pretty
        end
      else
        # #print out
        if sorted_count_array.count == sorted_name_array.count
          puts ""
          sorted_name_array.first(howmany).each_with_index { |value, index|
            percent = ((sorted_count_array[index]).round(2)/array.size.round(2))*100
            str = "#{index+1}. #{value}"
            puts "#{str} #{showSpace(str)} #{showBar(percent)}"
          }
          puts ""
        else
          puts "Something went wrong: count_array.count = #{sorted_count_array.count}\n
                name_array.count = #{sorted_name_array.count}. Please check your .bash_history.".pretty
        end
      end
      puts "There's a total of #{array.size} lines in #{readYML("#{Dir.home}/.aka/.config")["history"]}."
    end

    # sort
    def sort(countarray, namearray) #highest first. decscending.
      temp = 0, temp2 = ""
      countarray.each_with_index { |count, index|
        countarray[0..countarray.size-index].each_with_index { |x, thisindex|  #always one less than total

          if index < countarray.size-1 and thisindex < countarray.size-1
            if countarray[thisindex] < countarray[thisindex+1] #if this count is less than next count
              temp = countarray[thisindex]
              countarray[thisindex] = countarray[thisindex+1]
              countarray[thisindex+1] = temp

              temp2 = namearray[thisindex]
              namearray[thisindex] = namearray[thisindex+1]
              namearray[thisindex+1] = temp2
            end
          end

        }
      }#outer loop
      return countarray, namearray
    end

    # get history file
    def get_latest_history_file
      system("history -a")
    end

    # clean up
    def cleanup

      str = checkConfigFile(readYML("#{Dir.home}/.aka/.config")["dotfile"])

      if content = File.open(str).read
        content.gsub!(/\r\n?/, "\n")
        content_array = content.split("\n")
        check = false
        while check == false
          check = true
          content_array.each_with_index { |line, index|
            if line == "" or line == "\n"
              content_array.delete_at(index)
              check = false
            end
          }
        end
        write_with_newline(content_array)
      end
    end

    ################################################
    ## Getting these babies ready for beauty contest
    ################################################

    def showSpace word
      space = ""
      val = 20 - word.size
      val = 20 if val < 0
      val.times do
        space += " "
      end
      return space
    end

    def showBar percent
      result = ""
      val = percent/100 * 50
      val = 2 if val > 1 and val < 2
      val = 1 if val.round <= 1 #for visibiity, show two bars if it's just one
      val.round.times do
        result += "+"
      end

      remaining = 50 - val.round
      remaining.times do
        result += "-".red
      end

      return result + " #{percent.round(2)}%"
    end

    def add_to_proj fullalias
      values = fullalias.split("=")
      yml = readYML("#{Dir.pwd}/.aka")
      if yml == false
        write_new_proj_aka_file fullalias
      else
        yml["proj"]["title"] = "this is title"
        yml["proj"]["summary"] = "this is summary"
        yml["proj"]["aka"][values.first] = values[1]
        writeYML("#{Dir.pwd}/.aka", yml)
      end
    end

    def write_new_proj_aka_file fullalias
      values = fullalias.split("=")

      theyml = {"proj" => {
                  "title" => "",
                   "summary" => "",
                   "aliases" => {
                        "firstvalue" => ""
                              }}}

      writeYML("#{Dir.pwd}/.aka", theyml)
    end

    def createShortcut(proj)
      answer = ""
      proj["shortcuts"].to_a.each_with_index do |each,index|
          answer += "#{each["name"]}
                      - #{each["command"]}
                      ".pretty
          answer += "\n"
      end
      return answer
    end

    def add_last_command name
      command= find_last_command()
      return str = name + "=" + "#{command}"
    end

    def find_last_command
      str = checkConfigFile(readYML("#{Dir.home}/.aka/.config")["history"])
      #i think if you do history -w, you can retrieve the latest command
      if content = File.open(str).read
        count=0
        content.gsub!(/\r\n?/, "\n")
        content_array = content.split("\n")
        return  content_array[content_array.count - 1]
      end
    end

    def parseARGS str
      array =  str.split(" ")
      array.each_with_index do |line, value|
        array[value] = line.gsub('#{pwd}', Shellwords.escape(Dir.pwd))
      end
      return array.join(" ")
    end

    def add_pwd_to_the_command
      #detect #{pwd}
      #get the pwd and replace the the pwd
    end

    def showConfig
      thing = YAML.load_file("#{Dir.home}/.aka/.config")
      puts ""
      thing.each do |company,details|
        puts "#{company} -> " + "#{details}".red
      end
    end

    def setZSHRC
      setPath("#{Dir.home}/.zshrc","dotfile")
      setPath("#{Dir.home}/.zsh_history","history")
      setPath("/etc/zprofile","profile")
    end

    def setBASHRC
      setPath("#{Dir.home}/.bashrc","dotfile")
      setPath("#{Dir.home}/.bash_history","history")
      setPath("/etc/profile","profile")
    end

    def setBASH
      setPath("#{Dir.home}/.bash_profile","dotfile")
      setPath("#{Dir.home}/.bash_history","history")
      setPath("/etc/profile","profile")
    end

    def get_password
      ask("Enter Password: ", :echo => false)
    end

    def isOhMyZsh
      if readYML("#{Dir.home}/.aka/.config")["dotfile"] == "#{Dir.home}/.zshrc"
        return true
      else
        return false
      end
    end

  end
end
