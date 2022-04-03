
require 'terminal-table'
require 'slop'
# require_relative File.join Rails.root, "config/environment"


namespace :db do
namespace :br do

  DEFAULT_BACKUP_DIRECTORY = "#{Rails.root}/db/backups"
  DEFAULT_BACKUP_FORMAT = "sql"
  BACKUP_FORMATS = { 
    "custom"    => 'c',
    "sql"       => 'p',
    "psql"      => 'p',
    "plain"     => 'p',
    "text"      => 'p',
    "directory" => 'd',
    "tar"       => 't',
  }

  def backup_directory(backup_dir = DEFAULT_BACKUP_DIRECTORY, create_if_not_found=false)
    unless Dir.exists?(backup_dir)
      if create_if_not_found
        FileUtils.mkdir_p(backup_dir)
      else
        backup_dir = nil
      end
    end
    backup_dir
  end


  desc "list all or some backups from a location (default: #{DEFAULT_BACKUP_DIRECTORY}"
  task :list_backups,[:pattern,:location,] => :environment do |t, args|
    dir = backup_directory(args.location||DEFAULT_BACKUP_DIRECTORY)
    unless dir
      puts "backup location (#{args.location}) not found"
      exit(1)
    end

    pat = args.pattern  || "*"

    files = Dir.glob(File.join(dir, pat)).sort_by{|x| File.mtime(x)}.reverse!.map.with_index{|x,i| [i+1, File.basename(x), File.stat(x).size, File.stat(x).mtime.strftime("%F %H:%M %b %a")]}

    puts "Backup location: #{dir}"
    puts Terminal::Table.new( 
      rows: files,
      headings: ["\#","Filename","size","Date/time created"],
    )
  end


  desc 'backup the database (may specify backup (b)format and/or location)'
  task :xxxbackup, [:bformat, :location] => :environment do |t, args|
    bformat = args.bformat || DEFAULT_BACKUP_FORMAT
    fformat = backup_format_of(bformat)
    unless fformat
      puts "invalid backup format: #{args.bformat}"
      exit(1)
    end
    
    dir = backup_directory( args.location || DEFAULT_BACKUP_DIRECTORY)
    unless dir
      raise "backup location not found" 
      exit(1)
    end

    using_config do |app, host, db, user|
      file_name = "#{Time.now.strftime("%Y%m%d%H%M%S")}_#{db}.#{bformat}"
      cmd = "pg_dump -F #{fformat} -Z 6  -U #{user} -v --no-owner -h #{host} -d #{db} -f #{File.join(dir,file_name)}"

      puts "backing up database #{db}"
      puts cmd
      exec cmd
    end
  end

  desc 'backup the database (may specify backup (b)format and/or location)'
  #sample run: bin/rake db:br:backup -- --name "pre_period_closing"
  task :backup => :environment do

    i = ARGV.index("--")
    if i 
      ARGV=ARGV[(i+1)..-1]
    end

    opts = Slop.parse do |o|
      o.string '-f',  '--format',     'backup format extension',  default: DEFAULT_BACKUP_FORMAT
      o.string '-d',  '--directory',  'backup target directory',  default: DEFAULT_BACKUP_DIRECTORY
      o.string '-n',  '--name',       'backup target filename'
      o.bool   '-v',  '--verbose',    'enable verbose mode'
      o.bool   '-q',  '--quiet',      'suppress output (quiet mode)'

      o.on '--version', 'print the version' do
        puts Slop::VERSION
        exit 0
      end
      
      o.on '--help' do
        puts o
        exit 0
      end
    end

# binding.pry
    bformat = opts[:format]
    fformat = backup_format_of(bformat)
    unless fformat
      puts "invalid backup format: #{args.bformat}"
      exit 1
    end

    name = opts[:name]
    if name 
      name=name.parameterize(separator: "_")
    end

    dir = backup_directory(opts[:directory])
    unless dir
      raise "backup location not found" 
      exit 2
    end

    using_config do |app, host, db, user|
      file_name = [Time.now.strftime("%Y%m%d%H%M%S"), db, name, bformat].compact.join "."
      cmd = "pg_dump -F #{fformat} -Z 6  -U #{user} -v --no-owner -h #{host} -d #{db} -f #{File.join(dir,file_name)}"

      puts "backing up database #{db}..."
      puts cmd
      exec cmd
      puts "backup of database #{db} done."
    end

    exit 0
  end

  desc 'backup one or more tables or models (may specify backup (b)format and/or location)'
  task :backup_tables => :environment do

    i = ARGV.index("--")
    if i
      ARGV=ARGV[(i+1)..-1]
    end

    opts = Slop.parse do |o|
      o.string '-f',  '--format',     'backup format extension',  default: DEFAULT_BACKUP_FORMAT
      o.string '-d',  '--directory',  'backup target directory',  default: DEFAULT_BACKUP_DIRECTORY
      o.string '-n',  '--name',       'backup target filename'

      o.array '--tables', 'list of tables to backup', delimiter: ','

      o.bool   '-v',  '--verbose',    'enable verbose mode'
      o.bool   '-q',  '--quiet',      'suppress output (quiet mode)'
      o.bool   '--testing',    'testing only. do not run command'

      o.on '--version', 'print the version' do
        puts Slop::VERSION
        exit 0
      end

      o.on '--help' do
        puts o
        puts "Eg,"
        puts "bin/rails  db:br:backup_tables -- --tables mytable1 --tables mytable2"
        puts
        exit 0
      end
    end

