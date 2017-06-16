#!/usr/bin/ruby
# encoding: UTF-8

require 'tvdb_party'
require 'psych'

Tvdb = TvdbParty::Search.new("6C29C1F6969822E9", "en")
MyCorrections = Psych.load(File.open('/home/chris/.config/tvsort/fixes.yaml'))

OrigDest = '/mnt/media01/sort/'
NewDest = '/mnt/media01/TV/'
UnClean = Dir.glob(OrigDest + '{*.{mkv,avi,wmv,mp4,ts},**}/*.{mkv,avi,wmv,mp4,ts}')
sort_report = []
unclean_tv = []

UnClean.each do |f|
  unclean_tv.push(f) and next if f =~ /[sS]\d+[eE]\d+/
  unclean_tv.push(f) and next if f =~ /\d+x\d+/
  unclean_tv.push(f) and next if f =~ /.*[1950-2020].*\.\d+\d{2}/
  unclean_tv.push(f) and next if f =~ /.*\.\d+\d{2}/
  unclean_tv
end

unclean_tv.each do |f|
  copy_file_from = f
  f = case f
      when /[sS]\d+[eE]\d+/
        f
      when /(.*[1950-2020].*\.)(\d+)(\d{2})/
        f.gsub(/.*[1950-2020].*\.\d+\d{2}/, "#{$1}S#{$2}E#{$3}")
      when /(\d+)(\d{2})/
        f.gsub(/\d+\d{2}/, "S#{$1}E#{$2}")
      when /(\d+)x(\d+)/
        f.gsub(/\d+x\d+/, "S#{$1}E#{$2}")
      end

  begin
    f =~ /.*\/(.*?)[\.\s][sS](\d+)[eE](\d+).*?(\.[mMaAwW][kKvVmMpP][vViI4]|\.ts)/
    series, season, episode, exten  = $1.downcase, $2.to_i, $3.to_i, $4
    series = series.gsub(/[\._]/, ' ')
  rescue
    next
  end

  # Check for file names that need to be adjusted for thetvdb to recognize.
  series = MyCorrections[series] if MyCorrections.key?(series) == true

  # Grab episode title and series naming from tvdb
  begin
    results       = Tvdb.search("#{series}")
    results       = results[0]
    series_id     = Tvdb.get_series_by_id(results['seriesid'])
    series        = series_id.name
    temp_episode  = series_id.get_episode(season, episode)
    episode_title = temp_episode.name
  rescue Exception => e
    next
  end

  # Clean up characters for boxee
  begin
    series   = series.gsub(/[\/:;,'!?.\*]/, '')
    series   = series.gsub(/&/, 'and')
    episode_title = episode_title.gsub(/[\/:;,'!?.\*]/, '')
    episode_title = episode_title.gsub(/&/, 'and')
  rescue Exception => e
    puts "Series information not found: #{e}"
    next
  end
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
  #next if File.exist?(move_to) == true
  FileUtils.mv(move_from, move_to, force: true)
  sort_report << new_file
end

if sort_report.length > 0
  puts "\e[1;31mShows ready for viewing:\e[0m"
  sort_report.each do |f|
    rand_color = 31+Random.rand(6)
    rand_color = "\e[" + rand_color.to_s + "m"
    puts "\e[34m  '-- #{rand_color}#{f}\e[0m"
  end
else
  puts "\e[1;40;35mNo new shows. =(\e[0m"
end
