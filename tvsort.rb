#!/usr/bin/ruby
require 'smart_colored/extend'
require 'tvdb_party'
require 'yaml'

def colorize (text, colorCode)
  "#{colorCode}#{text}\e[0m"
end


Tvdb = TvdbParty::Search.new("6C29C1F6969822E9", "en")
MyCorrections = YAML::load(File.open('/home/chris/.config/tvsort/fixes.yaml'))

OrigDest = '/mnt/media01/sort/'
NewDest = '/mnt/media01/TV/'
#unClean = Dir.glob('/mnt/media01/sort/{*.{mkv,avi,wmv,m4v},**}/*.{mkv,avi,wmv,m4v}')
UnClean = Dir.glob(OrigDest + '{*.{mkv,avi,wmv,m4v},**}/*.{mkv,avi,wmv,m4v}')

sort_report = Array.new

unclean_tv = Array.new
UnClean.each do |f|
  unclean_tv.push(f) if f =~ /[sS]\d+[eE]\d+/
  unclean_tv.push(f) if f =~ /\d+x\d+/
#  unclean_tv.push(f) if f =~ /\d+\d{2}/
  unclean_tv
end

unclean_tv.each do |f|
  copy_file_from = f

#  f = f.gsub(/\d+\d{2}/, "S#{$1}E#{$2}") if f =~ /(\d+)(\d{2})/
  f = f.gsub(/\d+x\d+/, "S#{$1}E#{$2}") if f=~/(\d+)x(\d+)/
  
  f =~ /.*\/(.*?)[\.\s][sS](\d+)[eE](\d+).*?(\.[mMaAwW][kKvVmM][vViI])/
  series, season, episode, exten  = $1.downcase, $2.to_i, $3.to_i, $4
  series = series.gsub(/[\._]/, ' ')

  # Check for file names that need to be adjusted for thetvdb to recognize.
  MyCorrections.each { |k, v| series = v if series == k }

  # Grab episode title and series naming from tvdb
  results       = Tvdb.search("#{series}")
  results       = results[0]
  series_id     = Tvdb.get_series_by_id(results['seriesid'])
  series        = series_id.name 
  temp_episode  = series_id.get_episode(season, episode) || next
  episode_title = temp_episode.name

  # Clean up characters for boxee
  series   = series.gsub(/[\/:;,'!?.]/, '')
  series   = series.gsub(/&/, 'and')
  episode_title = episode_title.gsub(/[\/:;,'!?.]/, '')
  episode_title = episode_title.gsub(/&/, 'and')

  # Give two digit season & episode numbers
  season  = season.to_s.rjust(2, '0')
  episode = episode.to_s.rjust(2, '0')

  new_file = "#{series}.S#{season}E#{episode}.#{episode_title}#{exten}"
  folder_name = "#{series}/Season#{season}/"

  # Check for and make directories if needed.
  fileDestination = "#{NewDest}#{folder_name}"
  FileUtils.mkdir_p("#{NewDest}#{series}/Season#{season}") if Dir.exist?("#{NewDest}#{series}/Season#{season}") == false

  # Move and organize the show
  move_from = "#{copy_file_from}"
  move_to   = "#{NewDest}#{folder_name}#{new_file}"
  next if File.exist?(move_to) == true
  FileUtils.mv(move_from, move_to)
  sort_report << new_file
end


if sort_report.length > 0
  puts "\e[1;31mShows ready for viewing:\e[0m"
  sort_report.each do |f| 
    rand_color = 31+Random.rand(6)
    rand_color = "\e[" + rand_color.to_s + "m"
    puts colorize("#{f}", rand_color)
  end
else
  puts "\e[1;40;35mNo new shows. =(\e[0m"
end