# binding.pry
    bformat = opts[:format]
    fformat = backup_format_of(bformat)
    unless fformat
      puts "invalid backup format: #{args.bformat}"
      exit 1
    end

    name = opts[:name]
    if name
      name=name.parameterize(separator: "_")
    end

    dir = backup_directory(opts[:directory])
    unless dir
      raise "backup location not found"
      exit 2
    end

    tables = opts[:tables]
    if tables.empty?
      raise "tables not found"
      exit 3
    end
    dbtables = tables.map do |table|
      "-t #{table}"
    end.join(" ")

    using_config do |app, host, db, user|
      file_name = [Time.now.strftime("%Y%m%d%H%M%S"), db, name, "tables", tables.join("_&_"),  bformat].compact.join "."
      cmd = "pg_dump -F #{fformat} -Z 6  -U #{user} -v --no-owner -h #{host} -d #{db} #{dbtables} -f '#{File.join(dir,file_name)}'"

      puts "backing up database #{db}..."
      puts "  tables: #{tables}..."
      puts cmd
      unless opts[:testing]
        exec cmd
      end
      puts "backup of database #{db}."
      puts "  tables: #{tables} done..."
      puts
    end

    exit 0
  end


  desc 'restore database based on file pattern and/or latest backup'
  task :restore => :environment do |t,args|
    i = ARGV.index("--")
    if i
      ARGV=ARGV[(i+1)..-1]
    end

    opts = Slop.parse do |o|
      o.string '-d',  '--directory',  'backup target directory',  default: DEFAULT_BACKUP_DIRECTORY
      o.string '-n',  '--filename',       'backup target filename to restore'

      o.bool   '-v',  '--verbose',    'enable verbose mode'
      o.bool   '-q',  '--quiet',      'suppress output (quiet mode)'
      o.bool   '--testing',    'testing only. do not run command'

      o.on '--version', 'print the version' do
        puts Slop::VERSION
        exit 0
      end

      o.on '--help' do
        puts o
        puts
        puts "Eg, to get this help"
        puts "bin/rails  db:br:restore -- --help"
        puts "(note the double dash prefix)"
        puts
        puts "To restore the latest file in backup (default)"
        puts "bin/rails  db:br:restore"
        puts
        puts "or specify the actual file"
        puts "bin/rails  db:br:restore -- --filename my_backup_file.sql"
        puts
        exit 0
      end
    end

    unless dir = backup_directory(opts[:directory])
      puts "backup directory (#{dir}) not found"
      exit(1)
    end

    pattern = opts[:filename] || "*"
    fglob = File.join(dir, pattern)
    files = Dir.glob(fglob).sort_by{|x| File.mtime(x)}.reverse!
    file = files.first
    unless file
      puts "backup path #{fglob} is empty. no backup file to restore."
      exit(1)
    end

    puts "-----------------------------"
    puts "Note: this restore will do a backup; just in case..."
    puts
    backupcmd = %q( bin/rake db:br:backup -- --name "pre restore backup" )
    puts "backup current db before restore..."
    puts "will run: #{backupcmd}..."
    puts "before"
    puts "restoring backup file from #{file}."
    puts "Press enter to continue.. or Ctrl-C to cancel.."
    STDIN.gets

    if opts[:testing]
      puts "Testing mode. Canceling restore."
      puts
    else
      system backupcmd
      restore file
    end

  end


  desc 'xrestore database based on file pattern and/or latest backup'
  # sample runs:
  # bin/rails db:br:restore
  # bin/rails "db:br:restore[sample patterrn]""
  # bin/rails "db:br:restore[samplebackupfile.sql]""

  task :xrestore, [:pattern,:location] => :environment do |t,args|
    dir = backup_directory( args.location || DEFAULT_BACKUP_DIRECTORY)
    unless dir
      puts "backup directory (#{args.location}) not found"
      exit(1)
    end

    pattern = args.pattern || "*"

    fglob = File.join(dir, pattern)
    files = Dir.glob(fglob).sort_by{|x| File.mtime(x)}.reverse!
    file = files.first
    unless file
      puts "backup path #{fglob} is empty. no backup file to restore."
      exit(1)
    end

    puts "-----------------------------"
    puts "Note: this restore will do a backup; just in case..."
    puts 
    backupcmd = %q( bin/rake db:br:backup -- --name "pre restore backup" )
    puts "backup current db before restore..."
    puts "will run: #{backupcmd}..."
    puts "before"
    puts "restoring backup file from #{file}."
    puts "Press enter to continue.. or Ctrl-C to cancel.."
    STDIN.gets
    system backupcmd
    restore file

  end

  desc 'delete backup based on file pattern and/or latest backup'
  # sample run: bin/rails db:br:restore
  task :delete, [:pattern,:location] => :environment do |t,args|
    dir = backup_directory( args.location || DEFAULT_BACKUP_DIRECTORY)
    unless dir
      puts "backup directory (#{args.location}) not found"
      exit(1)
    end

    pattern = args.pattern || "*"

    fglob = File.join(dir, pattern)
    files = Dir.glob(fglob).sort_by{|x| File.mtime(x)}.reverse!
    file = files.first
    unless file
      puts "backup path #{fglob} is empty. no backup file to delete."
      exit(1)
    end

    delete file

  end


  desc 'stop running rails processes'
  # sample run: bin/rails db:br:restore
  task :stop_rails_processes, [:pattern,:location] => :environment do |t,args|
    case Rails.env
    when "production"
      system %Q( sudo service payroll stop ) # not working; no tty present
      system %Q( sudo service payroll stop ) # not working; no tty present
    when "development"
      my_pid = Process.pid.to_s
      pids =  %x( pgrep ruby ).split
      pids.delete my_pid

      pids . each do |pid|
        system %Q( kill -9 #{pid})
        system %Q( kill -9 #{pid})
      end
      # %x(killall -9 ruby)
      # %x(killall -9 ruby)
    else
      pid=%x( lsof -wni tcp:3000 | tail -1 ).split[1]
      system %Q( kill -9 #{pid})
      system %Q( kill -9 #{pid})
    end
  end




  private

  def delete file
    using_config do |app, host, db, user|
      cmd = "rm #{file}"

      puts "Deleting backup file #{file}"
      puts
      puts "press Enter to continue or Ctrl-C to break/abort restore"
      STDIN.gets
        
      puts cmd
      exec cmd
    end
  end


  def restore file
    using_config do |app, host, db, user|
      cmd = if is_sql_file(file)
          "cat #{file} | gunzip | sudo -u postgres psql -U #{user} -d #{db}"
        else
          "pg_restore -v -h #{host} -d #{db} -U #{user}  #{file}"
        end

#binding.pry

      puts "Restoring database #{db} using/from file #{file}"
      puts
      puts "this restore will do the ff:"
      puts
      puts "1 drop/destroy the database"
      puts "2 create an empty database"
      puts "3 do the actual restore"
      puts
      puts "press Enter to continue or Ctrl-C to break/abort restore"
      STDIN.gets
        
      puts 'Rake::Task["db:stop_rails_processes"].invoke'
      Rake::Task["db:br:stop_rails_processes"].invoke

      puts 'Rake::Task["db:drop"].invoke'
      Rake::Task["db:drop"].invoke
      
      puts 'Rake::Task["db:create"].invoke'
      Rake::Task["db:create"].invoke

      puts cmd
      exec cmd
    end
  end


  def is_sql_file filename
    /(\.sql|\.psql|\.text|\.plain)$/ =~ filename 
  end


  def backup_format_of file
    BACKUP_FORMATS[file]
  end


  def using_config
    yield Rails.application.class.module_parent_name.underscore,
          ActiveRecord::Base.connection_config[:host] || "localhost",
          ActiveRecord::Base.connection_config[:database],
          ActiveRecord::Base.connection_config[:username]

  end

  # command name typo intended : )
  LOG_FILE="/tmp/pgdump.err"
  BACKUP_OP_EMAIL = "asmpc-backup-op@asmpc.com"
  BACKUP_FAILURE_MESSAGE = "Backup failure!"
  def commandeer pg_cmd
    cmd = 
    %Q(
    if ! #{pg_cmd} 2> #{LOG_FILE }
    then 
      cat #{LOG_FILE} | mailx #{BACKUP_OP_EMAIL} -s #{BACKUP_FAILURE_MESSAGE}
    fi
    )

    exec cmd  
  end

end
end


