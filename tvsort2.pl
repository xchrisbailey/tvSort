#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use TVDB::API;
use File::Glob ':glob';
use File::Copy;
use File::Path qw(make_path);
use YAML::XS qw(LoadFile);
use Term::ExtendedColor qw(:all);

my @sort = <~chris/media/sort/tv/*.{mkv,avi}>;
my $orig = '/home/chris/media/sort/tv/';
my $fixy = '/home/chris/.config/tvsort/fixes.yaml';
my $dest = '/mnt/media01/TV/';
my $tvdb = TVDB::API::new( '6C29C1F6969822E9', 'en' );

my $fixes = LoadFile $fixy;

foreach my $sort (@sort) {
  my $old = $sort;
  if (
    $sort =~ s/.*\/(.*?)[\.\s][sS](\d+).*?[eE](\d+).*?(\.[maw][kvm][viv])// )
  {
    my $title   = lc $1;
    my $season  = $2;
    my $episode = $3;
    my $ext     = $4;
    $title =~ s/[\._]/ /g;
    $title =~ s/[,'\!"`:]//g;

    foreach my $key ( keys %$fixes ) {

      if ( $title eq $key ) {
        $title = $fixes->{$title};
        last;
      }
    }

    my $sID = $tvdb->getSeriesId($title);
    if ( defined $sID ) { }
    else {
      print fg( 'bold', fg( 'red1', "series " ) ),
        "' $title ' not found.. ;(\n";
      next;
    }
    my $sName = $tvdb->getSeriesName($sID);
    my $eName = $tvdb->getEpisodeName( $sName, $season, $episode );

    if ( defined $sName && defined $eName ) {
      $sName =~ tr/[\/:;,'!?.]//d;
      $eName =~ tr/[\/:;,'!?.]//d;
      $sName =~ s/&/and/g;
      $eName =~ s/&/and/g;

      my $sDest = "$dest$sName\/Season$season\/";
      my $sEpi  = "E$episode";
      my $sSea  = "S$season";
      my $sFile = "$sName.$sSea$sEpi.$eName";
      my $sComp = "$sDest$sFile";

      if ( -e "$sDest$sFile$ext" ) {
        print fg( 'italic', fg( 'orchid1', "$sFile$ext " ) ),
          fg( 'bold', fg( 'red2', "exist.\n" ) );
        next;
      }

      if ( -d "$sDest" ) {
        print fg( 'red1', italic('<- moving ') ),
          fg( 'orchid1', italic("$old\n") );
        print fg( 'red1', italic('to -> ') ),
          fg( 'orchid1', italic("$sDest$sFile$ext\n\n") );
        sleep 1;
        move( "$old", "$sDest$sFile$ext" );
      }
      else {
        print fg( 'red1', italic('<- moving ') ),
          fg( 'orchid1', italic("$old\n") );
        print fg( 'red1', italic('to -> ') ),
          fg( 'orchid1', italic("$sDest$sFile$ext\n\n") );
        sleep 1;
        make_path("$sDest");
        move( "$old", "$sDest$sFile$ext" );
      }
    }
  }
  else {
    print "$sort not a tv show..\n";
  }
}

# vim: set ts=2 et sw=2:

