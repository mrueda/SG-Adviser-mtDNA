#!/usr/bin/env perl
#
#   Web server for SG-ADVISER mtDNA web server
#   Data upload based on CGI.pm
#   Web-services via Mojolicius
#
#   Last Modified; Dec/13/2016
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
use CGI qw(:standard :html5); # Only using one object, using thus function oriented CGI, not OO
use CGI::Carp qw/fatalsToBrowser/;
use Fcntl qw(:flock SEEK_END);    # import LOCK_* and SEEK_END constants
use Sort::Naturally;              # Simplest way to do mixed string sorting
use File::Basename;

# Variables for CGI
$| = 1;                           # Tell Perl to NOT buffer our output

#$CGI::POST_MAX = 1024 * 10000000 ;     # 1024 = 1K, so ~100MB
my $max_file_size = 1024 * 500000;    # 500MB

# Defining a few variables below
my $version     = '1.0.0';
my $ip_server   = 'localhost:82';
my $server_dir  = '.';
my $server_perl = "$server_dir/mtDNA-server.pl";
my $job_id      = time . substr( "00000$$", -5 );     # temporary Id for the job
my $job_dir     = $server_dir . '/data/' . $job_id;
my $reload_sec  = '3';
my $reload_ms   = $reload_sec * 1000;
my $status_page = 'results/status';
my $log         = "log/log.txt";

# Miscellanea CSS
my $css_main = 'css/main.css';    # Using Bootstrap as the primary one
my $css_bootstrap = 'css/bootstrap.min.css'; # Using also responsive.css (see <head>)
my $css_responsive = 'css/bootstrap-responsive.min.css';
my $str_error      = "<i class=\"icon-warning-sign\"></i>";
my $str_help       = "<i class=\"icon-question-sign\"></i>";
my $str_ok         = "<i class=\"icon-ok-sign\"></i>";
my $str_upload     = "<i class=\"icon-upload\"></i>";
my $str_tasks      = "<i class=\"icon-tasks\"></i>";
my $center_div     = 'span6 offset3 pagination-centered';
my $position_abs   = 'style="position:absolute"';

# Hash of pages and functions
my %state = (
    'Default'    => \&front_page,
    'Submission' => \&submission
);

# Start the HTML
print start_str_html();

# Proceed depending on user selection
if ( param('bam') || param('bamdir') ) {
    $state{Submission}->();
}

# else print Home Page
else {
    $state{Default}->();
    print end_str_html();
}

exit;

=head2 upload_div

    About   : 
    Usage   :             
    Args    : 

=cut

sub upload_div {

    # The reason for this div is that we were unable to print "Uploading file"
    # When submit button is hit POST data is uploaded by CGI.pm
    # we could not capture any progress until ALL files were uploadedi :-/
    my $message = shift;
    my $alert   = 'alert alert-info alert-block break-word';
    my $str =
"<div id=\"upload-file-div\" class=\"$alert $center_div\" $position_abs >$message</div>\n";
    return $str;
}

=head2 status_div

    About   : 
    Usage   :             
    Args    : 

=cut

sub status_div {

    my $message = shift;
    my $alert   = 'alert alert-success alert-block break-word';
    my $str =
      "<div class=\"$alert $center_div\" $position_abs>$message</div>\n";
    return $str;
}

=head2 error_div

    About   : 
    Usage   :             
    Args    : 

=cut

sub error_div {

    my $message  = shift;
    my $solution = shift;
    my $job_id   = shift;
    my $alert    = 'alert alert-error alert-block break-word';
    my $img      = shift;
    my $rmdir    = shift;
    my $text =
"<br /><br />$solution <a href=\"http://$ip_server/help.html\" target=\"_blank\">$str_help</a><br />If you are in trouble send an email to: mrueda\@scripps.edu <br /><br /><a href=\"javascript:\" onclick=\"history.go(-1); return false;\"><span class=\"btn btn-primary\">&laquo; Back</span></a>";
    print
"<div class=\"$alert $center_div\" $position_abs> $message $img <br /> $text </div>\n";
    rmdir $job_dir if $rmdir;
    exit;
}

=head2 google_analytics

    About   : 
    Usage   :             
    Args    : 

=cut

sub google_analytics {

    my $str = " 
<!-- STATS -->
<script>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-71888980-2', 'auto');
  ga('send', 'pageview');

</script>
<!-- STATS -->\n";
    return $str;
}

