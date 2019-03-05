#!/usr/bin/perl
#

use strict;
use Getopt::Long;
use Term::ANSIColor;

my $debug = 0;
my $force = 0;
my $noconf = 0;
my $looper = 0;
my $remove = 0;
my $ignore = '';
my $tmpdir = '/tmp/optdeps';

GetOptions(
	'force' => \$force, 
	'loop' => \$looper, 
	'temp=s' => \$tmpdir, 
	'v+' => \$debug, 
	'ignore=s' => \$ignore,
	'noconfirm' => \$noconf,
	'remove' => \$remove
);
	
my $dopts = '&> /dev/null';
if ($debug > 0) { $dopts = ''; }
if ($ignore ne '') { 
	if ($ignore =~ /,/) { 
		my @aignore = split(/,/, $ignore);
		for (my $i=0;$i<@aignore;$i++) { $aignore[$i] = '--ignore ' . $aignore[$i]; }
		$ignore = join(' ', @aignore);
	}
	else { $ignore = '--ignore ' . $ignore; }		
}
if ($noconf) { $ignore = $ignore . ' --noconfirm'; }
my @packlist = @ARGV;

my $wrkdir = `pwd`;
$wrkdir =~ s/\n//;
if (!-d $tmpdir) { system("mkdir $tmpdir"); }
while (@packlist) {
  chdir($wrkdir);
  my $packfile = shift(@packlist);
  dprint(colored("++ Testing $packfile...", 'green'));
  if (!-r $packfile) { die "Error: Cannot read $packfile!\n"; }
  system("cp $packfile $tmpdir $dopts");
  my $tmppack = $tmpdir . '/';
  if ($packfile =~ /\//g) { 
	my @tpath = split(/\//g, $packfile);
	my $fname = $tpath[@tpath-1];
	$tmppack = $tmppack . $fname; 
  }
  else { $tmppack = $tmppack . $packfile; }
  if (!-r $tmppack) { die "Error: Failed to copy $packfile to $tmpdir!\n"; }
  chdir($tmpdir);
  system("tar -xf $tmppack $dopts");
  my $packinfo = $tmpdir . '/.PKGINFO';
  if (!-r $packinfo) { die "Error: Failed to extract $packfile to $tmpdir!\n"; }
  open(PKGFILE, "<", $packinfo) || die "Cannot read from $packinfo!\n";
  my @pdata = <PKGFILE>;
  close(PKGFILE);
  system("rm -rf ./*");
  my @optdeps;
  foreach my $line (@pdata) {
	if ($line =~ /optdepend = /) { 
	  my @oparms = split(/ = /, $line);
	  $oparms[1] =~ s/\n$//;
	  my @namedesc = split(/:/, $oparms[1]);
	  push(@optdeps, $namedesc[0]);
	}
  }
  if (@optdeps < 1) { dprint("Warning: No optdeps found in $packfile!", 1); }
  else { 
	foreach my $opt (@optdeps) { 
	    if (askUser($opt)) {
	        system("pacman -Sq --needed $ignore $opt"); 
	        if ($looper) { 
		  dprint("push($opt) onto the list",1);
		  my $optwild = $opt . '*';
		  push(@packlist, $optwild);
                }
            }
        }
  }
  system("rm $tmpdir/* $dopts");
  system("rm $tmpdir/.* $dopts");
  system("rm -rf $tmpdir/* $dopts");
  if ($remove) { system("rm $wrkdir/$packfile $dopts"); }
}
exit(0);

sub askUser {
	if ($force) { return 1; }
	my $pck = shift;
	print "Found optdep: $pck\nWould you like to install it? [y/N]: "; 
	my $resp = <STDIN>;
	$resp =~ s/\n$//;
	if (lc($resp) eq 'y') { return 1; }
	return 0;
}	

sub dprint {
	my $pdata = shift;
	my $loglevel = shift;
	if ($loglevel eq '') { $loglevel = 0; }
	if ($debug < $loglevel) { return; } 	
	print "$pdata\n";
}
