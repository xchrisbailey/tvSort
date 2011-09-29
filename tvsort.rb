#!/usr/bin/ruby
require 'tvdb_party'
require 'yaml'

def colorize (text, colorCode)
  "#{colorCode}#{text}\e[0m"
end


tvdb = TvdbParty::Search.new("6C29C1F6969822E9", "en")
myCorrections = YAML::load(File.open('/home/chris/.config/tvsort/fixes.yaml'))

oDest = '/mnt/media01/sort/'
nDest = '/mnt/media01/TV/'
unClean = Dir.glob(oDest + '{*.{mkv,avi,wmv,m4v},**}/*.{mkv,avi,wmv,m4v}')

sortReport = Array.new

unTV = Array.new
unClean.each do |f|
  unTV.push(f) if f =~ /[sS]\d+[eE]\d+/
  unTV.push(f) if f =~ /\d+x\d+/
  unTV.push(f) if f =~ /\d+\d{2}/
  unTV
end

unTV.each do |f|
  copyFileFrom = f

  f = f.gsub(/\d+\d{2}/, "S#{$1}E#{$2}") if f =~ /(\d+)(\d{2})/
  f = f.gsub(/\d+x\d+/, "S#{$1}E#{$2}") if f=~/(\d+)x(\d+)/
  
  f =~ /.*\/(.*?)[\.\s][sS](\d+)[eE](\d+).*?(\.[mMaAwW][kKvVmM][vViI])/
  series, season, episode, exten  = $1.downcase, $2.to_i, $3.to_i, $4
  series = series.gsub(/[\._]/, ' ')

  # Check for file names that need to be adjusted for thetvdb to recognize.
  myCorrections.each { |k, v| series = v if series == k }

  # Grab episode title and series naming from tvdb
  results     = tvdb.search("#{series}")
  results     = results[0]
  serID       = tvdb.get_series_by_id(results['seriesid'])
  series      = serID.name 
  tempEpisode = serID.get_episode(season, episode) || next
  epiTitle    = tempEpisode.name

  # Clean up characters for boxee
  series   = series.gsub(/[\/:;,'!?.]/, '')
  series   = series.gsub(/&/, 'and')
  epiTitle = epiTitle.gsub(/[\/:;,'!?.]/, '')
  epiTitle = epiTitle.gsub(/&/, 'and')

  # Give two digit season & episode numbers
  season  = season.to_s.rjust(2, '0')
  episode = episode.to_s.rjust(2, '0')

  newFile = "#{series}.S#{season}E#{episode}.#{epiTitle}#{exten}"
  folderName = "#{series}/Season#{season}/"

  # Check for and make directories if needed.
  fileDestination = "#{nDest}#{folderName}"
  FileUtils.mkdir_p("#{nDest}#{series}/Season#{season}") if Dir.exist?("#{nDest}#{series}/Season#{season}") == false

  # Move and organize the show
  moveFrom = "#{copyFileFrom}"
  moveTo   = "#{nDest}#{folderName}#{newFile}"
  next if File.exist?(moveTo) == true
  FileUtils.mv(moveFrom, moveTo)
  sortReport << newFile
end


if sortReport.length > 0
  puts "\e[1;31mShows ready for viewing:\e[0m"
  sortReport.each do |f| 
    rColor = 31+Random.rand(6)
    rColor = "\e[" + rColor.to_s + "m"
    puts colorize("#{f}", rColor)
  end
else
  puts "\e[1;40;35mNo new shows. =(\e[0m"
end