=head2 html_web_form

    About   : 
    Usage   :             
    Args    : 

=cut

sub html_web_form {

    my $str = '';
    $str .=
'<div id="web-form" class="hero-unit span4 offset2" style="display:none;">';
    $str .=
        start_multipart_form( -action => '.', -name => 'mtDNA_parameters' )
      . '<b>INDIVIDUAL SAMPLE</b>'
      . br
      . '<i class="icon-upload"></i> Please drop your mtDNA bam file</label>'
      . '<input name="bam" class="" id="bam" type="file"/>'
      . br
      . "<a href=\"http://$ip_server/results/job/mtDNA_Test_Job\"> <span class=\"icon-eye-open\"></span> Test job</a>"
      . hr
      . '<b>COHORT</b>'
      . br
      . '<i class="icon-upload"></i> Please drop the folder with your mtDNA bam files</label>'
      . '<input name="bamdir" type="file" id="bamdir" webkitdirectory directory multiple/>'
      . hr
      . '<b>Your email</b>'
      . '<label class="text" > '
      . textfield(
        -name => 'email',
        -size => 40
      )
      . '</label>'
      . hr
      .

      # Collapsible
      '
	<div class="accordion" id="accordion2">
	  <div class="accordion-group">
	    <div class="accordion-heading">
	      <a class="accordion-toggle label" data-toggle="collapse" data-parent="#accordion2" href="#collapseOne">
		<span class="label"><i class="icon-pencil icon-white"></i>&nbsp;&nbsp;&nbsp; Change parameters (optional)</span>
	      </a>
	    </div>
	    <div id="collapseOne" class="accordion-body collapse">
	      <div class="accordion-inner">
	';
    $str .=
        '<b>Private</b>'
      . '<label class="radio"> '
      . radio_group(
        -name    => 'private',
        -values  => [ 'yes', 'no' ],
        -default => 'no'
      ) . '</label>';
    $str .=
        '<b>Job ID</b>'
      . '<label class="text" > '
      . textfield(
        -name => 'job_id',
        -size => 40
      )
      . '</label>'
      . '</div> </div> </div> </div>'
      . hr
      . reset(
        -name  => 'Reset form',
        -class => 'btn pull-left'
      )
      . submit(
        -name  => 'submit-btn',
        -id    => 'submit-btn',
        -value => 'Submit',
        -class => 'btn btn-primary pull-right'
      ) . end_form;
    $str .= '</div>';
    return $str;
}

=head2 redirect_page

    About   : 
    Usage   :             
    Args    : 

=cut

