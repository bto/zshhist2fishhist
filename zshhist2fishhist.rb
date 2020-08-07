#!/usr/bin/env ruby

require 'fileutils'
require 'pathname'

def get_fish_history_filename()
  fish_dir = File.join(ENV['HOME'], '.local/share/fish')
  FileUtils.mkdir_p(fish_dir)
  File.join(fish_dir, 'fish_history')
end

def get_zsh_history_filename()
  if ARGV[0]
    f = Pathname.new(ARGV[0])
    return f if f.file?
  end

  f = Pathname.new(ENV['ZDOTDIR']) + '.zsh_history'
  return f if f.file?

  f = Pathname.new(ENV['HOME']) + '.zsh_history'
  return f if f.file?

  f = Pathname.new(ENV['HISTFILE'])
  return f if f.file?
end

def decode_non_ascii(line)
  data = line.unpack('C*')
  i = -1
  a = []
  while c = data[i+=1] do
    if c == 0x83
      c = data[i+=1] ^ 0b00100000
    end
    a.push(c)
  end
  a.pack('C*')
end

def zsh_command_to_fish_command(command)
  command.gsub(/&&/, '; and ').gsub('/||/', '; or ')
end

zsh_history = get_zsh_history_filename()
unless zsh_history
  STDERR.puts 'Not found .zsh_history file'
  exit(1);
end

File.open(get_fish_history_filename(), 'a') {|outfile|
  File.open(zsh_history).each do |line|
    line = decode_non_ascii(line)
    next unless /^:\s+(\d+):\d+;(.*)/ =~ line.strip()
    command = zsh_command_to_fish_command($2)
    time = $1
    outfile.puts "- cmd: #{command}\n  when: #{time}"
    puts "Add: #{command}"
  end
}
