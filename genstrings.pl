#! /usr/bin/perl
use strict;
use warnings;
use File::Find;

my @files;
my $start_dir = $ARGV[0];  # top level dir to search
find( 
    sub { 
    	(/.*\.swift/ || /.*\.m/) && push @files, $File::Find::name  
    }, 
    $start_dir
);
for my $input_file (@files) {
#	print "$input_file\n";
	my $input_fh;
	open($input_fh, "<", $input_file ) || die "Can't open $input_file: $!";
	my $text = join('', <$input_fh>);
	close($input_fh);
	
	while ( $text =~ /\WError\(\s*"(.*?)"/g) {
		print "/* Error */\n";
		print "\"$1\" = \"$1\";\n";
	}	
	
	while ( $text =~ /\WNSLocalizedString\(\s*"(.*?)".*?comment:\s*"(.*?)"/g) {
		print "/* $2 */\n";
		print "\"$1\" = \"$1\";\n";
	}

	while ( $text =~ /\WFragariaColor\((.*?),.*?"(.*?)"/g) {
		print "/* Fragaria color $1 */\n";
		print "\"$2\" = \"$2\";\n";
	}
}