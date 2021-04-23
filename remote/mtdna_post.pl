#!/usr/bin/env perl
#
#   SG-Adviser mtDNA web server standalone script
#
#   https://genomics.scripps.edu/mtdna
#
#   Author: Manuel Rueda Ph.D.
#   Scripps Stranslational Science Institute
#   La Jolla, CA  92093-0747
#   mrueda@scripps.edu
#
#   Version 1.0.0
#   Copyright (C) 2016 Manuel Rueda (mrueda@scripps.edu)
#
#   Notes:
#
#   This is an example "generic" script. The user must replace
#   the input parameters (see below).
#
#   For multiple executions we recommend these two options:
#
#   i/  Use a loop from an external Linux shell script
#       (e.g., 'for' in BASH).
#       The values of the POST paramaters must
#       be replaced. You can use 'sed' from outside,
#       or you may enter them as a Perl arguments (e.g., $ARGV[0], etc)
#
#   ii/ Use a for loop inside this script with the files you want to send
#
#
#   PS: Please, do not abuse the web server
#       Run your calculations sequentially if possible. Thanks!
#       Do not hesitate to contact the author in case you get any error
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, see <https://www.gnu.org/licenses/>.
#
#   If this program helps you in your research, please cite.

use strict;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use File::Basename qw(basename);

# Usage 
# Example: Argument LP6005833_DNA_D01.bam
if ($#ARGV) { print "Usage: $0 file.bam\n"; exit }

# Defining variables here
my $bam     = $ARGV[0];
my $bam_id  = basename($bam);
   $bam_id  =~ s/\.[bs]am//;
my $email   = '';
my $private = 'no';

# Setting remote connection
my $ua = new LWP::UserAgent;
$ua->ssl_opts( 'verify_hostname' => 0 ) ;    # to avoid SSL certificate error from genomics.scripps.edu
my $url   = 'https://genomics.scripps.edu';
my $mtdna = $url . '/mtdna/';

# START HERE FOR LOOP <- OPTIONAL USER MODIFICATION

# Send the form to the server Home page
# NB: It only works for individual sample mode (not cohort mode)
my $req = POST $mtdna,
  Content_Type => 'form-data',
  Content      => [
    bam     => ["$bam"],    #<- USER MODIFICATION
    email   => $email,      #<- USER MODIFICATION
    private => $private,    #<- USER MODIFICATION
    job_id  => $bam_id      #<- USER MODIFICATION
  ];

die "Couldn't get $mtdna" unless defined $req;

##############################################################
# DO NOT TOUCH CODE BELOW UNLESS YOU KNOW WHAT YOU ARE DOING #
##############################################################

# Retrieve the content as a string
my $mtdna_page_one = $ua->request($req)->as_string;

# Parse results to catch the final page
my ( $job_id, $mtdna_page_two ) = ('') x 2;
while ( $mtdna_page_one =~ m/Job ID: (\w+) <br \/>/gi ) {
    $job_id = $1;    # The Id of the job
}
die "Couldn't get the Job URL (make sure you don't have duplicate Job ID names)"
  unless $job_id;
print "ID : $job_id\n";

$mtdna_page_two = $mtdna . 'results/job/' . $job_id;
print "URL: $mtdna_page_two\n";

##################################################################
# DO NOT TOUCH the UPPER CODE UNLESS YOU KNOW WHAT YOU ARE DOING #
##################################################################

# END HERE FOR LOOP  <- OPTIONAL USER MODIFICATION