sub redirect_page {

    my $url = shift;
    my $ms  = shift;
    my $str = "
	<script type=\"text/javascript\">
	<!--
	setTimeout(\"location.href = '$url';\",$ms);
	//-->
	</script>\n";
    return $str;
}

sub lock {

    my ($fh) = @_;
    flock( $fh, LOCK_EX );

    # and, in case someone appended while we were waiting...
    seek( $fh, 0, SEEK_END );
}

sub unlock {

    my ($fh) = @_;
    flock( $fh, LOCK_UN );
}

=head2 upload_bam_file

    About   : 
    Usage   :             
    Args    : 

=cut

sub upload_bam_file {

    my $bam = shift;

    # Cleaning naming
    my $out_bam = basename($bam);

    error_div(
        "Error: Please revise the name of the file: $out_bam",
        'Nomenclature must follow this format: HG00119.[bs]am ( _ ok)',
        $job_id,
        $str_error,
        1
    ) if $out_bam !~ /^\w+\.[bs]am$/;

    # More cleaning
    $out_bam =~ s/\s+//g;                  # Deleting white spaces
    $out_bam =~ s#\.bam$#\-DNA_MIT\.bam#
      unless $out_bam =~ m/\-..._...\.bam$/;  # Renaming accordingly to MToolBox
    $out_bam =~ s#\.sam$#\-DNA_MIT\.sam#
      unless $out_bam =~ m/\-..._...\.sam$/;  # Renaming accordingly to MToolBox
    $out_bam = "$job_dir/$out_bam";           # Full path

    # Upload and check file size
    my ( $read_bytes, $buffer );
    my @tmp_fields = ();
    my $n_bytes    = 1024;
    my $t_bytes    = undef;

    my $fh_bam_in = $bam;
    open( my $fh_bam_out, '>', $out_bam );
    while ( $read_bytes = read( $fh_bam_in, $buffer, $n_bytes ) ) {
        $t_bytes += $read_bytes;
        print $fh_bam_out $buffer;
    }
    close $fh_bam_out;
    die "Read failure" unless defined($read_bytes);
    unless ( defined($t_bytes) ) {
        error_div(
            "Error: Could not read $out_bam. The file is empty",
            'Please check your bam files',
            $job_id, $str_error, 0
        );
    }
}

=head2 template_html

    About   : 
    Usage   :             
    Args    : 

=cut

sub template_html {

    # Extracted from bootstrap
    my $full = shift;
    my $str  = '';
    $str = << "EOF";
  <body>
    <!--[if lt IE 9]>
      <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->

        <!--[if lt IE 7]>
            <p class="chromeframe">You are using an outdated browser. <a href="http://browsehappy.com/">Upgrade your browser today</a> or <a href="http://www.google.com/chromeframe/?redirect=true">install Google Chrome Frame</a> to better experience this site.</p>
        <![endif]-->

        <!-- This code is taken from http://twitter.github.com/bootstrap/examples/hero.html -->
        <div class="navbar navbar-inverse navbar-fixed-top">
            <div class="navbar-inner">
                <div class="container">
                    <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                    </a>
                    <a class="brand" href="http://$ip_server">SG-ADVISER mtDNA</a>
                    <div class="nav-collapse collapse">
                        <ul class="nav">
                            <li class="active"><a href="http://$ip_server"><i class="icon-home icon-white"></i>Home</a></li>
                            <li class="dropdown">
                                <a href="#" class="dropdown-toggle" data-toggle="dropdown">Run <b class="caret"></b></a>
                                <ul class="dropdown-menu">
                                    <li class="nav-header">Server</li>
                                    <li id="start-using-nav"><a href="#"><span class="icon-forward"></span> Start using it</a></li>
                                    <li class="divider"></li>
                                    <li class="nav-header">Test-Job</li>
                                    <li><a href="http://$ip_server/results/job/mtDNA_Test_Job"><span class="icon-eye-open"></span> Explore it</a></li>
                                </ul>
                            </li>
                            <li><a href="results/status">Status</a></li>
                            <li><a href="results/wellderly">Wellderly</a></li>
                            <li class="dropdown">
                                <a href="#" class="dropdown-toggle" data-toggle="dropdown">Help <b class="caret"></b></a>
                                <ul class="dropdown-menu">
                                    <li class="nav-header">Help</li>
                                    <li><a href="help.html"><span class="icon-question-sign"></span> Help Page</a>
                                    <li class="divider"></li>
                                    <li class="nav-header">FAQs</li>
                                    <li><a href="faq.html"><span class="icon-question-sign"></span> FAQs Page</a></a></li>
                                </ul>
                            </li>
                            <li class="dropdown">
                                <a href="#" class="dropdown-toggle" data-toggle="dropdown">Links <b class="caret"></b></a>
                                <ul class="dropdown-menu">
                                    <li class="nav-header">Contact</li>
                                    <li><a href="mailto:mrueda\@scripps.edu"><span class="icon-envelope"></span> Author</a>
                                    <li class="divider"></li>
                                    <li class="nav-header">Corporate Info</li>
                                    <li><a href="http://www.scripps.edu"><span class="icon-home"></span> Scripps Research</a></a></li>
                                </ul>
                            </li>
                        </ul>
                    </div><!--/.nav-collapse -->
                </div>
            </div>
        </div>

EOF

    $str .= << "EOF" if $full;

           <div id="mtdna-home" class="container">

            <!-- Main hero unit for a primary marketing message or call to action -->
            <div id="mtdna-hero-unit" class="hero-unit">
                <h1>SG-ADVISER mtDNA</h1>
                <p> Automated analysis of mtDNA variations from NGS data</p>
                <p><a id="start-using-btn" class="btn btn-primary btn-large"><i class=\"icon-forward icon-white\"></i> Start using it</a></p>

                <!--  Carousel -->
                <!--  consult Bootstrap docs at 
                      http://twitter.github.com/bootstrap/javascript.html#carousel -->
                <div id="this-carousel-id" class="carousel slide">
                  <div class="carousel-inner">
                    <div class="item active">
                      <a href="https://commons.wikimedia.org/wiki/File:Map_of_the_human_mitochondrial_genome.svg">  <img src="img/mtdna.png" alt="Mitochondrial DNA Picture: by Emmanuel Douzery [CC BY-SA 4.0]via Wikimedia Commons" />
                      </a>
                      <div class="carousel-caption">
                        <p><a href="help.html">Analysis, annotation and priorization of variants &raquo;</a></p>
                      </div>
                    </div>
                    <div class="item">
                      <a href="https://commons.wikimedia.org/wiki/File:Mitochondrial_dna_lg.jpg">
                        <img src="img/mtdna2.png" alt="SG-ADVISER mtDNA" />
                      </a>
                      <div class="carousel-caption">
                        <p><a href="help.html">Mitochondrial DNA analysis &raquo;</a></p>
                      </div>
                    </div>
                    <div class="item">
                      <a href="https://commons.wikimedia.org/wiki/File:Human_migrations_and_mitochondrial_haplogroups.PNG">
                        <img src="img/haplogroup.png" alt="SG-ADVISER mtDNA" />
                      </a>
                      <div class="carousel-caption">
                        <p><a href="help.html">Human mitochondrial DNA haplogroups &raquo;</a></p>
                      </div>
                    </div>

                  
                  </div><!-- .carousel-inner -->
                  <!--  next and previous controls here
                        href values must reference the id for this carousel -->
                    <a class="carousel-control left" href="#this-carousel-id" data-slide="prev">&lsaquo;</a>
                    <a class="carousel-control right" href="#this-carousel-id" data-slide="next">&rsaquo;</a>
                </div><!-- .carousel -->
                <!-- end carousel -->

            </div>

            <!-- row of columns -->
            <div id="mtdna-text" class="row">
                <div class="span4">
                    <h2>SG-ADVISER</h2>
                    <p>Scripps Genome ADVISER suite include a web server interface to a high-performance computing environment for calculations of annotations and an HTML user interface that allows for data display.</p> 
                    <p><a class="btn" href="help.html">View details &raquo;</a></p>
                </div>
                <div class="span4">
                    <h2>mtDNA</h2>
                    <p>Mitochondrial DNA (mtDNA or mDNA) is the DNA located in mitochondria, cellular organelles within eukaryotic cells that convert chemical energy from food into a form that cells can use, adenosine triphosphate (ATP).</p>
                    <p><a class="btn" href="help.html">View details &raquo;</a></p>
                </div>
                <div class="span4">
                    <h2>Annotation</h2>
                    <p> The annotation of chrM bam files is performed through MToolBox that implements an effective computational strategy for mitochondrial genomes assembling and haplogroup assignment also including a prioritization analysis of detected variants. </p>
                    <p><a class="btn" href="help.html">View details &raquo;</a></p>
               </div>
            </div>
EOF
    return $str;
}

=head2 end_str_html

    About   : 
    Usage   :             
    Args    : 

=cut

sub end_str_html {

    my $str = << "EOF";
            <hr>
            <footer>
                <p>&copy; 2017 Scripps Research | U.S.A.</p>
            </footer>
            </div><!-- /container -->

        <script src="js/jquery.min.js"></script>
        <script src="js/bootstrap.min.js"></script>
        <script src="js/main.js"></script>
        <script src="js/jqBootstrapValidation.js"></script>
        <script type="text/javascript" language="javascript">
         if (window.location.hash === '#start-using-it') {
          start_using();
         } 
        </script>

EOF

    $str .= google_analytics();
    $str .= end_html;
    return $str;
}

=head2 start_str_html

    About   : 
    Usage   :             
    Args    : 

=cut

sub start_str_html {

    # CGI.pm creates DOCTYPE only for XHTML
    # We use a trick to get HTML5
    my $str  = '';
    my $html = '<html lang="en">';
    my $dtd  = '<!DOCTYPE html>';    # HTML5 DTD
    $str .= header( -expires => 'now' ) . start_html(
        -title  => 'SG-ADVISER mtDNA Home Page',
        -author => 'mrueda@scripps.edu',
        -meta   => {
            viewport    => 'width=device-width, initial-scale=1.0',
            author      => 'Manuel Rueda',
            keywords    => 'NGS pipeline mtDNA annotation',
            description => 'SG-ADVISER mtDNA: mitochondrial DNA annotation'
        },
        -style => { -src => [ $css_bootstrap, $css_responsive, $css_main ] }, #order matters
    );
    $str =~ s{<html xmlns.*?>}{$html}s;
    $str =~ s{<!DOCTYPE.*?>}{$dtd}s;
    $str =~
s{</head>\n}{<link rel="icon" href="img/favicon.ico" type="image/x-icon" />\n</head>\n};
    return $str;    # Voila!
}

=head2 submission

    About   : 
    Usage   :             
    Args    : 

=cut

sub submission {

    my ( $bam, $arguments ) = (undef) x 2;

    # Display upload div (we can't get indivual files with CGI.pm)
    print upload_div(
"$str_upload Uploading bam files to SG-ADVISER mtDNA<br /> <br /><br />Please note that this can take a while ...<br /><br /><br />"
    );

    # Check for file size
    error_div(
        "Error: Your file $bam is too big!",
        'Are you sure that it only contains mtDNA reads?',
        $job_id, $str_error, 0
    ) if $ENV{CONTENT_LENGTH} > $max_file_size;

    ###########################
    #  Arguments (optional)   #
    ###########################

    # Private job
    # NB: Note that we can turn-[on|off] "radio" parameters with js/main.js
    my $private = param('private') ? param('private') : 'no';

    # Report error if the job is private and no param('email')'
    error_div(
'Error: When setting a job to private you need to provide an email address',
        'Your email is the only way we can reach you once the job has finished',
        $job_id,
        $str_error,
        0
    ) if ( $private eq 'yes' && !param('email') );

    # Assign e-mail (mrueda@scripps.edu is the default)
    my $email = param('email') ? param('email') : 'mrueda@scripps.edu';

    # User Job ID
    if ( param('job_id') ) {
        my $user_job_id = param('job_id');
        $user_job_id =~ s/\s+/_/g;
        $job_id  = $user_job_id;
        $job_dir = $server_dir . '/data/' . $job_id;

        # if directory exist die
        error_div(
            "Error: Looks like '$job_id' has been used before as JOB ID",
            'Please use another name for Job ID parameter',
            $job_id,
            $str_error,
            0
        ) if ( -d $job_dir );
    }

    # Print template
    print template_html(0);

    # Generate JobDir
    mkdir $job_dir, 0775;

    my @bams = ();

    # CASE A: 1 BAM file
    if ( !param('bamdir') ) {

        # Uploading Fastq files
        $bam = param('bam');
        upload_bam_file($bam);
        push @bams, $bam;
    }

    # CASE B: Multiple BAMs
    else {
        @bams = param('bamdir');

        # We only keep BAMs (avoid xmls, etc.)
        @bams = nsort( grep { $_ =~ /\.(cr|[bs])am$/ } @bams );

        # Exit if we only have 1 file
        error_div(
            'Looks like you are not uploading the right bam files',
            'Please, revise your selection',
            $job_id, $str_error, 0
        ) unless scalar @bams > 1;

        # Upload one by one
        foreach my $bam_sample (@bams) {
            upload_bam_file($bam_sample);
        }
    }

    # Loading $arguments
    $arguments = "$job_id $private $email @bams"; # @bams sorted ny nsort (including dir/file)

    # Now that we have the complete list of arguments we check that
    # they do not contain "malicious" characters
    error_div(
        'Your selection(s) must not include these characters: &;? ...',
        'Please, check the nomenclature',
        $job_id, $str_error, 1
    ) if $arguments =~ /[&;`'"\*\|\?\~\<\>\^\(\)\[\]\{\}]/;

    # Adding the info to the logfile (blocking overwritting)
    open( my $LOG, '>>', $log );
    lock($LOG);
    print $LOG localtime() . " :: $ENV{'REMOTE_ADDR'} :: $arguments\n";
    unlock($LOG);
    close $LOG;

    # Now execute the accessory script that actually does the job
    system("$server_perl $arguments &");

    # And we finally redirect the user to the status page
    sleep($reload_sec);    # Otherwise it will go to status_div directly
    print status_div(
"Job ID: $job_id <br /> <br /><br />Nice! We are resubmitting you to the Status page $str_ok<br /><br /><br />"
    );
    print redirect_page( $status_page, $reload_ms );
}

=head2 front_page

    About   : 
    Usage   :             
    Args    : 

=cut

sub front_page {

    print html_web_form();
    print template_html(1);
}

