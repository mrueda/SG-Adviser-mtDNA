#!/usr/bin/env perl
#
#   External script for SG-ADVISER mtDNA web server
#
#   Last Modified; May/18/2017
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
use autodie;
use File::Basename;
use Cwd qw(cwd);

if ( $#ARGV < 2 ) {
    print "Usage: $0 idjob private email bam1...N\n";
    exit;
}

# VARIABLES I/O
my $version = '1.0.0';
my ( $job_id, $private, $email, @bams ) = @ARGV;
$| = 1;    # Tell Perl to NOT buffer our output
my $debug           = 0;
my $maintenance     = 0;
my $data_dir        = './data';
my $work_dir        = $data_dir . '/' . $job_id;
my $pro_dir         = '/pro';
my $scrippscall_dir = "$pro_dir/scrippscall";
my $varcall_dir     = "$scrippscall_dir/variant_calling";
my $sqs_dir         = "$pro_dir/sqs-3.1/bin";
my $mit_single =
  ( -x "$varcall_dir/mit_single.sh" )
  ? "$varcall_dir/mit_single.sh"
  : die "Can't execute $scrippscall_dir/mit_single.sh";
my $mit_cohort =
  ( -x "$varcall_dir/mit_cohort.sh" )
  ? "$varcall_dir/mit_cohort.sh"
  : die "Can't execute $varcall_dir/mit_cohort.sh";
my $n_bam    = scalar @bams;
my $mtoolbox = $n_bam > 1 ? $mit_cohort : $mit_single;
my $qstat =
  ( -x "$sqs_dir/qstat" )
  ? "$sqs_dir/qstat"
  : die "Can't execute $sqs_dir/qstat";
my $qsub =
  ( -x "$sqs_dir/qsub" )
  ? "$sqs_dir/qsub"
  : die "Can't execute $sqs_dir/sqs-3.1/bin/qsub";
my $ncpu = 4;    # After 4 the gain is minimal
my $sgadviser_mtdna_exe =
  ( -x "$mit_single" )
  ? "$mit_single"
  : die "Can't execute $mit_single";

# Change to working directory
chdir($work_dir);

# Generate $info file
my $info = 'info.txt';
open( my $fh_info, '>', $info );
my $time = localtime(time);

# We keep only basename (whole path is in log/log.txt)
@bams = map { basename($_) } @bams;

print $fh_info '#SG-ADVISER VERSION:' . $version . "\n";
print $fh_info '#'
  . join( "\t", 'TIME', 'JOB_ID', 'PRIVATE', 'NSAMPLE', 'BAM' ) . "\n";
print $fh_info
  join( "\t", $time, $job_id, $private, $n_bam, join( ',', @bams ) ) . "\n";
close $fh_info;
my $format = $bams[0] =~ /\.sam$/ ? 'sam' : 'bam';

# The actual fun starts here
# Note that is extremely important that:
# 1 - data/.sqs/ folder has permission for writting by www-data
# 2 - The /pro/sqs-3.1/bin/qsub exe must be accssible by www-data
# 3 - qseek daemon must be runing for www-data (can be started with (qinit start). For troubles do qinit stop + qinit start.
# sh: 0: getcwd() failed: No such file or directory

my ( $bam, $sgadviser_mtdna_log, $sgadviser_mtdna_err, $sgadviser_mtdna_sqs ) =
  ('') x 4;

$sgadviser_mtdna_log = 'sgadviser_mtdna.log';
$sgadviser_mtdna_err = 'sgadviser_mtdna.err';
$sgadviser_mtdna_sqs = 'sgadviser_mtdna.sqs';

# Queue job
my $job_sh = 'job_x_' . $job_id . '.sh';    # Must be unique
open( my $fh_qsub, '>', $job_sh );
print $fh_qsub "#!/bin/sh\n";
print $fh_qsub "cd " . cwd() . "\n";
print $fh_qsub
"$mtoolbox -n $ncpu -f $format > $sgadviser_mtdna_log 2> $sgadviser_mtdna_err \n";
print $fh_qsub
"$scrippscall_dir/web/mtb2json.pl -i mit_prioritized_variants.txt -f json4html > mit.json\n";
print $fh_qsub
  "/var/www/mtdna/sendmail.pl mit_prioritized_variants.txt $job_id $email\n"; # mit.json will contain a few bytes always
print $fh_qsub "rm *.[bs]a? *.fastq processed_fastq.tar.gz\n";
print $fh_qsub "rm OUT*/*.{sam,bam,fastq,pileup} OUT*/MarkTmp.tar.gz\n";
close $fh_qsub;

my $sgadviser_mtdna_cmd =
    "chmod +x $job_sh; $qsub -nproc $ncpu -q mtdna "
  . cwd()
  . "/$job_sh > "
  . cwd()
  . "/$sgadviser_mtdna_sqs";
system("$sgadviser_mtdna_cmd");

1;
