#!/usr/bin/perl

use strict;
use File::Spec;
use Getopt::Long;

my $toogg = 0;
my $normal = 0;
my $recurse = 0;
my $tempdir = "/tmp/tomp3-temp";

my @media_types = ('mpg', 'mp2', 'mpg4', 'mp4', 'm4a', 'mpeg', '3gp', 'flv', 'webm', 'ogg', 'ogv');

GetOptions(
	'ogg!' => \$toogg,
	'recurse!' => \$recurse,
	'normalize!' => \$normal
);

sub dieUsage {
	my $why = shift;
	my $use = "Usage: $0 [OPTIONS] <OUTPUT_FOLDER> <INPUT> [INPUT]...\n" .
			  "\tINPUT(S)\t\t- File/folder name or list of files/folders.\n" .
			  "\tOUTPUT_FOLDER\t\t- Folder name to place output into.\n" .
			  "\t--ogg\t\t\t- Convert to OGG instead of MP3.\n" .
			  "\t--recurse\t\t- Recursive directory search.\n" . 
			  "\t--normalize\t\t- Normalize tracks during encode.\n";
	die "\n$why\n\n$use\n";
}

sub getName {
	my $path = shift;
	if ($path !~ /\//) { return $path; }
	my @paths = split(/\//, $path);
	return @paths[@paths-1];
}

sub ismedia {
	my $what = shift;
	if (-d $what) { return 0; }
	foreach my $mtype (@media_types) { if (lc($what) =~ /\.$mtype$/i) { return 1; } }
	return 0;
}
sub extract {
	my $infile = shift;
	my $otfile = getName($infile);
	$otfile =~ s/\.\w+$/\.wav/;
	if ($infile eq $otfile) { $otfile = $otfile . '.wav'; }
	$otfile = File::Spec->catpath('', $tempdir, $otfile);
	system("ffmpeg -i \"$infile\" -vn -acodec pcm_u8 -ar 44100 -y \"$otfile\"");
	if (!-r $otfile) { die "Error: Decoding of $infile failed!\n"; }
	return $otfile;
}

sub normalize {
	if (!$normal) { return; }
	my $infile = shift;
	system("normalize \"$infile\"");	
}

sub encode {
	my $infile = shift;
	my $where = shift;
	my $otfile = File::Spec->catpath('', $where, getName($infile));
	if ($toogg) {
		$otfile =~ s/\.wav$/\.ogg/i;
		system("oggenc -o \"$otfile\" \"$infile\"");
	}
	else {
		$otfile =~ s/\.wav$/\.mp3/; 
		system("lame -h \"$infile\" \"$otfile\""); 
	}
	if (!-r $otfile) { die "Error: Encoding of $infile failed!\n"; }
	unlink($infile);
}

if ((!@ARGV) || (@ARGV < 2)) { dieUsage("Incorrect arguments!"); }
my @queue;
my $ofolder = shift(@ARGV);
if ((!-d $ofolder) || (!-w $ofolder)) { dieUsage("$ofolder is not a writable output directory!"); }
system("mkdir -p $tempdir");
foreach my $input (@ARGV) {
	print "Locating inputs...\n";
	if (-d $input) { 
		print "Reading directory: $input...\n";
		opendir(RDIR, $input) || dieUsage("Cannot open $input for reading!");
		my @tmp = readdir(RDIR);
		close(RDIR);
		foreach my $thing (@tmp) {
			my $fp =  File::Spec->catpath('', $input, $thing);
			if (ismedia($thing)) { 
				print "Found media: $fp.\n";
				push(@queue, $fp); 
			}
			elsif ((-d $thing) && ($recurse)) { 
				print "Found subdirectory: $fp.\n";
				push(@ARGV, $fp); 
			}
		}
	}
	elsif (ismedia($input)) { 
		print "Found media: $input.\n";
		push(@queue, $input); 
	}
}
if (!@queue) { dieUsage("No media files found!"); }
foreach my $media (@queue) {
	my $wav = extract($media);
	normalize($wav);
	encode($wav, $ofolder);
}
exit(0);
