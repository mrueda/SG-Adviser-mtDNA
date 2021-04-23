#!/usr/bin/env perl
#
#   Script for sending emails at SG-ADVISER mtDNA jobs
#
#   Last Modified; Dec/22/2016
#
#   Version: 1.0.0
#
#   Copyright (C) 2016 Manuel Rueda (mrueda@scripps.edu)
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
use warnings;
use Mail::Sendmail;    # It does not use sendmail

if ( @ARGV != 3 ) {
    print "Usage: $0 mit.json job_id recipient_email\n";
    exit 1;
}

my $file      = shift;
my $job_id    = shift;
my $recipient = shift;
my $sender    = 'genomics@scripps.edu';
my $smtp      = 'smtp.scripps.edu';
my $http      = 'https://genomics.scripps.edu/mtdna';
my $job_url   = $http . '/results/job/' . $job_id;
my $help_url  = $http . '/help.html';

# Test for completion
my $subject = '';
my $message = '';

if ( -s $file ) {
    $subject = "SG-ADVISER mtDNA job $job_id has finished";
    $message = <<  "EOF";
Hi there,

Your job $job_id is now accessible at:

$job_url

Enjoy!

_SGA-mtDNA_

EOF
}
else {

    $subject = "SG-ADVISER mtDNA job $job_id has failed";
    $message = << "EOF";
Hi there,

Your job $job_id could not be completed.

Make sure that you follow the recommended procedures.

$help_url

_SGA-mtDNA_

EOF
}

my %mail = (
    To      => $recipient,
    From    => $sender,
    Subject => $subject,
    Message => $message,
    smtp    => $smtp
);

sendmail(%mail) or die $Mail::Sendmail::error;
print "OK. Log says:\n" . $Mail::Sendmail::log . "\n";
